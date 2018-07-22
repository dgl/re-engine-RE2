#include "re2_xs.h"
#include "ppport.h"

MODULE = re::engine::RE2 PACKAGE = re::engine::RE2
PROTOTYPES: ENABLE

void
ENGINE(...)
PROTOTYPE:
PPCODE:
	XPUSHs(sv_2mortal(newSViv(PTR2IV(&re2_engine))));

# Use a typemap for this maybe, especially if we add more methods like it!
void
possible_match_range(SV *self, STRLEN len = 10)
PROTOTYPE:
PPCODE:
        REGEXP* rx;
        SV *possible_min, *possible_max;

        if(!SvROK(self) || 0 != strcmp("re::engine::RE2", sv_reftype(SvRV(self), TRUE)))
                croak("qr// reference to a re::engine::RE2 instance required");
        rx = SvRX(self);

        RE2_possible_match_range(aTHX_ rx, len, &possible_min, &possible_max);

        mXPUSHs(possible_min);
        mXPUSHs(possible_max);

HV*
named_captures(SV *self)
PROTOTYPE:
CODE:
        REGEXP* rx;
        if(!SvROK(self) || 0 != strcmp("re::engine::RE2", sv_reftype(SvRV(self), TRUE)))
                croak("qr// reference to a re::engine::RE2 instance required");
        rx = SvRX(self);
        RETVAL = RE2_named_captures(aTHX_ rx);
OUTPUT:
        RETVAL

int
number_of_capture_groups(SV *self)
PROTOTYPE:
CODE:
        REGEXP* rx;
        if(!SvROK(self) || 0 != strcmp("re::engine::RE2", sv_reftype(SvRV(self), TRUE)))
                croak("qr// reference to a re::engine::RE2 instance required");
        rx = SvRX(self);
        RETVAL = RE2_number_of_capture_groups(aTHX_ rx);
OUTPUT:
        RETVAL
