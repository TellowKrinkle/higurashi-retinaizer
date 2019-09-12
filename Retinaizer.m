#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <mach-o/fat.h>
#import <Cocoa/Cocoa.h>
#include "Retinaizer.h"
#include "Replacements.h"
#include <dlfcn.h>

#pragma mark - Structs

static struct MethodsToReplace {
	void (*InputReadMousePosition)(void);
	Pointf (*ScreenMgrGetMouseOrigin)(void *);
	Pointf (*ScreenMgrGetMouseScale)(void *);
	bool (*ScreenMgrSetResImmediate)(void *, int, int, bool, int);
	void (*ScreenMgrCreateAndShowWindow)(void *, int, int, bool);
	void (*ScreenMgrPreBlit)(void *);
} methodsToReplace = {0};

struct UnityMethods unityMethods = {0};
struct CPPMethods cppMethods = {0};

static const struct WantedFunction {
	char *name;
	void *target;
} wantedFunctions[] = {
	{"__Z22InputReadMousePositionv", &methodsToReplace.InputReadMousePosition},
	{"__ZN26ScreenManagerOSXStandalone14GetMouseOriginEv", &methodsToReplace.ScreenMgrGetMouseOrigin},
	{"__ZN26ScreenManagerOSXStandalone22SetResolutionImmediateEiibi", &methodsToReplace.ScreenMgrSetResImmediate},
	{"__ZN26ScreenManagerOSXStandalone19CreateAndShowWindowEiib", &methodsToReplace.ScreenMgrCreateAndShowWindow},
	{"__ZN26ScreenManagerOSXStandalone7PreBlitEv", &methodsToReplace.ScreenMgrPreBlit},

	{"__Z16GetScreenManagerv", &unityMethods.GetScreenManager},
	{"__Z12GetGfxDevicev", &unityMethods.GetGfxDevice},
	{"__Z15GetInputManagerv", &unityMethods.GetInputManager},
	{"__Z18GetQualitySettingsv", &unityMethods.GetQualitySettings},
	{"__Z17GetPlayerSettingsv", &unityMethods.GetPlayerSettings},
	{"__Z16GetRealGfxDevicev", &unityMethods.GetRealGfxDevice},
	{"__Z23GetRequestedDeviceLevelv", &unityMethods.GetRequestedDeviceLevel},
	{"__Z11IsBatchmodev", &unityMethods.IsBatchMode},
	{"__Z37MustSwitchResolutionForFullscreenModev", &unityMethods.MustSwitchResolutionForFullscreenMode},
	{"__Z21AllowResizeableWindowv", &unityMethods.AllowResizableWindow},
	{"__Z39Application_Get_Custom_PropUnityVersionv", &unityMethods.ApplicationGetCustomPropUnityVersion},

	{"__Z12SetSyncToVBL12ObjectHandleI19GraphicsContext_TagPvEi", &unityMethods.SetSyncToVBL},
	{"__ZN11PlayerPrefs6SetIntERKSsi", &unityMethods.PlayerPrefsSetInt},
	{"__Z14MakeNewContext16GfxDeviceLevelGLiiibb17DepthBufferFormatPib", &unityMethods.MakeNewContext},
	{"__ZN13RenderTexture10ReleaseAllEv", &unityMethods.RenderTextureReleaseAll},
	{"__Z20DestroyMainContextGLv", &unityMethods.DestroyMainContextGL},
	{"__ZN14GraphicsHelper8DrawQuadER9GfxDevicePK14ChannelAssignsbff", &unityMethods.GfxHelperDrawQuad},

	{"__ZNK16ScreenManagerOSX12GetDisplayIDEv", &unityMethods.ScreenMgrGetDisplayID},
	{"__ZN26ScreenManagerOSXStandalone13GetMouseScaleEv", &methodsToReplace.ScreenMgrGetMouseScale},
	{"__ZN16ScreenManagerOSX14WillChangeModeERSt6vectorIiSaIiEE", &unityMethods.ScreenMgrWillChangeMode},
	{"__ZN16ScreenManagerOSX31SetFullscreenResolutionRobustlyERiS0_ib12ObjectHandleI19GraphicsContext_TagPvE", &unityMethods.ScreenMgrSetFullscreenResolutionRobustly},
	{"__ZN16ScreenManagerOSX19DidChangeScreenModeEiii12ObjectHandleI19GraphicsContext_TagPvERSt6vectorIiSaIiEE", &unityMethods.ScreenMgrDidChangeScreenMode},
	{"__ZN26ScreenManagerOSXStandalone28SetupDownscaledFullscreenFBOEii", &unityMethods.ScreenMgrSetupDownscaledFullscreenFBO},

	{"__ZN10Matrix4x4f8SetOrthoEffffff", &unityMethods.Matrix4x4fSetOrtho},

	{"_gDefaultFBOGL", &unityMethods.gDefaultFBOGL},
	{"_g_PopUpWindow", &unityMethods.gPopUpWindow},
	{"__ZN10Matrix4x4f8identityE", &unityMethods.identityMatrix},
	{"__ZL14displayDevices", &unityMethods.displayDevices},

	{"__ZNSsC1EPKcRKSaIcE", &cppMethods.MakeStdString},
	{"__ZNSs4_Rep20_S_empty_rep_storageE", &cppMethods.stdStringEmptyRepStorage},
	{"__ZNSs4_Rep10_M_destroyERKSaIcE", &cppMethods.DestroyStdStringRep},
	{"__ZdlPv", &cppMethods.operatorDelete},
	{"_mono_string_to_utf8", &cppMethods.mono_string_to_utf8},
};

# pragma mark - Symbol loading and replacement

/// Search through the given symbol list to find pointers to functions
///
/// Functions it finds that are listed in `wantedFunctions` will have their addresses written into the associated pointers
static void searchSyms(const struct nlist_64 *syms, int count, const char *strings, int64_t functionOffset) {
	for (int i = 0; i < count; i++) {
		uint32_t offset = syms[i].n_un.n_strx;
		const char *name = strings + offset;
		for (int j = 0; j < sizeof(wantedFunctions) / sizeof(*wantedFunctions); j++) {
			if (strcmp(wantedFunctions[j].name, name) == 0) {
				*(void**)wantedFunctions[j].target = (void *)(syms[i].n_value + functionOffset);
			}
		}
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
	const struct mach_header_64 *header = (struct mach_header_64 *)_dyld_get_image_header(0);
	if (header->magic != MH_MAGIC_64) { abort(); }
	intptr_t offset = _dyld_get_image_vmaddr_slide(0);

	const struct load_command *lc = (struct load_command *)(header + 1);

	for (int i = 0; i < header->ncmds; i++, lc = (struct load_command *)((char *)lc + lc->cmdsize)) {
		if (lc->cmd == LC_SYMTAB) {
			const struct symtab_command *cmd = (const struct symtab_command *)lc;

			char *buf = malloc(cmd->strsize + cmd->nsyms * sizeof(struct nlist_64));

			FILE *fd = fopen(_dyld_get_image_name(0), "r");
			int64_t foffset = getFatOffset(fd, header);
			fseek(fd, cmd->symoff + foffset, SEEK_SET);
			fread(buf + cmd->strsize, sizeof(struct nlist_64), cmd->nsyms, fd);
			fseek(fd, cmd->stroff + foffset, SEEK_SET);
			fread(buf, 1, cmd->strsize, fd);
			fclose(fd);

			searchSyms((void *)(buf + cmd->strsize), cmd->nsyms, buf, offset);

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
static void replaceFunction(void *oldFunction, void *newFunction) {
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

static bool verifyAllOffsetsWereFound() {
	bool allFound = true;
	for (int i = 0; i < sizeof(wantedFunctions) / sizeof(*wantedFunctions); i++) {
		if (*(void **)wantedFunctions[i].target == NULL) {
			fprintf(stderr, "libRetinaizer: Warning: %s was not found, not enabling retina!\n", wantedFunctions[i].name);
			allFound = false;
		}
	}
	return allFound;
}

static bool verifyUnityVersion(const char *version) {
	if (strcmp(version, "5.2.2f1") == 0) {
		return true;
	}
	fprintf(stderr, "libRetinaizer: Unrecognized unity version %s, not enabling retina\n", version);
	return false;
}

static char * getUnityVersion() {
	void *versionMonoString = unityMethods.ApplicationGetCustomPropUnityVersion();
	return cppMethods.mono_string_to_utf8(versionMonoString);
}

static bool isRetina = false;
static const char *unityVersion = "unknown";

void goRetina() {
	if (isRetina) { return; }
	isRetina = true;
	initializeUnity();
	if (unityMethods.ApplicationGetCustomPropUnityVersion && cppMethods.mono_string_to_utf8) {
		unityVersion = strdup(getUnityVersion());
	}
	bool unityVersionOkay = verifyUnityVersion(unityVersion);
	bool offsetsFound = verifyAllOffsetsWereFound();
	if (!unityVersionOkay || !offsetsFound) { return; }
	replaceFunction(methodsToReplace.ScreenMgrGetMouseOrigin, GetMouseOriginReplacement);
	replaceFunction(methodsToReplace.InputReadMousePosition, ReadMousePosReplacement);
	replaceFunction(methodsToReplace.ScreenMgrGetMouseScale, GetMouseScaleReplacement);
	replaceFunction(methodsToReplace.ScreenMgrSetResImmediate, SetResImmediateReplacement);
	replaceFunction(methodsToReplace.ScreenMgrCreateAndShowWindow, CreateAndShowWindowReplacement);
	replaceFunction(methodsToReplace.ScreenMgrPreBlit, PreBlitReplacement);
	method_setImplementation(class_getInstanceMethod(NSClassFromString(@"PlayerWindowDelegate"), @selector(windowDidResize:)), (IMP)WindowDidResizeReplacement);
	dispatch_async(dispatch_get_main_queue(), ^{
		NSApplication *app = [NSApplication sharedApplication];
		for (NSWindow *window in [app orderedWindows]) {
			NSView *view = [window contentView];
			if (![view isKindOfClass:NSClassFromString(@"PlayerWindowView")]) {
				continue;
			}
			[view setWantsBestResolutionOpenGLSurface:YES];
		}
	});
}

__attribute__((constructor))
void setupRetinaizer() {
	dispatch_async_f(dispatch_get_main_queue(), NULL, goRetina);
}
