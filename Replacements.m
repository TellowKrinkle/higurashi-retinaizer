#include "Replacements.h"
#include "Offsets.h"
#include <OpenGL/glext.h>
#include <OpenGL/gl.h>
#include <Carbon/Carbon.h>

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

static NSScreen *screenForID(CGDirectDisplayID display) {
	for (NSScreen *screen in [NSScreen screens]) {
		if (display == [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] intValue]) {
			return screen;
		}
	}
	return nil;
}

#pragma mark - Replacement Functions
// Note: All functions have checks of toggleFullScreen support disabled, since this should only run on retina (10.7+) macs
// Higurashi games actually have an official minimum version of 10.11 so this isn't an issue, but if you plan to run this on a game that supports older macOS versions, add an @available check to goRetina.

Pointf GetMouseOriginReplacement(ScreenManager *mgr) {
	// Currently unmodified from the original, previously, when we overrode NSWindow contentRectForFrameRect we needed to modify this to undo that, but we no longer use that hack.
	NSWindow *window = (__bridge NSWindow*)*(void **)getField(mgr, screenMgrOffsets.window);
	if (window) {
		CGRect contentRect = [window contentRectForFrameRect:[window frame]];
		NSScreen *screen = [[NSScreen screens] objectAtIndex:0];
		double height = [screen frame].size.height;
		Pointf ret = (Pointf){contentRect.origin.x, height - contentRect.origin.y - contentRect.size.height};
		return ret;
	}
	else {
		return (Pointf){0, 0};
	}
}

Pointf *TatariGetMouseOriginReplacement(Pointf *output, ScreenManager *mgr) {
	*output = GetMouseOriginReplacement(mgr);
	return output;
}

void ReadMousePosReplacement() {
	CGEventRef event = CGEventCreate(NULL);
	CGPoint point = CGEventGetLocation(event);
	CFRelease(event);

	ScreenManager *screenMgr = unityMethods.GetScreenManager();
	char(*isFullscreenMethod)(ScreenManager *) = getVtableEntry(screenMgr, screenMgrOffsets.isFullscreenMethod);
	CGPoint origin;
	if (isFullscreenMethod(screenMgr)) {
		CGDirectDisplayID displayID = unityMethods.ScreenMgrGetDisplayID(screenMgr);
		origin = CGDisplayBounds(displayID).origin;
		// Original binary gets mouse scale and multiplies by it.  In macOS, mouse coordinates are in display points, as are window positions, so multiplying by mouse scale would break things rather than fixing things.
	}
	else {
		Pointf pt = GetMouseOriginReplacement(screenMgr);
		origin = (CGPoint){ pt.x, pt.y };
	}
	// Note: the height from ScreenManager is in retina coordinates
	int (*getHeightMethod)(ScreenManager *) = getVtableEntry(screenMgr, screenMgrOffsets.getHeightMethod);
	int windowHeight = getHeightMethod(screenMgr);
	NSPoint windowRelative = { point.x - origin.x, point.y - origin.y };
	NSWindow *window = (__bridge NSWindow *)*(void **)getField(screenMgr, screenMgrOffsets.window);
	if (window) {
		windowRelative = [window convertRectToBacking:(NSRect){windowRelative, NSZeroSize}].origin;
	}
	InputManager *inputManager = unityMethods.GetInputManager();
	Pointf *output = getField(inputManager, 0xb0);
	*output = (Pointf){ windowRelative.x, windowHeight - windowRelative.y };
}

Pointf GetMouseScaleReplacement(ScreenManager *mgr) {
	bool mustSwitch = unityMethods.MustSwitchResolutionForFullscreenMode();
	NSWindow *window = (__bridge NSWindow *)*(void **)getField(mgr, screenMgrOffsets.window);
	if (!mustSwitch && window) {
		// Added convertRectToBacking: for retina support
		CGRect frame = [window convertRectToBacking:[window contentRectForFrameRect:[window frame]]];
		int *width = getField(mgr, 0x64);
		int *height = getField(mgr, 0x68);
		return (Pointf){ *width / frame.size.width, *height / frame.size.height };
	}
	return (Pointf){1, 1};
}

Pointf *TatariGetMouseScaleReplacement(Pointf *output, ScreenManager *mgr) {
	*output = GetMouseScaleReplacement(mgr);
	return output;
}

bool SetResImmediateReplacement(ScreenManager *mgr, int width, int height, bool fullscreen, int refreshRate) {
	bool ret = false;
	GfxDevice *gfxDevice = unityMethods.GetGfxDevice();
	void (*finishRenderingMethod)(GfxDevice *) = getVtableEntry(gfxDevice, gfxDevOffsets.finishRenderingMethod);
	finishRenderingMethod(gfxDevice);
	bool isBatchMode = unityMethods.IsBatchMode();
	if (isBatchMode) { return false; }
	NSWindow *window = (__bridge NSWindow *)*(void **)getField(mgr, screenMgrOffsets.window);
	if ((([window styleMask] & NSWindowStyleMaskFullScreen) != 0) != fullscreen) {
		[window toggleFullScreen:NULL];
		// The original binary doesn't do this, but when defullscreening with the green window button, this method is called with fullscreen still true.  This causes toggleFullScreen to do nothing (because it's already happening) and messes up later code which assumes the fullscreen variable corresponds to the state of the window.
		fullscreen = [window styleMask] & NSWindowStyleMaskFullScreen;
	}
	IntVector modeVec = {0};
	unityMethods.ScreenMgrWillChangeMode(mgr, &modeVec);
	void (*releaseModeMethod)(ScreenManager *) = getVtableEntry(mgr, screenMgrOffsets.releaseModeMethod);
	releaseModeMethod(mgr);
	if (UnityVersion >= UNITY_VERSION_TATARI_OLD) {
		// Onikakushi calls this later
		unityMethods.RenderTextureReleaseAll();
	}
	uint32_t level = unityMethods.GetRequestedDeviceLevel();
	bool mustSwitchResolution = fullscreen && unityMethods.MustSwitchResolutionForFullscreenMode();

	void *context = NULL;
	bool tatariGRendererCheck = UnityVersion >= UNITY_VERSION_TATARI_OLD && *unityMethods.gRenderer != 0x10;
	bool needsToMakeContext = UnityVersion < UNITY_VERSION_TATARI_OLD || tatariGRendererCheck;

	if (needsToMakeContext) {
		int unk1 = -1;
		context = unityMethods.MakeNewContext(level, width, height, mustSwitchResolution, true, false, 2, &unk1, true);
		if (!context) { goto cleanup; }
		QualitySettings *qualitySettings = unityMethods.GetQualitySettings();
		int currentQualityIdx = *(int *)getField(qualitySettings, qualitySettingsOffsets.currentQuality);
		QualitySetting *settingsVector = *(void **)getField(qualitySettings, qualitySettingsOffsets.settingsVector);
		int vSyncCount = *(int *)getField((char *)settingsVector + qualitySettingOffsets.size * currentQualityIdx, qualitySettingOffsets.vSyncCount);
		unityMethods.SetSyncToVBL(context, vSyncCount);
	}

	bool needsCreateAndShowWindow = !mustSwitchResolution;
	if (mustSwitchResolution) {
		bool success = unityMethods.ScreenMgrSetFullscreenResolutionRobustly(mgr, &width, &height, fullscreen, false, context);
		if (UnityVersion >= UNITY_VERSION_TATARI_OLD && !success) {
			needsCreateAndShowWindow = true;
			fullscreen = false;
		}
	}
	if (needsCreateAndShowWindow) {
		CreateAndShowWindowReplacement(mgr, width, height, fullscreen);
		PlayerWindowView *view = (__bridge PlayerWindowView *)*(void **)getField(mgr, screenMgrOffsets.playerWindowView);
		if (needsToMakeContext) {
			[view setContext:*(CGLContextObj *)context];
		}
		// Original binary only updates width and height in non-fullscreen, which causes weirdness with retina because then the ScreenManager height would be the retina height for non-fs windows and non-retina height for fs windows.
		CGRect frame;
		if (fullscreen) {
			frame = [window convertRectToBacking:[window frame]];
		}
		else {
			frame = [window convertRectToBacking:[window contentRectForFrameRect:[window frame]]];
		}
		width = frame.size.width;
		height = frame.size.height;
	}
	bool *isFullscreen = getField(mgr, 0x23);
	*isFullscreen = fullscreen;
	if (UnityVersion < UNITY_VERSION_TATARI_OLD) {
		// Tatari+ calls this earlier
		unityMethods.RenderTextureReleaseAll();
	}
	if (needsToMakeContext) {
		if (UnityVersion >= UNITY_VERSION_TATARI_OLD && *unityMethods.gRenderer == 0x11 && *(void **)getField(mgr, screenMgrOffsets.renderSurfaceA) != 0) {
			GfxDevice *gfxDevice = unityMethods.GetGfxDevice();
			void (*setBackBufferColorDepthSurface)(GfxDevice *, RenderSurface *, RenderSurface *) = getVtableEntry(gfxDevice, gfxDevOffsets.setBackBufferColorDepthSurfaceMethod);
			void (*deallocRenderSurface)(GfxDevice *, RenderSurface *) = getVtableEntry(gfxDevice, gfxDevOffsets.deallocRenderSurfaceMethod);
			RenderSurface **rsA = getField(mgr, screenMgrOffsets.renderSurfaceA);
			RenderSurface **rsB = getField(mgr, screenMgrOffsets.renderSurfaceB);
			setBackBufferColorDepthSurface(gfxDevice, *rsA, *rsB);
			deallocRenderSurface(gfxDevice, *rsA);
			deallocRenderSurface(gfxDevice, *rsB);
			*rsA = *rsB = NULL;
			unityMethods.RenderTextureSetActive(NULL, 0, -1, 0x10);
		}
		unityMethods.DestroyMainContextGL();
	}

	StdString prefname = makeStdString("Screenmanager Resolution Width");
	unityMethods.PlayerPrefsSetInt(&prefname, width);
	destroyStdString(prefname);
	prefname = makeStdString("Screenmanager Resolution Height");
	unityMethods.PlayerPrefsSetInt(&prefname, height);
	destroyStdString(prefname);
	prefname = makeStdString("Screenmanager Is Fullscreen mode");
	unityMethods.PlayerPrefsSetInt(&prefname, fullscreen);
	destroyStdString(prefname);
	if (needsToMakeContext) {
		unityMethods.ScreenMgrDidChangeScreenMode(mgr, width, height, fullscreen, context, &modeVec);
	}
	if (UnityVersion < UNITY_VERSION_TATARI_OLD) {
		*unityMethods.gDefaultFBOGL = 0;
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

	}
	else if (tatariGRendererCheck) {
		unityMethods.ScreenMgrRebindDefaultFramebuffer(mgr);
	}
	if (needsToMakeContext && fullscreen && !unityMethods.MustSwitchResolutionForFullscreenMode()) {
		CGDirectDisplayID display = unityMethods.ScreenMgrGetDisplayID(mgr);
		CGRect bounds = CGDisplayBounds(display);
		NSScreen *screen = screenForID(display);
		if (screen) {
			bounds = [screen convertRectToBacking:bounds];
		}
		if (width != bounds.size.width || height != bounds.size.height) {
			if (tatariGRendererCheck) {
				unityMethods.ActivateGraphicsContext(context, false, 0);
			}
			if (UnityVersion < UNITY_VERSION_TATARI_OLD || tatariGRendererCheck) {
				unityMethods.ScreenMgrSetupDownscaledFullscreenFBO(mgr, width, height);
			}
		}
	}
	ret = true;
cleanup:
	if (modeVec.begin != NULL) {
		cppMethods.operatorDelete(modeVec.begin);
	}
	return ret;
};

static void newWindowOrigin(NSWindow *window, CGRect frame, CGRect displayBounds) {
	double x = (displayBounds.size.width - frame.size.width)/2 + displayBounds.origin.x;
	double y = displayBounds.size.height - frame.size.height;
	if (y > 60) {
		y -= 50;
	}
	[window setFrameOrigin:(NSPoint){x, y}];
}

// Recenter window the first time this runs since the previous position was probably based on the wrong size
static bool hasRunModdedCreateWindow = false;

void CreateAndShowWindowReplacement(ScreenManager *mgr, int width, int height, bool fullscreen) {
	ScreenManager *otherMgr = unityMethods.GetScreenManager();
	CGDirectDisplayID display = unityMethods.ScreenMgrGetDisplayID(otherMgr);
	NSScreen *screen = screenForID(display);
	CGRect displayBounds = CGDisplayBounds(display);
	CGRect bounds = (CGRect){CGPointZero, {width, height}};
	if (screen) {
		bounds = [screen convertRectFromBacking:bounds];
	}
	NSWindow *window = (__bridge NSWindow *)*(void **)getField(mgr, screenMgrOffsets.window);
	if (!window) {
		bool resizable = unityMethods.AllowResizableWindow();
		NSWindowStyleMask style = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable;
		if (resizable) {
			style |= NSWindowStyleMaskResizable;
		}
		window = [[NSWindow alloc] initWithContentRect:bounds styleMask:style backing:NSBackingStoreBuffered defer:YES];
		*(void **)getField(mgr, screenMgrOffsets.window) = (void *)CFBridgingRetain(window);
		[window setAcceptsMouseMovedEvents:YES];
		id windowDelegate = [NSClassFromString(@"PlayerWindowDelegate") alloc];
		if (UnityVersion >= UNITY_VERSION_TATARI_OLD) {
			windowDelegate = [windowDelegate init];
			*(void **)getField(mgr, screenMgrOffsets.playerWindowDelegate) = (void *)CFBridgingRetain(windowDelegate);
		}
		[window setDelegate:windowDelegate];
		[window setBackgroundColor:[NSColor blackColor]];
		if (*unityMethods.gPopUpWindow) {
			[window setStyleMask:resizable ? NSWindowStyleMaskResizable : 0];
		}
		PlayerWindowView *view = [[NSClassFromString(@"PlayerWindowView") alloc] initWithFrame:bounds];
		*(void **)getField(mgr, screenMgrOffsets.playerWindowView) = (void *)CFBridgingRetain(view);
		[window setContentView:view];
		[window makeFirstResponder:view];
		newWindowOrigin(window, [window frame], displayBounds);
		[window useOptimizedDrawing:YES];
		NSDictionary<NSString *, id> *dic = [[NSBundle mainBundle] infoDictionary];
		NSString *name = [dic objectForKey:@"CFBundleName"];
		if (!name) {
			name = @"Unity Player";
		}
		[window setTitle:name];
		[window makeKeyAndOrderFront:NULL];
	}
	if (!fullscreen) {
		CGRect contentRect = [window contentRectForFrameRect:[window frame]];
		if (contentRect.size.width != bounds.size.width || contentRect.size.height != bounds.size.height) {
			contentRect.origin.y -= (bounds.size.height - contentRect.size.height);
		}
		CGRect newFrame = [window frameRectForContentRect:(NSRect){contentRect.origin, bounds.size}];
		if (hasRunModdedCreateWindow) {
			[window setFrame:newFrame display:YES animate:YES];
		}
		else {
			[window setFrame:newFrame display:YES];
			newWindowOrigin(window, newFrame, displayBounds);
		}
	}
	hasRunModdedCreateWindow = true;
	int *flag = getField(unityMethods.GetPlayerSettings(), playerSettingsOffsets.collectionBehaviorFlag);
	if (*flag == 2) {
		[window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	}
	else {
		[window setCollectionBehavior:fullscreen ? NSWindowCollectionBehaviorFullScreenPrimary : NSWindowCollectionBehaviorDefault];
		if (fullscreen) {
			SetSystemUIMode(kUIModeAllHidden, 0);
			[NSApp setPresentationOptions:NSApplicationPresentationHideDock | NSApplicationPresentationHideMenuBar | NSApplicationPresentationDisableProcessSwitching];
		}
		else {
			SetSystemUIMode(kUIModeNormal, kUIOptionAutoShowMenuBar);
		}
		if ((([window styleMask] & NSWindowStyleMaskFullScreen) != 0) != fullscreen) {
			[window toggleFullScreen:NULL];
		}
	}
}

void PreBlitReplacement(ScreenManager *mgr) {
	int defaultFBOGL = *unityMethods.gDefaultFBOGL;
	if (defaultFBOGL != 0) {
		GLuint *framebuffer1 = getField(mgr, 0x84);
		GLuint *framebuffer2 = getField(mgr, 0x8c);
		GLint *width = getField(mgr, 0x64);
		GLint *height = getField(mgr, 0x68);
		if (*framebuffer2 != 0) {
			glBindFramebufferEXT(GL_READ_FRAMEBUFFER, *framebuffer2);
			glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER, *framebuffer1);
			glBlitFramebufferEXT(0, 0, *width, *height, 0, 0, *width, *height, 0x4000, GL_NEAREST);
		}
		*unityMethods.gDefaultFBOGL = 0;
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
		ScreenManager *otherMgr = unityMethods.GetScreenManager();
		CGDirectDisplayID display = unityMethods.ScreenMgrGetDisplayID(otherMgr);
		CGRect bounds = CGDisplayBounds(display);
		NSScreen *screen = screenForID(display);
		if (screen) {
			bounds = [screen convertRectToBacking:bounds];
		}
		Matrix4x4f matrix;
		unityMethods.Matrix4x4fSetOrtho(&matrix, 0, 1, 0, 1, -1, 100);
		GfxDevice *gfxDevice = unityMethods.GetRealGfxDevice();
		void (*setProjectionMatrixMethod)(GfxDevice *, Matrix4x4f *) = getVtableEntry(gfxDevice, 0xe0);
		void (*setViewMatrixMethod)(GfxDevice *, Matrix4x4f *) = getVtableEntry(gfxDevice, 0xd8);
		void (*setViewportMethod)(GfxDevice *, RectTInt *) = getVtableEntry(gfxDevice, 0x128);
		setProjectionMatrixMethod(gfxDevice, &matrix);
		setViewMatrixMethod(gfxDevice, unityMethods.identityMatrix);
		RectTInt viewport = {0, 0, bounds.size.width, bounds.size.height};
		setViewportMethod(gfxDevice, &viewport);
		unityMethods.GfxHelperDrawQuad(gfxDevice, NULL, false, 1, 1);
		*unityMethods.gDefaultFBOGL = defaultFBOGL;
	}
}

void WindowDidResizeReplacement(id<NSWindowDelegate> self, SEL sel, NSNotification * _Nonnull notification) {
	NSWindow *window = (NSWindow *)[notification object];
	CGRect rect = [window convertRectToBacking:[window contentRectForFrameRect:[window frame]]];
	if (!([window styleMask] & NSWindowStyleMaskFullScreen)) {
		ScreenManager *mgr = unityMethods.GetScreenManager();
		void (*requestResolutionMethod)(ScreenManager *, int, int, bool, int) = getVtableEntry(mgr, 0x10);
		bool (*isFullscreenMethod)(ScreenManager *) = getVtableEntry(mgr, 0xb8);
		requestResolutionMethod(mgr, rect.size.width, rect.size.height, isFullscreenMethod(mgr), 0);
	}
}
