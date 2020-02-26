/// Definitions of various sets of offsets used by the games

#ifndef Offsets_h
#define Offsets_h

#include "CppTypes.h"
#include <type_traits>
#include <OpenGL/gl.h>

/// Indicates that the value will not be used by the program for the given game
/// Set to a value that will most likely cause a crash if it does get used (since these are used as offsets, 0 will not cause a direct crash)
static const size_t UNUSED_VALUE = 1UL << 48;

struct AnyMemberOffset {
	size_t offset;
	constexpr inline explicit AnyMemberOffset(size_t _offset): offset(_offset) {}
};
struct AnyVtableOffset {
	size_t offset;
	constexpr inline explicit AnyVtableOffset(size_t _offset): offset(_offset) {}
};

/// An offset from a class to an instance variable in that class
template<typename C, typename M>
struct MemberOffset {
	using Class = C;
	using Member = M;
	size_t offset = UNUSED_VALUE;

	MemberOffset() = default;
	constexpr inline /*implicit*/ MemberOffset(AnyMemberOffset off): offset(off.offset) {}

	Member& apply(Class* c) const {
		return *(Member*)(reinterpret_cast<unsigned char *>(c) + offset);
	}
};

/// An offset from a class's vtable to a particular method in that vtable
template<typename C, typename R, typename... Args>
struct VtableOffset {
	using Result = R;
	using Class = C;
	using Function = Result(*)(Class*, Args...);
	size_t offset = UNUSED_VALUE;

	VtableOffset() = default;
	constexpr inline /*implicit*/ VtableOffset(AnyVtableOffset off): offset(off.offset) {}

	Result operator()(Class* c, Args... args) const {
		return bind(c)(c, args...);
	}

	Function bind(Class* c) const {
		unsigned char *vtable = *reinterpret_cast<unsigned char **>(c);
		return *reinterpret_cast<Function*>(vtable + offset);
	}
};

struct ScreenManagerOffsets {
	VtableOffset<ScreenManager, void, int, int, bool, int> RequestResolution;
	VtableOffset<ScreenManager, int> GetHeight;
	VtableOffset<ScreenManager, bool> IsFullscreen;
	VtableOffset<ScreenManager, int> ReleaseMode;
	MemberOffset<ScreenManager, void*> window;
	MemberOffset<ScreenManager, void*> playerWindowView;
	MemberOffset<ScreenManager, void*> playerWindowDelegate;
	MemberOffset<ScreenManager, bool> isFullscreen;
	MemberOffset<ScreenManager, int> width;
	MemberOffset<ScreenManager, int> height;
	MemberOffset<ScreenManager, GLuint> renderbuffer;
	MemberOffset<ScreenManager, GLuint> framebufferA;
	MemberOffset<ScreenManager, GLuint> framebufferB;
	MemberOffset<ScreenManager, RenderSurface*> renderColorSurface;
	MemberOffset<ScreenManager, RenderSurface*> renderDepthSurface;
	MemberOffset<ScreenManager, RenderSurface*> backBufferColorSurface;
	MemberOffset<ScreenManager, RenderSurface*> backBufferDepthSurface;
	MemberOffset<ScreenManager, GfxRenderTargetSetup*> renderTargetSetup;
};

struct GfxDeviceOffsets {
	VtableOffset<GfxDevice, void> FinishRendering;
	VtableOffset<GfxDevice, void, RenderSurface*, RenderSurface*> SetBackBufferColorDepthSurface;
	VtableOffset<GfxDevice, void, Matrix4x4f*> SetProjectionMatrix;
	VtableOffset<GfxDevice, void, Matrix4x4f*> SetViewMatrix;
	VtableOffset<GfxDevice, void, RectT<int>*> SetViewport;
	VtableOffset<GfxDevice, void, RenderSurface*> DeallocRenderSurface;
	VtableOffset<GfxDevice, void> AcquireThreadOwnership;
	VtableOffset<GfxDevice, void> ReleaseThreadOwnership;
	MemberOffset<GfxDevice, int> renderer;
};

struct GfxFramebufferGLESOffsets {
	MemberOffset<GfxFramebufferGLES, GLuint> framebufferOld;
	MemberOffset<GfxFramebufferGLES, GLHandle> framebufferNew;
};

struct PlayerSettingsOffsets {
	MemberOffset<PlayerSettings, int> macFullscreenMode;
};

struct QualitySettingsOffsets {
	MemberOffset<QualitySettings, QualitySetting*> settingsVector;
	MemberOffset<QualitySettings, int> currentQuality;
};

struct QualitySettingOffsets {
	MemberOffset<QualitySetting, int> vSyncCount;
	size_t size = UNUSED_VALUE;
};

struct InputManagerOffsets {
	MemberOffset<InputManager, Pointf> mousePosition;
};

struct MetalSurfaceOffsets {
	MemberOffset<MetalSurfaceHelper, CGSize> size;
};

extern struct AllOffsets {
	struct ScreenManagerOffsets screenManager;
	struct GfxDeviceOffsets gfxDevice;
	struct GfxFramebufferGLESOffsets gfxFramebufferGLES;
	struct PlayerSettingsOffsets playerSettings;
	struct QualitySettingsOffsets qualitySettings;
	struct QualitySettingOffsets qualitySetting;
	struct InputManagerOffsets inputManager;
	struct MetalSurfaceOffsets metalSurface;
	int unityVersion = 0;
} _allOffsets;

static struct ScreenManagerOffsets& screenMgrOffsets = _allOffsets.screenManager;
static struct GfxDeviceOffsets& gfxDevOffsets = _allOffsets.gfxDevice;
static struct GfxFramebufferGLESOffsets& gfxFramebufferGLESOffsets = _allOffsets.gfxFramebufferGLES;
static struct PlayerSettingsOffsets& playerSettingsOffsets = _allOffsets.playerSettings;
static struct QualitySettingsOffsets& qualitySettingsOffsets = _allOffsets.qualitySettings;
static struct QualitySettingOffsets& qualitySettingOffsets = _allOffsets.qualitySetting;
static struct InputManagerOffsets& inputMgrOffsets = _allOffsets.inputManager;
static struct MetalSurfaceOffsets& metalSurfaceOffsets = _allOffsets.metalSurface;

/// 8-digit hex number where each pair of digits represents one part of the Unity version (so 5.2.2f1 would be 0x05020201)
static const int UNITY_VERSION_ONI = 0x05020201;
static const int UNITY_VERSION_TATARI_OLD = 0x05030401;
static const int UNITY_VERSION_TATARI_NEW = 0x05040001;
static const int UNITY_VERSION_HIMA = 0x05040101;
static const int UNITY_VERSION_ME = 0x05050301;
static const int UNITY_VERSION_TSUMI = 0x05050303;
static const int UNITY_VERSION_MINA = 0x05060701;
static int& UnityVersion = _allOffsets.unityVersion;

#endif /* Offsets_h */
