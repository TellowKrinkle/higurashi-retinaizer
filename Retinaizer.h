#ifndef Retinaizer_h
#define Retinaizer_h

#import <Cocoa/Cocoa.h>
#include "CppTypes.h"

@interface WindowFakeSizer : NSWindow

- (NSRect)actualContentRectForFrameRect:(NSRect)frameRect;

@end

@interface PlayerWindowView : NSView

- (void)setContext:(CGLContextObj)context;

@end

typedef struct Pointf {
	float x;
	float y;
} Pointf;

extern struct UnityMethods {
	void *(*GetScreenManager)(void);
	void *(*GetInputManager)(void);
	void *(*GetGfxDevice)(void);
	void *(*GetQualitySettings)(void);
	uint32_t (*GetRequestedDeviceLevel)(void);
	bool (*IsBatchMode)(void);
	bool (*MustSwitchResolutionForFullscreenMode)(void);

	void (*SetSyncToVBL)(void *, int);
	void (*PlayerPrefsSetInt)(StdString *, int);
	void *(*MakeNewContext)(uint32_t, int, int, int, bool, bool, uint32_t, int *, bool);

	void (*RenderTextureReleaseAll)(void);
	void (*DestroyMainContextGL)(void);

	CGDirectDisplayID (*ScreenMgrGetDisplayID)(void *);
	Pointf (*ScreenMgrGetMouseScale)(void *);
	void (*ScreenMgrWillChangeMode)(void *, IntVector *);
	void (*ScreenMgrSetFullscreenResolutionRobustly)(void *, int *, int *, int, bool, void *);
	void (*ScreenMgrCreateAndShowWindow)(void *, int, int, bool);
	void (*ScreenMgrDidChangeScreenMode)(void *, int, int, int, void *, IntVector *);
	void (*ScreenMgrSetupDownscaledFullscreenFBO)(void *, int, int);

	int *gDefaultFBOGL;
} unityMethods;

extern struct CPPMethods {
	void (*MakeStdString)(StdString*, const char *, void *); // &this, cStr, allocator
	void *stdStringEmptyRepStorage;
	void (*DestroyStdStringRep)(void *, void *); // &this, allocator
	void (*operatorDelete)(void *);
} cppMethods;

#endif /* Retinaizer_h */
