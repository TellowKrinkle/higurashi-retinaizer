/// Static offset instances representing each Unity version, for use by the code that selects the correct set to put into the global offset instances

#ifndef GameOffsets_h
#define GameOffsets_h

#include "Offsets.h"

/// Indicates that the value will not be used by the program for the given game
/// Set to a value that will most likely cause a crash if it does get used (since these are used as offsets, 0 will not cause a direct crash)
static const size_t UNUSED_VALUE = 1UL << 48;

struct AllOffsets {
	struct ScreenManagerOffsets screenManager;
	struct GfxDeviceOffsets gfxDevice;
	struct PlayerSettingsOffsets playerSettings;
	struct QualitySettingsOffsets qualitySettings;
	struct QualitySettingOffsets qualitySetting;
	struct InputManagerOffsets inputManager;
	int unityVersion;
};

#pragma mark Onikakushi (5.2.2f1)

static const struct AllOffsets OnikakushiOffsets = {
	.screenManager = {
		.requestResolutionMethod = 0x10,
		.getHeightMethod = 0xa8,
		.isFullscreenMethod = 0xb8,
		.releaseModeMethod = 0x100,
		.window = 0x70,
		.playerWindowView = 0x78,
		.playerWindowDelegate = UNUSED_VALUE,
		.isFullscreen = 0x23,
		.width = 0x64,
		.height = 0x68,
		.framebufferA = 0x84,
		.framebufferB = 0x8c,
		.renderSurfaceA = UNUSED_VALUE,
		.renderSurfaceB = UNUSED_VALUE,
	},
	.gfxDevice = {
		.finishRenderingMethod = 0x3f0,
		.setBackBufferColorDepthSurfaceMethod = UNUSED_VALUE,
		.setProjectionMatrixMethod = 0xe0,
		.setViewMatrixMethod = 0xd8,
		.setViewportMethod = 0x128,
		.deallocRenderSurfaceMethod = UNUSED_VALUE,
	},
	.playerSettings = {
		.collectionBehaviorFlag = 0xd4,
	},
	.qualitySettings = {
		.settingsVector = 0x28,
		.currentQuality = 0x44,
	},
	.qualitySetting = {
		.vSyncCount = 0x44,
		.size = 0x60,
	},
	.inputManager = {
		.mousePosition = 0xb0,
	},
	.unityVersion = UNITY_VERSION_ONI
};

#pragma mark Old Tatarigoroshi (5.3.4p1)

static const struct AllOffsets TatarigoroshiOldOffsets = {
	.screenManager = {
		.requestResolutionMethod = 0x10,
		.getHeightMethod = 0xb0,
		.isFullscreenMethod = 0xc0,
		.releaseModeMethod = 0x108,
		.window = 0x70,
		.playerWindowView = 0x78,
		.playerWindowDelegate = 0x80,
		.isFullscreen = 0x23,
		.width = 0x64,
		.height = 0x68,
		.framebufferA = 0x148,
		.framebufferB = 0x154,
		.renderSurfaceA = 0xc8,
		.renderSurfaceB = 0xd0,
	},
	.gfxDevice = {
		.finishRenderingMethod = 0x3e0,
		.setBackBufferColorDepthSurfaceMethod = 0x2f0,
		.setProjectionMatrixMethod = 0xe0,
		.setViewMatrixMethod = 0xd8,
		.setViewportMethod = 0x128,
		.deallocRenderSurfaceMethod = 0x308,
	},
	.playerSettings = {
		.collectionBehaviorFlag = 0xd8,
	},
	.qualitySettings = {
		.settingsVector = 0x28,
		.currentQuality = 0x44,
	},
	.qualitySetting = {
		.vSyncCount = 0x44,
		.size = 0x68,
	},
	.inputManager = {
		.mousePosition = 0xb0,
	},
	.unityVersion = UNITY_VERSION_TATARI_OLD
};

#endif /* GameOffsets_h */
