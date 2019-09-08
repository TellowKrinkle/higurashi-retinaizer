#ifndef Replacements_h
#define Replacements_h

#include "Retinaizer.h"
#include <stdbool.h>

Pointf GetMouseOriginReplacement(void *mgr);
void ReadMousePosReplacement(void);
bool SetResImmediateReplacement(void *, int, int, bool, int);
void CreateAndShowWindowReplacement(void *mgr, int width, int height, bool fullscreen);
void PreBlitReplacement(void *mgr);
void WindowDidResizeReplacement(id<NSWindowDelegate> self, SEL sel, NSNotification * notification);

#endif /* Replacements_h */