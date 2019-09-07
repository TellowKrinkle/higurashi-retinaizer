#include "Replacements.h"
#include <OpenGL/glext.h>
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

enum ScreenMgrOffsets {
	ScreenMgrWindowOffset = 0x70,
	PlayerWindowViewOffset = 0x78,
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
			CreateAndShowWindowReplacement(mgr, width, height, fullscreen);
			PlayerWindowView *view = (__bridge PlayerWindowView *)*(void **)getField(mgr, PlayerWindowViewOffset);
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

void CreateAndShowWindowReplacement(void *mgr, int width, int height, bool fullscreen) {
	void *otherMgr = unityMethods.GetScreenManager();
	CGDirectDisplayID display = unityMethods.ScreenMgrGetDisplayID(otherMgr);
	NSScreen *screen = screenForID(display);
	CGRect displayBounds = CGDisplayBounds(display);
	CGRect bounds = (CGRect){CGPointZero, {width, height}};
	if (screen) {
		bounds = [screen convertRectFromBacking:bounds];
	}
	WindowFakeSizer *window = (__bridge WindowFakeSizer *)*(void **)getField(mgr, ScreenMgrWindowOffset);
	if (!window) {
		bool resizable = unityMethods.AllowResizableWindow();
		NSWindowStyleMask style = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable;
		if (resizable) {
			style |= NSWindowStyleMaskResizable;
		}
		window = [[WindowFakeSizer alloc] initWithContentRect:bounds styleMask:style backing:NSBackingStoreBuffered defer:YES];
		*(void **)getField(mgr, ScreenMgrWindowOffset) = (void *)CFBridgingRetain(window);
		[window setAcceptsMouseMovedEvents:YES];
		id windowDelegate = [NSClassFromString(@"PlayerWindowDelegate") alloc];
		[window setDelegate:windowDelegate];
		[window setBackgroundColor:[NSColor blackColor]];
		if (*unityMethods.gPopUpWindow) {
			[window setStyleMask:resizable ? NSWindowStyleMaskResizable : 0];
		}
		PlayerWindowView *view = [[NSClassFromString(@"PlayerWindowView") alloc] initWithFrame:bounds];
		*(void **)getField(mgr, PlayerWindowViewOffset) = (void *)CFBridgingRetain(view);
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
		CGRect contentRect = [window actualContentRectForFrameRect:[window frame]];
		if (contentRect.size.width != bounds.size.width || contentRect.size.height != bounds.size.height) {
			contentRect.origin.y -= (bounds.size.height - contentRect.size.height);
		}
		CGRect newFrame = [window frameRectForContentRect:(NSRect){contentRect.origin, bounds.size}];
		if (hasRunModdedCreateWindow) {
			[window setFrame:newFrame display:YES animate:YES];
		}
		else {
			hasRunModdedCreateWindow = true;
			[window setFrame:newFrame display:YES];
			newWindowOrigin(window, newFrame, displayBounds);
		}
	}
	int *flag = getField(unityMethods.GetPlayerSettings(), 0xd4);
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
