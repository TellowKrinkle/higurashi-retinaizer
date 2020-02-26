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
	GfxDevice *(*GetRealGfxDevice)(void);
	QualitySettings *(*GetQualitySettings)(void);
	PlayerSettings *(*GetPlayerSettings)(void);
	MetalSurfaceHelper *(*GetCurrentMetalSurface)(void);
	uint32_t (*GetRequestedDeviceLevel)(void);
	GfxFramebufferGLES *(*GetFramebufferGLES)(void);
	bool (*IsBatchMode)(void);
	bool (*MustSwitchResolutionForFullscreenMode)(void);
	bool (*AllowResizableWindow)(void);
	bool (*IsRealGfxDeviceThreadOwner)(void);
	char *(*ApplicationGetCustomPropUnityVersion)(void);

	void (*SetSyncToVBL)(void *, int);
	union {
		void (*oni )(StdString *,            int);
		void (*mina)(StringStorageDefault *, int);
	} PlayerPrefsSetInt;
	union {
		void *(*oni )(uint32_t, int, int, int, bool, bool, uint32_t, int *, bool);
		void *(*me  )(uint32_t, int, int, int, bool,       uint32_t, int *);
		void *(*mina)(uint32_t, int, int, int, bool,       uint32_t);
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
	union {
		void (*oni )(ScreenManager *, int, int, int, void *, IntVector *);
		void (*mina)(ScreenManager *, int, int, int, void *);
	} ScreenMgrDidChangeScreenMode;
	void (*ScreenMgrSetupDownscaledFullscreenFBO)(ScreenManager *, int, int);
	void (*ScreenMgrRebindDefaultFramebuffer)(ScreenManager *);

	union {
		GLuint *(*tatari)(GLuint *, GfxFramebufferGLES *, GfxRenderTargetSetup *);
		GLHandle (*me)(GfxFramebufferGLES *, GfxRenderTargetSetup *);
	} GfxFBGLESGetFramebufferName;
	union {
		void (*tatari)(ApiGLES *, GLuint *, int, GLuint *, GLuint *, int, int, int, int, int, int, int, int, int);
		void (*me    )(ApiGLES *, GLHandle, int, GLHandle, GLHandle, int, int, int, int, int, int, int, int, int);
	} ApiGLESBlitFramebuffer;
	union {
		void (*tatari)(ApiGLES *, GLuint, GLuint *);
		void (*me    )(ApiGLES *, GLuint, GLHandle);
	} ApiGLESBindFramebuffer;
	void (*ApiGLESClear)(ApiGLES *, GLbitfield, ColorRGBAf *, bool, float, int);

	void (*Matrix4x4fSetOrtho)(Matrix4x4f *, float, float, float, float, float, float);

	void (*StringStorageDefaultAssign)(StringStorageDefault *, const char *, unsigned long);
	void (*FreeAllocInternal)(void *, int);

	int *gDefaultFBOGL;
	int *gRenderer;
	ApiGLES *gGL;
	CGSize *gMetalSurfaceRequestedSize;
	bool *gPopUpWindow;
	Matrix4x4f *identityMatrix;
	struct DisplayDevice (*displayDevices)[8];
} unity;

extern struct CPPMethods {
	void (*MakeStdString)(StdString*, const char *, void *); // &this, cStr, allocator
	void *stdStringEmptyRepStorage;
	void (*DestroyStdStringRep)(void *, void *); // &this, allocator
	void (*operatorDelete)(void *);
} cppMethods;

#endif /* Retinaizer_h */
