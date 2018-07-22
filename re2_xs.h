#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

START_EXTERN_C
EXTERN_C const regexp_engine re2_engine;
EXTERN_C void RE2_possible_match_range(pTHX_ REGEXP* rx, STRLEN len, SV **possible_min, SV **possible_max);
EXTERN_C HV* RE2_named_captures(pTHX_ REGEXP* rx);
EXTERN_C int RE2_number_of_capture_groups(pTHX_ REGEXP* rx);
END_EXTERN_C

