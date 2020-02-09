#ifndef Replacements_h
#define Replacements_h

#include "Retinaizer.h"
#include <stdbool.h>

Pointf GetMouseOriginReplacement(ScreenManager *mgr);
Pointf *TatariGetMouseOriginReplacement(Pointf *output, ScreenManager *mgr);
void ReadMousePosReplacement(void);
Pointf GetMouseScaleReplacement(ScreenManager *mgr);
Pointf *TatariGetMouseScaleReplacement(Pointf *output, ScreenManager *mgr);
bool SetResImmediateReplacement(ScreenManager *, int, int, bool, int);
void CreateAndShowWindowReplacement(ScreenManager *mgr, int width, int height, bool fullscreen);
void PreBlitReplacement(ScreenManager *mgr);
void WindowDidResizeReplacement(id<NSWindowDelegate> self, SEL sel, NSNotification * notification);

#endif /* Replacements_h */
