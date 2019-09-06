#include "Replacements.h"
#include <OpenGL/glext.h>

#pragma mark - Helpers

static void *getVtableEntry(void *object, size_t offset) {
	void **vtable = *(void **)object;
	return *(vtable + offset / sizeof(void *));
}

static void *getField(void *object, size_t offset) {
	return (char *)object + offset;
}

static StdString makeStdString(const char *str) {
	StdString stdStr;
	cppMethods.MakeStdString(&stdStr, str, NULL);
	return stdStr;
}

static void destroyStdString(StdString str) {
	if (str.c_str - 24 != cppMethods.stdStringEmptyRepStorage) {
		int refcnt = __atomic_fetch_add((int *)(str.c_str - 8), -1, __ATOMIC_ACQ_REL);
		if (refcnt < 1) {
			cppMethods.DestroyStdStringRep(str.c_str - 24, NULL);
		}
	}
}

enum ScreenMgrOffsets {
	ScreenMgrWindowOffset = 0x70,
};

#pragma mark - Replacement Functions

Pointf GetMouseOriginReplacement(void *mgr) {
	void *windowPtr = *(void **)getField(mgr, ScreenMgrWindowOffset);
	if (windowPtr) {
		WindowFakeSizer *window = (__bridge WindowFakeSizer*)windowPtr;
		CGRect contentRect = [window actualContentRectForFrameRect:[window frame]];
		NSScreen *screen = [[NSScreen screens] objectAtIndex:0];
		double height = 0;
		if (screen) {
			height = [screen frame].size.height;
		}
		Pointf ret = (Pointf){contentRect.origin.x, height - contentRect.origin.y - contentRect.size.height};
		return ret;
	}
	else {
		return (Pointf){0, 0};
	}
}

void ReadMousePosReplacement() {
	CGEventRef event = CGEventCreate(NULL);
	CGPoint point = CGEventGetLocation(event);
	CFRelease(event);

	void *screenMgr = unityMethods.GetScreenManager();
	char(*isFullscreenMethod)(void *) = getVtableEntry(screenMgr, 0xb8);
	CGPoint origin;
	if (isFullscreenMethod(screenMgr)) {
		CGDirectDisplayID displayID = unityMethods.ScreenMgrGetDisplayID(screenMgr);
		origin = CGDisplayBounds(displayID).origin;
	}
	else {
		Pointf pt = GetMouseOriginReplacement(screenMgr);
		origin = (CGPoint){ pt.x, pt.y };
	}
	int (*getHeightMethod)(void *) = getVtableEntry(screenMgr, 0xa8);
	int screenHeight = getHeightMethod(screenMgr);
	NSPoint windowRelative = { point.x - origin.x, point.y - origin.y };
	void *windowPtr = *(void **)getField(screenMgr, ScreenMgrWindowOffset);
	if (windowPtr) {
		WindowFakeSizer *window = (__bridge WindowFakeSizer*)windowPtr;
		windowRelative = [window convertRectToBacking:(NSRect){windowRelative, NSZeroSize}].origin;
	}
	void *inputManager = unityMethods.GetInputManager();
	Pointf *output = getField(inputManager, 0xb0);
	*output = (Pointf){ windowRelative.x, screenHeight - windowRelative.y };
}

// TODO: Currently unmodified
bool SetResImmediateReplacement(void *mgr, int width, int height, bool fullscreen, int refreshRate) {
	bool ret = false;
	void *gfxDevice = unityMethods.GetGfxDevice();
	void (*finishRenderingMethod)(void *) = getVtableEntry(gfxDevice, 0x3f0);
	finishRenderingMethod(gfxDevice);
	bool isBatchMode = unityMethods.IsBatchMode();
	if (isBatchMode) { return false; }
	WindowFakeSizer *window = (__bridge WindowFakeSizer *)*(void **)getField(mgr, ScreenMgrWindowOffset);
	if ((([window styleMask] & NSWindowStyleMaskFullScreen) != 0) != fullscreen) {
		[window toggleFullScreen:NULL];
	}
	IntVector modeVec = {0};
	unityMethods.ScreenMgrWillChangeMode(mgr, &modeVec);
	void (*releaseModeMethod)(void *) = getVtableEntry(mgr, 0x100);
	releaseModeMethod(mgr);
	uint32_t level = unityMethods.GetRequestedDeviceLevel();
	bool mustSwitchResolution = fullscreen && unityMethods.MustSwitchResolutionForFullscreenMode();
	int unk1 = -1;
	void *context = unityMethods.MakeNewContext(level, width, height, mustSwitchResolution, true, false, 2, &unk1, true);
	if (context) {
		void *qualitySettings = unityMethods.GetQualitySettings();
		int currentQualityIdx = *(int *)getField(qualitySettings, 0x44);
		void *settingsVector = *(void **)getField(qualitySettings, 0x28);
		int vSyncCount = *(int *)getField((char *)settingsVector + 0x60 * currentQualityIdx, 0x44);
		unityMethods.SetSyncToVBL(context, vSyncCount);
		if (mustSwitchResolution) {
			unityMethods.ScreenMgrSetFullscreenResolutionRobustly(mgr, &width, &height, fullscreen, false, context);
		}
		else {
			unityMethods.ScreenMgrCreateAndShowWindow(mgr, width, height, fullscreen);
			PlayerWindowView *view = (__bridge PlayerWindowView *)*(void **)getField(mgr, 0x78);
			[view setContext:*(CGLContextObj *)context];
			if (!fullscreen) {
				if (window) {
					CGRect frame = [window convertRectToBacking:[window actualContentRectForFrameRect:[window frame]]];
					height = frame.size.height;
					width = frame.size.width;
				}
				else {
					height = width = 0;
				}
			}
		}
		bool *isFullscreen = getField(mgr, 0x23);
		*isFullscreen = fullscreen;
		unityMethods.RenderTextureReleaseAll();
		unityMethods.DestroyMainContextGL();

		StdString prefname = makeStdString("Screenmanager Resolution Width");
		unityMethods.PlayerPrefsSetInt(&prefname, width);
		destroyStdString(prefname);
		prefname = makeStdString("Screenmanager Resolution Height");
		unityMethods.PlayerPrefsSetInt(&prefname, height);
		destroyStdString(prefname);
		prefname = makeStdString("Screenmanager Is Fullscreen mode");
		unityMethods.PlayerPrefsSetInt(&prefname, fullscreen);
		destroyStdString(prefname);
		unityMethods.ScreenMgrDidChangeScreenMode(mgr, width, height, fullscreen, context, &modeVec);
		*unityMethods.gDefaultFBOGL = 0;
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
		ret = true;
		if (fullscreen && !unityMethods.MustSwitchResolutionForFullscreenMode()) {
			CGDirectDisplayID display = unityMethods.ScreenMgrGetDisplayID(mgr);
			CGRect bounds = CGDisplayBounds(display);
			if (width != bounds.size.width || height != bounds.size.height) {
				unityMethods.ScreenMgrSetupDownscaledFullscreenFBO(mgr, width, height);
			}
		}
	}
	if (modeVec.begin != NULL) {
		cppMethods.operatorDelete(modeVec.begin);
	}
	return ret;
};
