#ifndef Replacements_h
#define Replacements_h

#include "Retinaizer.h"
#include <stdbool.h>

Pointf GetMouseOriginReplacement(void *mgr);
void ReadMousePosReplacement(void);
bool SetResImmediateReplacement(void *, int, int, bool, int);

#endif /* Replacements_h */
