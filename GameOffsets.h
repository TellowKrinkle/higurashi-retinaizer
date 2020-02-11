/// Static offset instances representing each Unity version, for use by the code that selects the correct set to put into the global offset instances

#ifndef GameOffsets_h
#define GameOffsets_h

#include "Offsets.h"

inline AnyMemberOffset operator"" _i(unsigned long long n) { return AnyMemberOffset(n); }
inline AnyVtableOffset operator"" _v(unsigned long long n) { return AnyVtableOffset(n); }

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
		.RequestResolution = 0x10_v,
		.GetHeight = 0xa8_v,
		.IsFullscreen = 0xb8_v,
		.ReleaseMode = 0x100_v,
		.window = 0x70_i,
		.playerWindowView = 0x78_i,
		.isFullscreen = 0x23_i,
		.width = 0x64_i,
		.height = 0x68_i,
		.framebufferA = 0x84_i,
		.framebufferB = 0x8c_i,
	},
	.gfxDevice = {
		.FinishRendering = 0x3f0_v,
		.SetProjectionMatrix = 0xe0_v,
		.SetViewMatrix = 0xd8_v,
		.SetViewport = 0x128_v,
	},
	.playerSettings = {
		.collectionBehaviorFlag = 0xd4_i,
	},
	.qualitySettings = {
		.settingsVector = 0x28_i,
		.currentQuality = 0x44_i,
	},
	.qualitySetting = {
		.vSyncCount = 0x44_i,
		.size = 0x60,
	},
	.inputManager = {
		.mousePosition = 0xb0_i,
	},
	.unityVersion = UNITY_VERSION_ONI
};

#pragma mark Old Tatarigoroshi (5.3.4p1)

static const struct AllOffsets TatarigoroshiOldOffsets = {
	.screenManager = {
		.RequestResolution = 0x10_v,
		.GetHeight = 0xb0_v,
		.IsFullscreen = 0xc0_v,
		.ReleaseMode = 0x108_v,
		.window = 0x70_i,
		.playerWindowView = 0x78_i,
		.playerWindowDelegate = 0x80_i,
		.isFullscreen = 0x23_i,
		.width = 0x64_i,
		.height = 0x68_i,
		.framebufferA = 0x148_i,
		.framebufferB = 0x154_i,
		.renderSurfaceA = 0xc8_i,
		.renderSurfaceB = 0xd0_i,
	},
	.gfxDevice = {
		.FinishRendering = 0x3e0_v,
		.SetBackBufferColorDepthSurface = 0x2f0_v,
		.SetProjectionMatrix = 0xe0_v,
		.SetViewMatrix = 0xd8_v,
		.SetViewport = 0x128_v,
		.DeallocRenderSurface = 0x308_v,
	},
	.playerSettings = {
		.collectionBehaviorFlag = 0xd8_i,
	},
	.qualitySettings = {
		.settingsVector = 0x28_i,
		.currentQuality = 0x44_i,
	},
	.qualitySetting = {
		.vSyncCount = 0x44_i,
		.size = 0x68,
	},
	.inputManager = {
		.mousePosition = 0xb0_i,
	},
	.unityVersion = UNITY_VERSION_TATARI_OLD
};

#endif /* GameOffsets_h */
