#define PERL_NO_GET_CONTEXT

// This needs to be first, Perl is rude and defines macros like "Copy"
#include <re2/re2.h>
#include "re2_xs.h"
#include "compat-cophh.h"

#if PERL_VERSION > 10
#define RegSV(p) SvANY(p)
#else
#define RegSV(p) (p)
#endif

namespace {
    REGEXP * RE2_comp(pTHX_
// Constness differs on different versions of Perl
#if PERL_VERSION == 10
            const
#endif
            SV * const, U32);
    I32      RE2_exec(pTHX_ REGEXP * const, char *, char *,
                      char *, I32, SV *, void *, U32);
    char *   RE2_intuit(pTHX_ REGEXP * const, SV *, char *,
                        char *, U32, re_scream_pos_data *);
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
};

namespace {

REGEXP *
RE2_comp(pTHX_
#if PERL_VERSION == 10
        const
#endif
        SV * const pattern, const U32 flags)
{
    const char *const exp = SvPVX(pattern);
    const STRLEN plen = SvCUR(pattern);
    U32 extflags = flags;

    RE2::Options options;
    bool perl_only = false;

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

    // XXX: Probably should allow control of this somehow
    options.set_log_errors(false);

    SV *const max_mem = cophh_fetch_pvs(PL_curcop->cop_hints_hash,
            "re::engine::RE2::max-mem", 0);
    if (SvOK(max_mem) && SvIV_nomg(max_mem)) {
        options.set_max_mem(SvIV(max_mem));
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
            const std::string error = ri->error();
            delete ri;

            croak(perl_only
                    ? "/x is not supported by RE2"
                    : error.c_str());
            return NULL; // unreachable
        }

        delete ri;

        // Fallback. Perl will either compile or print errors for us.
        return Perl_re_compile(aTHX_ pattern, flags);
    }

    REGEXP *rx_sv;
#if PERL_VERSION > 10
    rx_sv = (REGEXP*) newSV_type(SVt_REGEXP);
#else
    Newxz(rx_sv, 1, REGEXP);
    rx_sv->refcnt = 1;
#endif
    regexp *const rx = RegSV(rx_sv);

    rx->extflags = extflags;
    rx->engine   = &re2_engine;

#if PERL_VERSION >= 11
    rx->pre_prefix = SvCUR(wrapped) - plen - 1;
#endif

#if PERL_VERSION == 10
    rx->wraplen = SvCUR(wrapped);
    rx->wrapped = savepvn(SvPVX(wrapped), SvCUR(wrapped));
#else
    RX_WRAPPED(rx_sv) = savepvn(SvPVX(wrapped), SvCUR(wrapped));
    RX_WRAPLEN(rx_sv) = SvCUR(wrapped);
#endif

#if PERL_VERSION == 10
    /* Preserve a copy of the original pattern */
    rx->prelen = (I32)plen;
    rx->precomp = savepvn(exp, plen);
#endif

    /* Store our private object */
    rx->pprivate = (void *) ri;

#if 0
    ri->NamedCapturingGroups();
    /* If named captures are defined make rx->paren_names */
#endif

    rx->lastparen = rx->lastcloseparen = rx->nparens = ri->NumberOfCapturingGroups();

    Newxz(rx->offs, rx->nparens + 1, regexp_paren_pair);

    /* return the regexp */
    return rx_sv;
}

I32
RE2_exec(pTHX_ REGEXP * const rx, char *stringarg, char *strend,
          char *strbeg, I32 minend, SV * sv,
          void *data, U32 flags)
{
    RE2 * ri = (RE2*) RegSV(rx)->pprivate;
    regexp * re = RegSV(rx);

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
        } else {
            re->offs[i].start = -1;
            re->offs[i].end   = -1;
        }
    }

    return 1;
}

char *
RE2_intuit(pTHX_ REGEXP * const rx, SV * sv, char *strpos,
             char *strend, U32 flags, re_scream_pos_data *data)
{
	PERL_UNUSED_ARG(rx);
	PERL_UNUSED_ARG(sv);
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
    delete (RE2 *) RegSV(rx)->pprivate;
}

void *
RE2_dupe(pTHX_ REGEXP * const rx, CLONE_PARAMS *param)
{
	PERL_UNUSED_ARG(param);
    return RegSV(rx)->pprivate;
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
    const RE2 *const re2 = (RE2*) RegSV(rx)->pprivate;
    std::string min, max;

    re2->PossibleMatchRange(&min, &max, (int)len);

    *min_sv = newSVpvn(min.data(), min.size());
    *max_sv = newSVpvn(max.data(), max.size());

    return;
}

// ex:sw=4 et:
