#include "Replacements.h"
#include "Offsets.h"
#include "Finally.h"
#include <OpenGL/glext.h>
#include <OpenGL/gl.h>
#include <Carbon/Carbon.h>

#pragma mark - Helpers

template <typename T>
T* arrayOffset(T* array, size_t itemSize, int index) {
	return reinterpret_cast<T*>(reinterpret_cast<unsigned char *>(array) + itemSize * index);
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
	NSWindow *window = (__bridge NSWindow*)screenMgrOffsets.window.apply(mgr);
	if (window) {
		CGRect contentRect = [window contentRectForFrameRect:[window frame]];
		NSScreen *screen = [[NSScreen screens] objectAtIndex:0];
		double height = [screen frame].size.height;
		Pointf ret = {(float)contentRect.origin.x, (float)(height - contentRect.origin.y - contentRect.size.height)};
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
	CGPoint origin;
	if (screenMgrOffsets.isFullscreenMethod(screenMgr)) {
		CGDirectDisplayID displayID = unityMethods.ScreenMgrGetDisplayID(screenMgr);
		origin = CGDisplayBounds(displayID).origin;
		// Original binary gets mouse scale and multiplies by it.  In macOS, mouse coordinates are in display points, as are window positions, so multiplying by mouse scale would break things rather than fixing things.
	}
	else {
		Pointf pt = GetMouseOriginReplacement(screenMgr);
		origin = (CGPoint){ pt.x, pt.y };
	}
	// Note: the height from ScreenManager is in retina coordinates
	int windowHeight = screenMgrOffsets.getHeightMethod(screenMgr);
	NSPoint windowRelative = { point.x - origin.x, point.y - origin.y };
	NSWindow *window = (__bridge NSWindow *)screenMgrOffsets.window.apply(screenMgr);
	if (window) {
		windowRelative = [window convertRectToBacking:(NSRect){windowRelative, NSZeroSize}].origin;
	}
	InputManager *inputManager = unityMethods.GetInputManager();
	Pointf *output = &inputMgrOffsets.mousePosition.apply(inputManager);
	*output = { (float)windowRelative.x, (float)(windowHeight - windowRelative.y) };
}

Pointf GetMouseScaleReplacement(ScreenManager *mgr) {
	bool mustSwitch = unityMethods.MustSwitchResolutionForFullscreenMode();
	NSWindow *window = (__bridge NSWindow *)screenMgrOffsets.window.apply(mgr);
	if (!mustSwitch && window) {
		// Added convertRectToBacking: for retina support
		CGRect frame = [window convertRectToBacking:[window contentRectForFrameRect:[window frame]]];
		int width = screenMgrOffsets.width.apply(mgr);
		int height = screenMgrOffsets.height.apply(mgr);
		return { (float)(width / frame.size.width), (float)(height / frame.size.height) };
	}
	return (Pointf){1, 1};
}

Pointf *TatariGetMouseScaleReplacement(Pointf *output, ScreenManager *mgr) {
	*output = GetMouseScaleReplacement(mgr);
	return output;
}

bool SetResImmediateReplacement(ScreenManager *mgr, int width, int height, bool fullscreen, int refreshRate) {
	GfxDevice *gfxDevice = unityMethods.GetGfxDevice();
	gfxDevOffsets.finishRenderingMethod(gfxDevice);
	bool isBatchMode = unityMethods.IsBatchMode();
	if (isBatchMode) { return false; }
	NSWindow *window = (__bridge NSWindow *)screenMgrOffsets.window.apply(mgr);
	if ((([window styleMask] & NSWindowStyleMaskFullScreen) != 0) != fullscreen) {
		[window toggleFullScreen:NULL];
		// The original binary doesn't do this, but when defullscreening with the green window button, this method is called with fullscreen still true.  This causes toggleFullScreen to do nothing (because it's already happening) and messes up later code which assumes the fullscreen variable corresponds to the state of the window.
		fullscreen = [window styleMask] & NSWindowStyleMaskFullScreen;
	}
	IntVector modeVec = {0};
	auto modeVecCleanup = finally([&modeVec]() {
		if (modeVec.begin != NULL) {
			cppMethods.operatorDelete(modeVec.begin);
		}
	});
	unityMethods.ScreenMgrWillChangeMode(mgr, &modeVec);
	screenMgrOffsets.releaseModeMethod(mgr);
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
		if (!context) { return false; }
		QualitySettings *qualitySettings = unityMethods.GetQualitySettings();
		int currentQualityIdx = qualitySettingsOffsets.currentQuality.apply(qualitySettings);
		QualitySetting *settingsVector = qualitySettingsOffsets.settingsVector.apply(qualitySettings);
		int vSyncCount = qualitySettingOffsets.vSyncCount.apply(arrayOffset(settingsVector, qualitySettingOffsets.size, currentQualityIdx));
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
		@autoreleasepool {
			// CreateAndShowWindow calls [NSWindow setFrame:display:animate:] which will autorelease the NSOpenGLContext in the PlayerWindowView if animate is `NO`.  The PlayerWindowView *really* wants its old NSOpenGLContext to be dealloc'd before it assigns the new NSOpenGLContext (otherwise blackscreen when the dealloc happens later).  Unity never encountered this because it always called with `animate:YES`.
			CreateAndShowWindowReplacement(mgr, width, height, fullscreen);
		}
		PlayerWindowView *view = (__bridge PlayerWindowView *)screenMgrOffsets.playerWindowView.apply(mgr);
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
	screenMgrOffsets.isFullscreen.apply(mgr) = fullscreen;
	if (UnityVersion < UNITY_VERSION_TATARI_OLD) {
		// Tatari+ calls this earlier
		unityMethods.RenderTextureReleaseAll();
	}
	if (needsToMakeContext) {
		if (UnityVersion >= UNITY_VERSION_TATARI_OLD && *unityMethods.gRenderer == 0x11 && screenMgrOffsets.renderSurfaceA.apply(mgr) != nullptr) {
			GfxDevice *gfxDevice = unityMethods.GetGfxDevice();
			RenderSurface **rsA = &screenMgrOffsets.renderSurfaceA.apply(mgr);
			RenderSurface **rsB = &screenMgrOffsets.renderSurfaceB.apply(mgr);
			gfxDevOffsets.setBackBufferColorDepthSurfaceMethod(gfxDevice, *rsA, *rsB);
			gfxDevOffsets.deallocRenderSurfaceMethod(gfxDevice, *rsA);
			gfxDevOffsets.deallocRenderSurfaceMethod(gfxDevice, *rsB);
			*rsA = *rsB = nullptr;
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
	return true;
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
	CGRect bounds = {CGPointZero, {(CGFloat)width, (CGFloat)height}};
	if (screen) {
		bounds = [screen convertRectFromBacking:bounds];
	}
	NSWindow *window = (__bridge NSWindow *)screenMgrOffsets.window.apply(mgr);
	if (!window) {
		bool resizable = unityMethods.AllowResizableWindow();
		NSWindowStyleMask style = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable;
		if (resizable) {
			style |= NSWindowStyleMaskResizable;
		}
		window = [[NSWindow alloc] initWithContentRect:bounds styleMask:style backing:NSBackingStoreBuffered defer:YES];
		screenMgrOffsets.window.apply(mgr) = (void *)CFBridgingRetain(window);
		[window setAcceptsMouseMovedEvents:YES];
		id windowDelegate = [NSClassFromString(@"PlayerWindowDelegate") alloc];
		if (UnityVersion >= UNITY_VERSION_TATARI_OLD) {
			windowDelegate = [windowDelegate init];
			screenMgrOffsets.playerWindowDelegate.apply(mgr) = (void *)CFBridgingRetain(windowDelegate);
		}
		[window setDelegate:windowDelegate];
		[window setBackgroundColor:[NSColor blackColor]];
		if (*unityMethods.gPopUpWindow) {
			[window setStyleMask:resizable ? NSWindowStyleMaskResizable : 0];
		}
		PlayerWindowView *view = [[NSClassFromString(@"PlayerWindowView") alloc] initWithFrame:bounds];
		screenMgrOffsets.playerWindowView.apply(mgr) = (void *)CFBridgingRetain(view);
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

	int flag = playerSettingsOffsets.collectionBehaviorFlag.apply(unityMethods.GetPlayerSettings());
	if (flag == 2) {
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
		GLuint framebuffer1 = screenMgrOffsets.framebufferA.apply(mgr);
		GLuint framebuffer2 = screenMgrOffsets.framebufferB.apply(mgr);
		GLint width = screenMgrOffsets.width.apply(mgr);
		GLint height = screenMgrOffsets.height.apply(mgr);
		if (framebuffer2 != 0) {
			glBindFramebufferEXT(GL_READ_FRAMEBUFFER, framebuffer2);
			glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER, framebuffer1);
			glBlitFramebufferEXT(0, 0, width, height, 0, 0, width, height, 0x4000, GL_NEAREST);
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
		gfxDevOffsets.setProjectionMatrixMethod(gfxDevice, &matrix);
		gfxDevOffsets.setViewMatrixMethod(gfxDevice, unityMethods.identityMatrix);
		RectTInt viewport = {0, 0, (int)bounds.size.width, (int)bounds.size.height};
		gfxDevOffsets.setViewportMethod(gfxDevice, &viewport);
		unityMethods.GfxHelperDrawQuad(gfxDevice, NULL, false, 1, 1);
		*unityMethods.gDefaultFBOGL = defaultFBOGL;
	}
}

void WindowDidResizeReplacement(id<NSWindowDelegate> self, SEL sel, NSNotification * _Nonnull notification) {
	NSWindow *window = (NSWindow *)[notification object];
	CGRect rect = [window convertRectToBacking:[window contentRectForFrameRect:[window frame]]];
	if (!([window styleMask] & NSWindowStyleMaskFullScreen)) {
		ScreenManager *mgr = unityMethods.GetScreenManager();
		bool isFullscreen = screenMgrOffsets.isFullscreenMethod(mgr);
		screenMgrOffsets.requestResolutionMethod(mgr, rect.size.width, rect.size.height, isFullscreen, 0);
	}
}