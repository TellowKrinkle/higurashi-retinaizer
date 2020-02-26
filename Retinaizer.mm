#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <mach-o/fat.h>
#import <Cocoa/Cocoa.h>
#include "Retinaizer.h"
#include "Replacements.h"
#include "GameOffsets.h"
#include "Offsets.h"
#include <dlfcn.h>
#include <type_traits>

#pragma mark - Structs

static struct MethodsToReplace {
	void (*InputReadMousePosition)(void);
	Pointf (*ScreenMgrGetMouseOrigin)(ScreenManager *);
	Pointf (*ScreenMgrGetMouseScale)(ScreenManager *);
	bool (*ScreenMgrSetResImmediate)(ScreenManager *, int, int, bool, int);
	void (*ScreenMgrCreateAndShowWindow)(ScreenManager *, int, int, bool);
	void (*ScreenMgrPreBlit)(ScreenManager *);
} methodsToReplace = {0};

static struct ReplacementMethods {
	void (*InputReadMousePosition)(void);
	Pointf (*ScreenMgrGetMouseOrigin)(ScreenManager *);
	Pointf (*ScreenMgrGetMouseScale)(ScreenManager *);
	bool (*ScreenMgrSetResImmediate)(ScreenManager *, int, int, bool, int);
	void (*ScreenMgrCreateAndShowWindow)(ScreenManager *, int, int, bool);
	void (*ScreenMgrPreBlit)(ScreenManager *);
} replacementMethods = {
	.InputReadMousePosition = ReadMousePosReplacement,
	.ScreenMgrGetMouseOrigin = GetMouseOriginReplacement,
	.ScreenMgrGetMouseScale = GetMouseScaleReplacement,
	.ScreenMgrSetResImmediate = SetResImmediateReplacement,
	.ScreenMgrCreateAndShowWindow = CreateAndShowWindowReplacement,
	.ScreenMgrPreBlit = PreBlitReplacement,
};

struct UnityMethods unityMethods = {0};
struct CPPMethods cppMethods = {0};

struct AllOffsets _allOffsets;

static struct WantedFunction {
	const char *name;
	void *target;
} wantedFunctions[] = {
	{"__Z22InputReadMousePositionv", &methodsToReplace.InputReadMousePosition},
	{"__ZN26ScreenManagerOSXStandalone14GetMouseOriginEv", &methodsToReplace.ScreenMgrGetMouseOrigin},
	{"__ZN26ScreenManagerOSXStandalone22SetResolutionImmediateEiibi", &methodsToReplace.ScreenMgrSetResImmediate},
	{"__ZN26ScreenManagerOSXStandalone19CreateAndShowWindowEiib", &methodsToReplace.ScreenMgrCreateAndShowWindow},
	{"__ZN26ScreenManagerOSXStandalone7PreBlitEv", &methodsToReplace.ScreenMgrPreBlit},

	{"__Z16GetScreenManagerv", &unityMethods.GetScreenManager},
	{"__Z12GetGfxDevicev", &unityMethods.GetGfxDevice},
	{"__Z16GetRealGfxDevicev", &unityMethods.GetRealGfxDevice},
	{"__Z15GetInputManagerv", &unityMethods.GetInputManager},
	{"__Z18GetQualitySettingsv", &unityMethods.GetQualitySettings},
	{"__Z17GetPlayerSettingsv", &unityMethods.GetPlayerSettings},
	{"__Z22GetCurrentMetalSurfacev", &unityMethods.GetCurrentMetalSurface},
	{"__Z23GetRequestedDeviceLevelv", &unityMethods.GetRequestedDeviceLevel},
	{"__ZN4gles18GetFramebufferGLESEv", &unityMethods.GetFramebufferGLES},
	{"__Z11IsBatchmodev", &unityMethods.IsBatchMode},
	{"__Z37MustSwitchResolutionForFullscreenModev", &unityMethods.MustSwitchResolutionForFullscreenMode},
	{"__Z21AllowResizeableWindowv", &unityMethods.AllowResizableWindow},
	{"__Z26IsRealGfxDeviceThreadOwnerv", &unityMethods.IsRealGfxDeviceThreadOwner},
	{"__Z39Application_Get_Custom_PropUnityVersionv", &unityMethods.ApplicationGetCustomPropUnityVersion},

	{"__Z12SetSyncToVBL12ObjectHandleI19GraphicsContext_TagPvEi", &unityMethods.SetSyncToVBL},
	{"__ZN11PlayerPrefs6SetIntERKSsi", &unityMethods.PlayerPrefsSetInt},
	{"__ZN11PlayerPrefs6SetIntERKN4core12basic_stringIcNS0_20StringStorageDefaultIcEEEEi", &unityMethods.PlayerPrefsSetInt},
	{"__Z14MakeNewContext16GfxDeviceLevelGLiiibb17DepthBufferFormatPib", &unityMethods.MakeNewContext},
	{"__Z14MakeNewContext16GfxDeviceLevelGLiiib17DepthBufferFormatPi", &unityMethods.MakeNewContext},
	{"__Z14MakeNewContext16GfxDeviceLevelGLiiib17DepthBufferFormat", &unityMethods.MakeNewContext},
	{"__ZN13RenderTexture9SetActiveEPS_i11CubemapFacej", &unityMethods.RenderTextureSetActive},
	{"__ZN13RenderTexture9SetActiveEPS_i11CubemapFaceij", &unityMethods.RenderTextureSetActive},
	{"__ZN13RenderTexture9SetActiveEPS_i11CubemapFaceiNS_14SetActiveFlagsE", &unityMethods.RenderTextureSetActive},
	{"__ZN13RenderTexture10ReleaseAllEv", &unityMethods.RenderTextureReleaseAll},
	{"__Z20DestroyMainContextGLv", &unityMethods.DestroyMainContextGL},
	{"__Z15RecreateSurfacev", &unityMethods.RecreateSurface},
	{"__ZN14GraphicsHelper8DrawQuadER9GfxDevicePK14ChannelAssignsbff", &unityMethods.GfxHelperDrawQuad},
	{"__ZN14GraphicsHelper8DrawQuadER9GfxDevicePK14ChannelAssignsbRK5RectTIfE", &unityMethods.GfxHelperDrawQuad},
	{"__Z23ActivateGraphicsContext12ObjectHandleI19GraphicsContext_TagPvEbi", &unityMethods.ActivateGraphicsContext},

	{"__ZNK16ScreenManagerOSX12GetDisplayIDEv", &unityMethods.ScreenMgrGetDisplayID},
	{"__ZN26ScreenManagerOSXStandalone13GetMouseScaleEv", &methodsToReplace.ScreenMgrGetMouseScale},
	{"__ZN16ScreenManagerOSX14WillChangeModeERSt6vectorIiSaIiEE", &unityMethods.ScreenMgrWillChangeMode},
	{"__ZN16ScreenManagerOSX31SetFullscreenResolutionRobustlyERiS0_ib12ObjectHandleI19GraphicsContext_TagPvE", &unityMethods.ScreenMgrSetFullscreenResolutionRobustly},
	{"__ZN16ScreenManagerOSX19DidChangeScreenModeEiii12ObjectHandleI19GraphicsContext_TagPvERSt6vectorIiSaIiEE", &unityMethods.ScreenMgrDidChangeScreenMode},
	{"__ZN16ScreenManagerOSX19DidChangeScreenModeEiii12ObjectHandleI19GraphicsContext_TagPvE", &unityMethods.ScreenMgrDidChangeScreenMode},
	{"__ZN26ScreenManagerOSXStandalone28SetupDownscaledFullscreenFBOEii", &unityMethods.ScreenMgrSetupDownscaledFullscreenFBO},
	{"__ZN26ScreenManagerOSXStandalone24RebindDefaultFramebufferEv", &unityMethods.ScreenMgrRebindDefaultFramebuffer},

	{"__ZN18GfxFramebufferGLES18GetFramebufferNameERK20GfxRenderTargetSetup", &unityMethods.GfxFBGLESGetFramebufferName},
	{"__ZN7ApiGLES15BlitFramebufferEN2gl17FramebufferHandleENS0_15FramebufferReadES1_S1_iiiiiiiiNS0_15FramebufferMaskE", &unityMethods.ApiGLESBlitFramebuffer},
	{"__ZN7ApiGLES15BlitFramebufferEN2gl6HandleILNS0_10ObjectTypeE9EEENS0_15FramebufferReadES3_S3_iiiiiiiiNS0_15FramebufferMaskE", &unityMethods.ApiGLESBlitFramebuffer},
	{"__ZN7ApiGLES15BindFramebufferEN2gl17FramebufferTargetENS0_17FramebufferHandleE", &unityMethods.ApiGLESBindFramebuffer},
	{"__ZN7ApiGLES15BindFramebufferEN2gl17FramebufferTargetENS0_6HandleILNS0_10ObjectTypeE9EEE", &unityMethods.ApiGLESBindFramebuffer},
	{"__ZN7ApiGLES5ClearEjRK10ColorRGBAfbfi", &unityMethods.ApiGLESClear},

	{"__ZN10Matrix4x4f8SetOrthoEffffff", &unityMethods.Matrix4x4fSetOrtho},

	{"__ZN4core20StringStorageDefaultIcE6assignEPKcm", &unityMethods.StringStorageDefaultAssign},
	{"__Z19free_alloc_internalPv18MemLabelIdentifier", &unityMethods.FreeAllocInternal},

	{"_gDefaultFBOGL", &unityMethods.gDefaultFBOGL},
	{"_g_Renderer", &unityMethods.gRenderer},
	{"_gGL", &unityMethods.gGL},
	{"_g_MetalSurfaceRequestedSize", &unityMethods.gMetalSurfaceRequestedSize},
	{"_g_PopUpWindow", &unityMethods.gPopUpWindow},
	{"__ZN10Matrix4x4f8identityE", &unityMethods.identityMatrix},
	{"__ZL14displayDevices", &unityMethods.displayDevices},

	{"__ZNSsC1EPKcRKSaIcE", &cppMethods.MakeStdString},
	{"__ZNSs4_Rep20_S_empty_rep_storageE", &cppMethods.stdStringEmptyRepStorage},
	{"__ZNSs4_Rep10_M_destroyERKSaIcE", &cppMethods.DestroyStdStringRep},
	{"__ZdlPv", &cppMethods.operatorDelete},
};

static const struct {
	int firstVersion;
	int lastVersion;
	void *target;
} notAlwaysAvailable[] = {
	{UNITY_VERSION_TATARI_OLD, INT_MAX, &unityMethods.gRenderer},
	{UNITY_VERSION_TATARI_OLD, INT_MAX, &unityMethods.ScreenMgrRebindDefaultFramebuffer},
	{0, UNITY_VERSION_TATARI_OLD, &unityMethods.MustSwitchResolutionForFullscreenMode},
	{0, UNITY_VERSION_TATARI_NEW, &unityMethods.ScreenMgrSetFullscreenResolutionRobustly},
	{UNITY_VERSION_TATARI_NEW, INT_MAX, &unityMethods.GetFramebufferGLES},
	{UNITY_VERSION_TATARI_NEW, UNITY_VERSION_HIMA, &unityMethods.ApiGLESBlitFramebuffer},
	{UNITY_VERSION_TATARI_NEW, INT_MAX, &unityMethods.ApiGLESBindFramebuffer},
	{0, UNITY_VERSION_HIMA, &unityMethods.gDefaultFBOGL},
	{UNITY_VERSION_ME, UNITY_VERSION_TSUMI, &unityMethods.gMetalSurfaceRequestedSize},
	{UNITY_VERSION_ME, UNITY_VERSION_TSUMI, &unityMethods.RecreateSurface},
	{UNITY_VERSION_ME, INT_MAX, &unityMethods.ApiGLESClear},
	{0, UNITY_VERSION_TSUMI, &unityMethods.ScreenMgrWillChangeMode},
	{0, UNITY_VERSION_TSUMI, &unityMethods.GfxHelperDrawQuad},
	{UNITY_VERSION_MINA, INT_MAX, &unityMethods.GetCurrentMetalSurface},
	{UNITY_VERSION_MINA, INT_MAX, &unityMethods.StringStorageDefaultAssign},
	{UNITY_VERSION_MINA, INT_MAX, &unityMethods.FreeAllocInternal},
};

# pragma mark - Symbol loading

/// Sorts the wanted functions array by name for binary search
static void sortWantedFunctions() {
	const int size = sizeof(wantedFunctions)/sizeof(*wantedFunctions);
	for (int i = 1; i < size; i++) {
		auto tmp = wantedFunctions[i];
		int j = i;
		while (j > 0 && strcmp(tmp.name, wantedFunctions[j-1].name) < 0) {
			wantedFunctions[j] = wantedFunctions[j-1];
			j -= 1;
		}
		wantedFunctions[j] = tmp;
	}
}

/// Uses binary search to find the function with the given name, and writes `function` to its target
static void writeWantedFunction(const char *name, void *function) {
	int low = 0;
	int high = sizeof(wantedFunctions)/sizeof(*wantedFunctions);
	while (high > low) {
		int mid = (high + low) / 2;
		int cmp = strcmp(name, wantedFunctions[mid].name);
		if (cmp < 0) {
			high = mid;
		}
		else if (cmp > 0) {
			low = mid + 1;
		}
		else {
			*(void **)wantedFunctions[mid].target = function;
			return;
		}
	}
}

/// Search through the given symbol list to find pointers to functions
///
/// Functions it finds that are listed in `wantedFunctions` will have their addresses written into the associated pointers
static void searchSyms(const struct nlist_64 *syms, int count, const char *strings, int64_t functionOffset) {
	sortWantedFunctions();
	for (int i = 0; i < count; i++) {
		uint32_t offset = syms[i].n_un.n_strx;
		const char *name = strings + offset;
		writeWantedFunction(name, (void *)(syms[i].n_value + functionOffset));
	}
}

static int32_t bswapIfNecessary(int needsSwap, int32_t input) {
	if (needsSwap) { return OSSwapInt32(input); }
	return input;
}

/// Gets the offset of the given mach header in a fat binary
static int64_t getFatOffset(FILE *file, const struct mach_header_64* target) {
	fseek(file, 0, SEEK_SET);
	struct fat_header head;
	fread(&head, sizeof(head), 1, file);
	int needsSwap = 0;
	if (head.magic == FAT_CIGAM) {
		needsSwap = 1;
	}
	else if (head.magic != FAT_MAGIC) {
		return 0;
	}
	int nArch = bswapIfNecessary(needsSwap, head.nfat_arch);
	struct fat_arch archs[nArch];
	fread(archs, sizeof(*archs), nArch, file);
	for (int i = 0; i < nArch; i++) {
		if (bswapIfNecessary(needsSwap, archs[i].cputype) == target->cputype && bswapIfNecessary(needsSwap, archs[i].cpusubtype) == target->cpusubtype) {
			return bswapIfNecessary(needsSwap, archs[i].offset);
		}
	}
	return 0;
}

/// Reads pointers into `unityMethods`
static void initializeUnity() {
	static bool initializationDone = false;
	if (initializationDone) { return; }
	initializationDone = true;

	const struct mach_header_64 *header = (struct mach_header_64 *)_dyld_get_image_header(0);
	if (header->magic != MH_MAGIC_64) { abort(); }
	intptr_t offset = _dyld_get_image_vmaddr_slide(0);

	const struct load_command *lc = (struct load_command *)(header + 1);

	for (int i = 0; i < header->ncmds; i++, lc = (struct load_command *)((char *)lc + lc->cmdsize)) {
		if (lc->cmd == LC_SYMTAB) {
			const struct symtab_command *cmd = (const struct symtab_command *)lc;

			char *buf = (char *)malloc(cmd->strsize + cmd->nsyms * sizeof(struct nlist_64));

			FILE *fd = fopen(_dyld_get_image_name(0), "r");
			int64_t foffset = getFatOffset(fd, header);
			fseek(fd, cmd->symoff + foffset, SEEK_SET);
			fread(buf + cmd->strsize, sizeof(struct nlist_64), cmd->nsyms, fd);
			fseek(fd, cmd->stroff + foffset, SEEK_SET);
			fread(buf, 1, cmd->strsize, fd);
			fclose(fd);

			searchSyms((const struct nlist_64 *)(buf + cmd->strsize), cmd->nsyms, buf, offset);

			free(buf);
		}
	}

	// Symbols from outside the binary (e.g. libc++) won't get found by the above code but must be public so we can get them this way
	for (int i = 0; i < sizeof(wantedFunctions) / sizeof(*wantedFunctions); i++) {
		struct WantedFunction fn = wantedFunctions[i];
		if (*(void **)fn.target == NULL) {
			// Skip the initial `_` when using with dlsym
			*(void **)fn.target = dlsym(RTLD_DEFAULT, fn.name + 1);
		}
	}
}

/// Modifies the function pointed to by `oldFunction` to immediately jump to `newFunction`
__attribute__((noinline))
static void _replaceFunction(void *oldFunction, void *newFunction) {
	// From http://thomasfinch.me/blog/2015/07/24/Hooking-C-Functions-At-Runtime.html
	// Note: dlsym doesn't work on non-exported symbols which is why we're not using it
	ssize_t offset = ((ssize_t)newFunction - ((ssize_t)oldFunction + 5));

	// Make the memory containing the original funcion writable
	// Code from http://stackoverflow.com/questions/20381812/mprotect-always-returns-invalid-arguments
	size_t pageSize = sysconf(_SC_PAGESIZE);
	uintptr_t start = (uintptr_t)oldFunction;
	uintptr_t end = start + 1;
	uintptr_t pageStart = start & -pageSize;
	mprotect((void *)pageStart, end - pageStart, PROT_READ | PROT_WRITE | PROT_EXEC);

	// Insert the jump instruction at the beginning of the original function
	int64_t instruction = 0xe9 | (offset << 8);
	*(int64_t *)oldFunction = instruction;

	// Re-disable write
	mprotect((void *)pageStart, end - pageStart, PROT_READ | PROT_EXEC);
}

/// Modifies the function pointed to by `oldFunction` to immediately jump to `newFunction`
template<typename Result, typename... Args>
static void replaceFunction(Result (*oldFunction)(Args...), Result (*newFunction)(Args...)) {
	_replaceFunction((void *)oldFunction, (void *)newFunction);
}

#pragma mark - Unity version switching

static bool verifyAllOffsetsWereFound() {
	bool allFound = true;
	for (const auto& function : wantedFunctions) {
		if (*(void **)function.target == nullptr) {
			// Check if it's known to not be here
			bool isExpectedMissing = false;
			for (const auto& entry : notAlwaysAvailable) {
				if ((UnityVersion < entry.firstVersion || UnityVersion > entry.lastVersion) && entry.target == function.target) {
					isExpectedMissing = true;
				}
			}
			if (isExpectedMissing) { continue; }

			fprintf(stderr, "libRetinaizer: %s was not found\n", function.name);
			allFound = false;
		}
	}
	return allFound;
}

static bool verifyAndConfigureForUnityVersion(const char *version) {
	if (strcmp(version, "5.2.2f1") == 0) {
		_allOffsets = OnikakushiOffsets;
		return true;
	}
	replacementMethods.ScreenMgrGetMouseOrigin = (decltype(replacementMethods.ScreenMgrGetMouseOrigin))TatariGetMouseOriginReplacement;
	replacementMethods.ScreenMgrGetMouseScale = (decltype(replacementMethods.ScreenMgrGetMouseScale))TatariGetMouseScaleReplacement;
	if (strcmp(version, "5.3.4p1") == 0) {
		_allOffsets = TatarigoroshiOldOffsets;
		return true;
	}
	if (strcmp(version, "5.4.0f1") == 0) {
		_allOffsets = TatarigoroshiNewOffsets;
		return true;
	}
	if (strcmp(version, "5.4.1f1") == 0) {
		// 5.4.1f1 uses the same offsets as 5.4.0f1
		_allOffsets = TatarigoroshiNewOffsets;
		UnityVersion = UNITY_VERSION_HIMA;
		return true;
	}
	if (strcmp(version, "5.5.3p1") == 0) {
		_allOffsets = MeakashiOffsets;
		return true;
	}
	if (strcmp(version, "5.5.3p3") == 0) {
		// 5.5.3p3 uses the same offsets as 5.5.3p1
		_allOffsets = MeakashiOffsets;
		UnityVersion = UNITY_VERSION_TSUMI;
		return true;
	}
	if (strcmp(version, "5.6.7f1") == 0) {
		_allOffsets = MinagoroshiOffsets;
		return true;
	}
	fprintf(stderr, "libRetinaizer: Unrecognized unity version %s\n", version);
	return false;
}

static const char * getUnityVersion() {
	const unsigned char *getVersion = (unsigned char *)unityMethods.ApplicationGetCustomPropUnityVersion;
	for (int i = 0; i < 20; i++) {
		// Looking for LEA RDI,[rip+VersionStringOffset]
		// We're expecting the implementation to call scripting_string_new on a C version of the version string
		if (getVersion[i] == 0x48 && getVersion[i+1] == 0x8d && getVersion[i+2] == 0x3d) {
			const int *offset = (int *)(getVersion + i + 3);
			return *offset + 4 + (char *)(offset);
		}
	}
	return "unknown";
}

static const char *unityVersion = "unknown";

#pragma mark - Mod initializer

extern "C" {
void goRetina(void);
}

static bool verifyOkayToRun() {
	bool unityVersionOkay = verifyAndConfigureForUnityVersion(unityVersion);
	bool offsetsFound = verifyAllOffsetsWereFound();
	if (!unityVersionOkay || !offsetsFound) {
		fprintf(stderr, "libRetinaizer: Not enabling retina due to the above issues\n");
		return false;
	}
	fprintf(stderr, "libRetinaizer: All checks okay, will enable retina\n");
	return true;
}

void goRetina() {
	static bool isRetina = false;
	if (isRetina) { return; }
	isRetina = true;
	initializeUnity();
	if (NSApp == nullptr) {
		// Unity hasn't initialized yet, which means our first printout won't go to the unity log
		dispatch_async_f(dispatch_get_main_queue(), NULL, [](void*){ verifyOkayToRun(); });
	}
	if (unityMethods.ApplicationGetCustomPropUnityVersion) {
		unityVersion = getUnityVersion();
	}
	if (!verifyOkayToRun()) { return; }
	replaceFunction(methodsToReplace.ScreenMgrGetMouseOrigin, replacementMethods.ScreenMgrGetMouseOrigin);
	replaceFunction(methodsToReplace.InputReadMousePosition, replacementMethods.InputReadMousePosition);
	replaceFunction(methodsToReplace.ScreenMgrGetMouseScale, replacementMethods.ScreenMgrGetMouseScale);
	replaceFunction(methodsToReplace.ScreenMgrSetResImmediate, replacementMethods.ScreenMgrSetResImmediate);
	replaceFunction(methodsToReplace.ScreenMgrCreateAndShowWindow, replacementMethods.ScreenMgrCreateAndShowWindow);
	replaceFunction(methodsToReplace.ScreenMgrPreBlit, replacementMethods.ScreenMgrPreBlit);
	method_setImplementation(class_getInstanceMethod(NSClassFromString(@"PlayerWindowDelegate"), @selector(windowDidResize:)), (IMP)WindowDidResizeReplacement);
}

static bool goRetinaOnLoad = ((void)goRetina(), true);
