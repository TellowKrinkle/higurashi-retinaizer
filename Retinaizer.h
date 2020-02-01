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

/// 6-digit hex number where each pair of digits represents one part of the Unity semantic version (so 5.2.2 would be 0x050202)
extern int UnityVersion;
static const int UNITY_VERSION_ONI = 0x050202;
static const int UNITY_VERSION_TATARI_OLD = 0x050304;

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
	bool (*ScreenMgrSetFullscreenResolutionRobustly)(void *, int *, int *, int, bool, void *);
	void (*ScreenMgrDidChangeScreenMode)(void *, int, int, int, void *, IntVector *);
	void (*ScreenMgrSetupDownscaledFullscreenFBO)(void *, int, int);

	void (*Matrix4x4fSetOrtho)(Matrix4x4f *, float, float, float, float, float, float);

	int *gDefaultFBOGL;
	int *gRenderer;
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

extern struct ScreenManagerOffsets {
	size_t getHeightMethod;
	size_t isFullscreenMethod;
	size_t releaseModeMethod;
	size_t windowOffset;
	size_t playerWindowViewOffset;
	size_t playerWindowDelegateOffset;
} screenMgrOffsets;

extern struct GfxDeviceOffsets {
	size_t finishRenderingMethod;
} gfxDevOffsets;

extern struct PlayerSettingsOffsets {
	size_t collectionBehaviorFlag;
} playerSettingsOffsets;

#endif /* Retinaizer_h */
