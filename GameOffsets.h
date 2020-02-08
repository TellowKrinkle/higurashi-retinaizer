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
	int unityVersion;
};

#pragma mark Onikakushi (5.2.2f1)

static const struct AllOffsets OnikakushiOffsets = {
	.screenManager = {
		.getHeightMethod = 0xa8,
		.isFullscreenMethod = 0xb8,
		.releaseModeMethod = 0x100,
		.window = 0x70,
		.playerWindowView = 0x78,
		.playerWindowDelegate = UNUSED_VALUE,
		.renderSurfaceA = UNUSED_VALUE,
		.renderSurfaceB = UNUSED_VALUE,
	},
	.gfxDevice = {
		.finishRenderingMethod = 0x3f0,
		.setBackBufferColorDepthSurfaceMethod = UNUSED_VALUE,
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
	.unityVersion = UNITY_VERSION_ONI
};

#pragma mark Old Tatarigoroshi (5.3.4p1)

static const struct AllOffsets TatarigoroshiOldOffsets = {
	.screenManager = {
		.getHeightMethod = 0xb0,
		.isFullscreenMethod = 0xc0,
		.releaseModeMethod = 0x108,
		.window = 0x70,
		.playerWindowView = 0x78,
		.playerWindowDelegate = 0x80,
		.renderSurfaceA = 0xc8,
		.renderSurfaceB = 0xd0,
	},
	.gfxDevice = {
		.finishRenderingMethod = 0x3e0,
		.setBackBufferColorDepthSurfaceMethod = 0x2f0,
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
	.unityVersion = UNITY_VERSION_TATARI_OLD
};

#endif /* GameOffsets_h */
