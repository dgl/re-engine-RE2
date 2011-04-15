/* Compatibility for bits of the cophh API which was added in 5.13.7.
 * This uses refcounted_he_* functions that are not part of the public perl
 * API, therefore won't work on platforms with strict linkers (Windows, AIX).
 */
#if PERL_VERSION < 13 || (PERL_VERSION == 13 && PERL_SUBVERSION < 7)

#define cophh_fetch_pvs(cophh, key, flags) \
    Perl_refcounted_he_fetch(aTHX_ cophh, NULL, key, sizeof(key) - 1, 0, flags)

#endif
