#include "re2_xs.h"

MODULE = re::engine::RE2 PACKAGE = re::engine::RE2
PROTOTYPES: ENABLE

void
ENGINE(...)
PROTOTYPE:
PPCODE:
	XPUSHs(sv_2mortal(newSViv(PTR2IV(&re2_engine))));
