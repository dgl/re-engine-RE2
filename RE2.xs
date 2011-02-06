#include "re2_xs.h"

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

        RE2_possible_match_range(rx, len, &possible_min, &possible_max);

        XPUSHs(possible_min);
        XPUSHs(possible_max);

void
set_max_mem(int mem)
PROTOTYPE: $
PPCODE:
	re2_max_mem = mem;
