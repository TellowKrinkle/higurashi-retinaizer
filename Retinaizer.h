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
	ScreenManager *(*GetScreenManager)(void);
	InputManager *(*GetInputManager)(void);
	GfxDevice *(*GetGfxDevice)(void);
	QualitySettings *(*GetQualitySettings)(void);
	PlayerSettings *(*GetPlayerSettings)(void);
	GfxDevice *(*GetRealGfxDevice)(void);
	uint32_t (*GetRequestedDeviceLevel)(void);
	bool (*IsBatchMode)(void);
	bool (*MustSwitchResolutionForFullscreenMode)(void);
	bool (*AllowResizableWindow)(void);
	char *(*ApplicationGetCustomPropUnityVersion)(void);

	void (*SetSyncToVBL)(void *, int);
	void (*PlayerPrefsSetInt)(StdString *, int);
	union {
		void *(*oni)(uint32_t, int, int, int, bool, bool, uint32_t, int *, bool);
		void *(*me )(uint32_t, int, int, int, bool,       uint32_t, int *);
	} MakeNewContext;
	union {
		void (*oni)(void *, int, int,      unsigned int);
		void (*me )(void *, int, int, int, unsigned int);
	} RenderTextureSetActive;
	void (*RenderTextureReleaseAll)(void);
	void (*DestroyMainContextGL)(void);
	void (*RecreateSurface)(void);
	union {
		void (*oni   )(void *, void *, bool, float, float);
		void (*tatari)(void *, void *, bool, RectT<float>*);
	} GfxHelperDrawQuad;
	bool (*ActivateGraphicsContext)(void *, bool, int);

	CGDirectDisplayID (*ScreenMgrGetDisplayID)(ScreenManager *);
	void (*ScreenMgrWillChangeMode)(ScreenManager *, IntVector *);
	bool (*ScreenMgrSetFullscreenResolutionRobustly)(ScreenManager *, int *, int *, int, bool, void *);
	void (*ScreenMgrDidChangeScreenMode)(ScreenManager *, int, int, int, void *, IntVector *);
	void (*ScreenMgrSetupDownscaledFullscreenFBO)(ScreenManager *, int, int);
	void (*ScreenMgrRebindDefaultFramebuffer)(ScreenManager *);

	void (*Matrix4x4fSetOrtho)(Matrix4x4f *, float, float, float, float, float, float);

	int *gDefaultFBOGL;
	int *gRenderer;
	CGSize *gMetalSurfaceRequestedSize;
	bool *gPopUpWindow;
	Matrix4x4f *identityMatrix;
	struct DisplayDevice (*displayDevices)[8];
} unityMethods;

extern struct CPPMethods {
	void (*MakeStdString)(StdString*, const char *, void *); // &this, cStr, allocator
	void *stdStringEmptyRepStorage;
	void (*DestroyStdStringRep)(void *, void *); // &this, allocator
	void (*operatorDelete)(void *);
} cppMethods;

#endif /* Retinaizer_h */
