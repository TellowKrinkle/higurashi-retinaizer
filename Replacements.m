#include "Replacements.h"

#pragma mark - Helpers

static void *getVtableEntry(void *object, size_t offset) {
	void **vtable = *(void **)object;
	return *(vtable + offset / sizeof(void *));
}

static void *getField(void *object, size_t offset) {
	return (char *)object + offset;
}

#pragma mark - Replacement Functions

Pointf GetMouseOriginReplacement(void *mgr) {
	void *windowPtr = *(void **)getField(mgr, 0x70);
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
	void *windowPtr = *(void **)getField(screenMgr, 0x70);
	if (windowPtr) {
		WindowFakeSizer *window = (__bridge WindowFakeSizer*)windowPtr;
		windowRelative = [window convertRectToBacking:(NSRect){windowRelative, NSZeroSize}].origin;
	}
	void *inputManager = unityMethods.GetInputManager();
	Pointf *output = getField(inputManager, 0xb0);
	*output = (Pointf){ windowRelative.x, screenHeight - windowRelative.y };
}
