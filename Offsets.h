/// Definitions of various sets of offsets used by the games

#ifndef Offsets_h
#define Offsets_h

// size is struct size, *Method are vtable offsets, others are struct offsets

extern struct ScreenManagerOffsets {
	size_t requestResolutionMethod;
	size_t getHeightMethod;
	size_t isFullscreenMethod;
	size_t releaseModeMethod;
	size_t window;
	size_t playerWindowView;
	size_t playerWindowDelegate;
	size_t isFullscreen;
	size_t width;
	size_t height;
	size_t framebufferA;
	size_t framebufferB;
	size_t renderSurfaceA;
	size_t renderSurfaceB;
} screenMgrOffsets;

extern struct GfxDeviceOffsets {
	size_t finishRenderingMethod;
	size_t setBackBufferColorDepthSurfaceMethod;
	size_t setProjectionMatrixMethod;
	size_t setViewMatrixMethod;
	size_t setViewportMethod;
	size_t deallocRenderSurfaceMethod;
} gfxDevOffsets;

extern struct PlayerSettingsOffsets {
	size_t collectionBehaviorFlag;
} playerSettingsOffsets;

extern struct QualitySettingsOffsets {
	size_t settingsVector;
	size_t currentQuality;
} qualitySettingsOffsets;

extern struct QualitySettingOffsets {
	size_t vSyncCount;
	size_t size;
} qualitySettingOffsets;

extern struct InputManagerOffsets {
	size_t mousePosition;
} inputMgrOffsets;

#endif /* Offsets_h */
