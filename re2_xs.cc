#define PERL_NO_GET_CONTEXT

// This needs to be first, Perl is rude and defines macros like "Copy"
#include <re2/re2.h>
#include <map>
#include "re2_xs.h"

using std::map;
using std::string;

namespace {
    REGEXP * RE2_comp(pTHX_ SV * const, U32);
    char *   RE2_intuit(pTHX_ REGEXP * const, SV *, const char *,
                        char *, char *, U32, re_scream_pos_data *);
    I32      RE2_exec(pTHX_ REGEXP * const, char *, char *,
                      char *, SSize_t, SV *, void *, U32);
    SV *     RE2_checkstr(pTHX_ REGEXP * const);
    void     RE2_free(pTHX_ REGEXP * const);
    SV *     RE2_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
    void *   RE2_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif

    static SV * stringify(pTHX_ const U32 flags, const char *const exp,
          const STRLEN plen)
    {
        SV * wrapped = newSVpvn("(?", 2), * wrapped_unset = newSVpvn("", 0);
        sv_2mortal(wrapped);
        sv_2mortal(wrapped_unset);

        sv_catpvn(flags & RXf_PMf_FOLD ? wrapped : wrapped_unset, "i", 1);
        sv_catpvn(flags & RXf_PMf_MULTILINE ? wrapped : wrapped_unset, "m", 1);
        sv_catpvn(flags & RXf_PMf_SINGLELINE ? wrapped : wrapped_unset, "s", 1);

        if (SvCUR(wrapped_unset)) {
            sv_catpvn(wrapped, "-", 1);
            sv_catsv(wrapped, wrapped_unset);
        }

        sv_catpvn(wrapped, ":", 1);
        sv_catpvn(wrapped, exp, plen);
        sv_catpvn(wrapped, ")", 1);

        return wrapped;
    }
};

const regexp_engine re2_engine = {
    RE2_comp,
    RE2_exec,
    RE2_intuit,
    RE2_checkstr,
    RE2_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    RE2_package,
#if defined(USE_ITHREADS)
    RE2_dupe,
#endif
    NULL,
};

namespace {

REGEXP *
RE2_comp(pTHX_ SV * const pattern, const U32 flags)
{
    const char *exp;
    STRLEN plen;
    RE2::Options options;

    U32 extflags = flags;
    bool perl_only = false;

    exp = SvPV(pattern, plen);

    /* C<split " ">, bypass the engine alltogether and act as perl does */
    if (flags & RXf_SPLIT && plen == 1 && exp[0] == ' ')
        extflags |= (RXf_SKIPWHITE|RXf_WHITE);

    /* RXf_NULL - Have C<split //> split by characters */
    if (plen == 0)
        extflags |= RXf_NULL;

    /* RXf_START_ONLY - Have C<split /^/> split on newlines */
    else if (plen == 1 && exp[0] == '^')
        extflags |= RXf_START_ONLY;

    /* RXf_WHITE - Have C<split /\s+/> split on whitespace */
    else if (plen == 3 && strnEQ("\\s+", exp, 3))
        extflags |= RXf_WHITE;

    if (flags & RXf_PMf_EXTENDED)
        perl_only = true;  /* /x */

    options.set_case_sensitive(!(flags & RXf_PMf_FOLD)); /* /i */

    // XXX: Need to compile two versions?
    /* The pattern is not UTF-8. Tell RE2 to treat it as Latin1. */
#ifdef RXf_UTF8
    if (!(flags & RXf_UTF8))
#else
    if (!SvUTF8(pattern))
#endif
        options.set_encoding(RE2::Options::EncodingLatin1);

    options.set_log_errors(false);

    SV *const max_mem = cophh_fetch_pvs(PL_curcop->cop_hints_hash,
            "re::engine::RE2::max-mem", 0);
    if (SvOK(max_mem) && SvIV_nomg(max_mem)) {
        options.set_max_mem(SvIV(max_mem));
    }

    SV *const longest_match = cophh_fetch_pvs(PL_curcop->cop_hints_hash,
            "re::engine::RE2::longest-match", 0);
    if (SvOK(longest_match) && SvTRUE(longest_match)) {
        options.set_longest_match(true);
    }

    SV *const never_nl = cophh_fetch_pvs(PL_curcop->cop_hints_hash,
            "re::engine::RE2::never-nl", 0);
    if (SvOK(never_nl) && SvTRUE(never_nl)) {
        options.set_never_nl(true);
    }

    // Try and compile first, if this fails we will fallback to Perl regex via
    // Perl_re_compile.
    const SV *const wrapped = stringify(aTHX_ flags, exp, plen);
    RE2 * ri = NULL;

    if (!perl_only) {
        ri = new RE2 (re2::StringPiece(SvPVX(wrapped), SvCUR(wrapped)), options);
    }

    if (perl_only || ri->error_code()) {
        // Failed. Are we in strict RE2 only mode?
        SV *const re2_strict = cophh_fetch_pvs(PL_curcop->cop_hints_hash,
                "re::engine::RE2::strict", 0);

        if (SvOK(re2_strict) && SvTRUE(re2_strict)) {
            const string error = ri->error();
            delete ri;

            croak("%s", perl_only
                    ? "/x is not supported by RE2"
                    : error.c_str());
            return NULL; // unreachable
        }

        delete ri;

        // Fallback. Perl will either compile or print errors for us.
        return Perl_re_compile(aTHX_ pattern, flags);
    }

    REGEXP *rx_sv = (REGEXP*) newSV_type(SVt_REGEXP);
    regexp *const rx = SvANY(rx_sv);
    /* Zero the structure before we populate it. This future proofs us
     * from any new fields or whatnot in the REGEXP structure */
    Zero(rx,1,regexp);

    rx->extflags = extflags;
    rx->engine   = &re2_engine;

    rx->pre_prefix = SvCUR(wrapped) - plen - 1;

    RX_WRAPPED(rx_sv) = savepvn(SvPVX(wrapped), SvCUR(wrapped));
    RX_WRAPLEN(rx_sv) = SvCUR(wrapped);

    /* Store our private object */
    rx->pprivate = (void *) ri;

    /* If named captures are defined make rx->paren_names */
    const map<string, int> ncg(ri->NamedCapturingGroups());
    for(map<string, int>::const_iterator it = ncg.begin();
          it != ncg.end();
          ++it) {
        // This block assumes RE2 won't give us multiple named captures of the
        // same name -- it currently doesn't support this.
        SV* value = newSV_type(SVt_PVNV);

        SvIV_set(value, 1);
        SvIOK_on(value);
        I32 offsetp = it->second;
        sv_setpvn(value, (char*)&offsetp, sizeof offsetp);

        if (!RXp_PAREN_NAMES(rx)) {
          RXp_PAREN_NAMES(rx) = newHV();
        }

        hv_store(RXp_PAREN_NAMES(rx), it->first.data(), it->first.size(), value, 0);
    }

    /* these are run time properties, not compile time - and we zero the struct
       above so there is no point in clearing them here.

       rx->lastparen = rx->lastcloseparen = 0;
    */
    rx->nparens = ri->NumberOfCapturingGroups();

#if PERL_VERSION >= 37 && PERL_SUBVERSION >=7
    rx->logical_nparens = rx->nparens;
#endif


    Newxz(rx->offs, rx->nparens + 1, regexp_paren_pair);

    /* return the regexp */
    return rx_sv;
}

#if PERL_VERSION >= 19
I32
RE2_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, SSize_t minend, SV * sv,
          void *data, U32 flags)
#else
I32
RE2_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, I32 minend, SV * sv,
          void *data, U32 flags)
#endif
{
    RE2 * ri = (RE2*) SvANY(rx)->pprivate;
    regexp * re = SvANY(rx);

    re2::StringPiece res[re->nparens + 1];

#ifdef RE2_DEBUG
    Perl_warner(aTHX_ packWARN(WARN_MISC), "RE2: Matching '%s' (%p, %p) against '%s'", stringarg, strbeg, stringarg, RX_WRAPPED(rx));
#endif

    if(stringarg > strend) {
      re->offs[0].start = -1;
      re->offs[0].end   = -1;
      return 0;
    }

    bool ok = ri->Match(
            re2::StringPiece(strbeg, strend - strbeg),
            stringarg - strbeg,
            strend - strbeg,
            RE2::UNANCHORED,
            res, sizeof res / sizeof *res);

    /* Matching failed */
    if (!ok) {
        return 0;
    }

    re->subbeg = strbeg;
    re->sublen = strend - strbeg;

    for (int i = 0; i <= re->nparens; i++) {
        if(res[i].data()) {
            re->offs[i].start = res[i].data() - strbeg;
            re->offs[i].end   = res[i].data() - strbeg + res[i].length();
            /* lastparen is the last paren in the struct that matched,
             * and is used as an optimization by perl.
             * lastcloseparen is the last paren in the struct that was closed
             * lastcloseparen is used to implement $^N */
            re->lastparen = re->lastcloseparen = i;
        } else {
            re->offs[i].start = -1;
            re->offs[i].end   = -1;
        }
    }

    return 1;
}

char *
RE2_intuit(pTHX_ REGEXP * const rx, SV * sv, const char *strbeg, char *strpos,
             char *strend, U32 flags, re_scream_pos_data *data)
{
	PERL_UNUSED_ARG(rx);
	PERL_UNUSED_ARG(sv);
	PERL_UNUSED_ARG(strbeg);
	PERL_UNUSED_ARG(strpos);
	PERL_UNUSED_ARG(strend);
	PERL_UNUSED_ARG(flags);
	PERL_UNUSED_ARG(data);
    return NULL;
}

SV *
RE2_checkstr(pTHX_ REGEXP * const rx)
{
	PERL_UNUSED_ARG(rx);
    return NULL;
}

void
RE2_free(pTHX_ REGEXP * const rx)
{
    delete (RE2 *) SvANY(rx)->pprivate;
}

// Perl polluting our namespace, again.
#undef Copy
void *
RE2_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
	PERL_UNUSED_ARG(param);

    RE2 *previous = (RE2*) SvANY(rx)->pprivate;
    RE2::Options options;
    options.Copy(previous->options());

    return new RE2 (re2::StringPiece(RX_WRAPPED(rx), RX_WRAPLEN(rx)), options);
}

SV *
RE2_package(pTHX_ REGEXP * const rx)
{
	PERL_UNUSED_ARG(rx);
	return newSVpvs("re::engine::RE2");
}

};

// Unnamespaced
extern "C" void RE2_possible_match_range(pTHX_ REGEXP* rx, STRLEN len, SV** min_sv, SV** max_sv)
{
    const RE2 *const re2 = (RE2*) SvANY(rx)->pprivate;
    string min, max;

    re2->PossibleMatchRange(&min, &max, (int)len);

    *min_sv = newSVpvn(min.data(), min.size());
    *max_sv = newSVpvn(max.data(), max.size());

    return;
}

extern "C" HV* RE2_named_captures(pTHX_ REGEXP* rx)
{
    const RE2 *const re2 = (RE2*) SvANY(rx)->pprivate;
    const map<string, int> ncg(re2->NamedCapturingGroups());
    HV* hv = newHV();
    for(map<string, int>::const_iterator it = ncg.begin();
          it != ncg.end();
          ++it) {
        hv_store(hv, it->first.data(), it->first.size(), newSViv(it->second), 0);
    }

    return hv;
}

extern "C" int RE2_number_of_capture_groups(pTHX_ REGEXP* rx)
{
    const RE2 *const re2 = (RE2*) SvANY(rx)->pprivate;
    return re2->NumberOfCapturingGroups();
}

// ex:sw=4 et:
