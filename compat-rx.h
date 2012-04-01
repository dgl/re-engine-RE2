/* Compatibility for RX_* macros added around 5.10.1. */

#ifndef RX_WRAPPED
#define RX_WRAPPED(prog) ((prog)->wrapped)
#define RX_WRAPLEN(prog) ((prog)->wraplen)
#endif

