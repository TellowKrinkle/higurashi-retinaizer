#ifndef Retinaizer_h
#define Retinaizer_h

#import <Cocoa/Cocoa.h>
#include "CppTypes.h"

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
	void *(*GetPlayerSettings)(void);
	void *(*GetRealGfxDevice)(void);
	uint32_t (*GetRequestedDeviceLevel)(void);
	bool (*IsBatchMode)(void);
	bool (*MustSwitchResolutionForFullscreenMode)(void);
	bool (*AllowResizableWindow)(void);
	char *(*ApplicationGetCustomPropUnityVersion)(void);

	void (*SetSyncToVBL)(void *, int);
	void (*PlayerPrefsSetInt)(StdString *, int);
	void *(*MakeNewContext)(uint32_t, int, int, int, bool, bool, uint32_t, int *, bool);
	void (*RenderTextureReleaseAll)(void);
	void (*DestroyMainContextGL)(void);
	void (*GfxHelperDrawQuad)(void *, void *, bool, float, float);

	CGDirectDisplayID (*ScreenMgrGetDisplayID)(void *);
	void (*ScreenMgrWillChangeMode)(void *, IntVector *);
	void (*ScreenMgrSetFullscreenResolutionRobustly)(void *, int *, int *, int, bool, void *);
	void (*ScreenMgrDidChangeScreenMode)(void *, int, int, int, void *, IntVector *);
	void (*ScreenMgrSetupDownscaledFullscreenFBO)(void *, int, int);

	void (*Matrix4x4fSetOrtho)(Matrix4x4f *, float, float, float, float, float, float);

	int *gDefaultFBOGL;
	bool *gPopUpWindow;
	Matrix4x4f *identityMatrix;
	struct DisplayDevice (*displayDevices)[8];
} unityMethods;

extern struct CPPMethods {
	void (*MakeStdString)(StdString*, const char *, void *); // &this, cStr, allocator
	void *stdStringEmptyRepStorage;
	void (*DestroyStdStringRep)(void *, void *); // &this, allocator
	void (*operatorDelete)(void *);
	char *(*mono_string_to_utf8)(void *monoString);
} cppMethods;

#endif /* Retinaizer_h */
