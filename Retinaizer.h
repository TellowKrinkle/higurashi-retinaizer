#ifndef Retinaizer_h
#define Retinaizer_h

#import <Cocoa/Cocoa.h>

@interface WindowFakeSizer : NSWindow

- (NSRect)actualContentRectForFrameRect:(NSRect)frameRect;

@end

typedef struct Pointf {
	float x;
	float y;
} Pointf;

extern struct UnityMethods {
	void *(*GetScreenManager)(void);
	void *(*GetInputManager)(void);
	CGDirectDisplayID (*ScreenMgrGetDisplayID)(void *);
	Pointf (*ScreenMgrGetMouseScale)(void *);
} unityMethods;

#endif /* Retinaizer_h */
