#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

START_EXTERN_C
EXTERN_C const regexp_engine re2_engine;
EXTERN_C void RE2_possible_match_range(pTHX_ REGEXP* rx, STRLEN len, SV **possible_min, SV **possible_max);
END_EXTERN_C

