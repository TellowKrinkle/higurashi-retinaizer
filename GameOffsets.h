/// Static offset instances representing each Unity version, for use by the code that selects the correct set to put into the global offset instances

#ifndef GameOffsets_h
#define GameOffsets_h

#include "Offsets.h"

inline AnyMemberOffset operator"" _i(unsigned long long n) { return AnyMemberOffset(n); }
inline AnyVtableOffset operator"" _v(unsigned long long n) { return AnyVtableOffset(n); }

#pragma mark Onikakushi, Watanagashi (5.2.2f1)

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
		.macFullscreenMode = 0xd4_i,
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
		.macFullscreenMode = 0xd8_i,
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

#pragma mark New Tatarigoroshi (5.4.0f1)

static const struct AllOffsets TatarigoroshiNewOffsets = {
	.screenManager = {
		.RequestResolution = 0x10_v,
		.GetHeight = 0xb0_v,
		.IsFullscreen = 0xc8_v,
		.ReleaseMode = 0x110_v,
		.window = 0x70_i,
		.playerWindowView = 0x78_i,
		.playerWindowDelegate = 0x80_i,
		.isFullscreen = 0x24_i,
		.width = 0x68_i,
		.height = 0x6c_i,
		.framebufferA = 0x150_i,
		.framebufferB = 0x15c_i,
		.renderSurfaceA = 0xd0_i,
		.renderSurfaceB = 0xd8_i,
	},
	.gfxDevice = {
		.FinishRendering = 0x410_v,
		.SetBackBufferColorDepthSurface = 0x2f0_v,
		.SetProjectionMatrix = 0xe8_v,
		.SetViewMatrix = 0xe0_v,
		.SetViewport = 0x130_v,
		.DeallocRenderSurface = 0x308_v,
	},
	.playerSettings = {
		.macFullscreenMode = 0x10c_i,
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
	.unityVersion = UNITY_VERSION_TATARI_NEW
};

#pragma mark Himatsubushi (5.4.1f1)

// 5.4.1f1 uses the same offsets as 5.4.0f1

#pragma mark Meakashi (5.5.3p1)

static const struct AllOffsets MeakashiOffsets = {
	.screenManager = {
		.RequestResolution = 0x10_v,
		.GetHeight = 0xb0_v,
		.IsFullscreen = 0xc8_v,
		.ReleaseMode = 0x110_v,
		.window = 0x70_i,
		.playerWindowView = 0x78_i,
		.playerWindowDelegate = 0x80_i,
		.isFullscreen = 0x24_i,
		.width = 0x68_i,
		.height = 0x6c_i,
		.framebufferA = {},
		.framebufferB = {},
		.renderSurfaceA = 0xd0_i,
		.renderSurfaceB = 0xd8_i,
	},
	.gfxDevice = {
		.FinishRendering = 0x420_v,
		.SetBackBufferColorDepthSurface = 0x2e8_v,
		.SetProjectionMatrix = 0xe8_v,
		.SetViewMatrix = 0xe0_v,
		.SetViewport = 0x130_v,
		.DeallocRenderSurface = 0x300_v,
	},
	.playerSettings = {
		.macFullscreenMode = 0x198_i,
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
	.unityVersion = UNITY_VERSION_ME
};

#pragma mark Tsumihoroboshi (5.5.3p3)

// 5.5.3p3 uses the same offsets as 5.5.3p1

#pragma mark Minagoroshi (5.6.7f1)

static const struct AllOffsets MinagoroshiOffsets = {
	.screenManager = {
		.RequestResolution = 0x10_v,
		.GetHeight = 0xb0_v,
		.IsFullscreen = 0xc8_v,
		.ReleaseMode = 0x110_v,
		.window = 0x70_i,
		.playerWindowView = 0x78_i,
		.playerWindowDelegate = 0x80_i,
		.isFullscreen = 0x24_i,
		.width = 0x68_i,
		.height = 0x6c_i,
		.framebufferA = {},
		.framebufferB = {},
		.renderSurfaceA = 0x98_i,
		.renderSurfaceB = 0xa0_i,
	},
	.gfxDevice = {
		.FinishRendering = 0x440_v,
		.SetBackBufferColorDepthSurface = 0x308_v,
		.SetProjectionMatrix = 0xf8_v,
		.SetViewMatrix = 0xf0_v,
		.SetViewport = 0x140_v,
		.DeallocRenderSurface = 0x320_v,
	},
	.playerSettings = {
		.macFullscreenMode = 0x264_i,
	},
	.qualitySettings = {
		.settingsVector = 0x30_i,
		.currentQuality = 0x4c_i,
	},
	.qualitySetting = {
		.vSyncCount = 0x64_i,
		.size = 0x88,
	},
	.inputManager = {
		.mousePosition = 0xb8_i,
	},
	.metalSurface = {
		.size = 0x10_i
	},
	.unityVersion = UNITY_VERSION_MINA
};

#endif /* GameOffsets_h */
