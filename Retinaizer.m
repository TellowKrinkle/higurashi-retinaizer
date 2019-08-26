#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <mach-o/fat.h>
#import <Cocoa/Cocoa.h>

#pragma mark - Structs

@interface WindowFakeSizer : NSWindow

- (NSRect)actualContentRectForFrameRect:(NSRect)frameRect;

@end

typedef struct Pointf {
	float x;
	float y;
} Pointf;

static struct UnityMethods {
	void (*InputReadMousePosition)(void);
	void *(*GetScreenManager)(void);
	void *(*GetInputManager)(void);
	CGDirectDisplayID (*ScreenMgrGetDisplayID)(void *);
	Pointf (*ScreenMgrGetMouseOrigin)(void *);
	Pointf (*ScreenMgrGetMouseScale)(void *);
} unityMethods = {0};

static const struct WantedFunction {
	char *name;
	void *target;
} wantedFunctions[] = {
	{"__Z22InputReadMousePositionv", &unityMethods.InputReadMousePosition},
	{"__Z16GetScreenManagerv", &unityMethods.GetScreenManager},
	{"__ZNK16ScreenManagerOSX12GetDisplayIDEv", &unityMethods.ScreenMgrGetDisplayID},
	{"__ZN26ScreenManagerOSXStandalone13GetMouseScaleEv", &unityMethods.ScreenMgrGetMouseScale},
	{"__ZN26ScreenManagerOSXStandalone14GetMouseOriginEv", &unityMethods.ScreenMgrGetMouseOrigin},
	{"__Z15GetInputManagerv", &unityMethods.GetInputManager},
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
}

/// Modifies the function pointed to by `oldFunction` to immediately jump to `newFunction`
static void replaceFunction(void *oldFunction, void *newFunction) {
	// From http://thomasfinch.me/blog/2015/07/24/Hooking-C-Functions-At-Runtime.html
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

# pragma mark - Replacement Functions

static Pointf GetMouseOriginReplacement(void *mgr);
static void ReadMousePosReplacement(void);

void goRetina() {
	initializeUnity();
	dispatch_async(dispatch_get_main_queue(), ^{
		replaceFunction(unityMethods.ScreenMgrGetMouseOrigin, GetMouseOriginReplacement);
		replaceFunction(unityMethods.InputReadMousePosition, ReadMousePosReplacement);
		NSApplication *app = [NSApplication sharedApplication];
		for (NSWindow *window in [app orderedWindows]) {
			NSView *view = [window contentView];
			if (![view isKindOfClass:NSClassFromString(@"PlayerWindowView")]) {
				continue;
			}
			[view setWantsBestResolutionOpenGLSurface:YES];
			object_setClass(window, [WindowFakeSizer class]);
		}
	});
}

@implementation WindowFakeSizer
- (NSRect)actualContentRectForFrameRect:(NSRect)frameRect {
	return [super contentRectForFrameRect:frameRect];
}

- (NSRect)contentRectForFrameRect:(NSRect)frameRect {
	return [self convertRectToBacking:[super contentRectForFrameRect:frameRect]];
}
@end

static void *getVtableEntry(void *object, size_t offset) {
	void **vtable = *(void **)object;
	return *(vtable + offset / sizeof(void *));
}

static void *getField(void *object, size_t offset) {
	return (char *)object + offset;
}

static Pointf GetMouseOriginReplacement(void *mgr) {
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

static void ReadMousePosReplacement() {
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
		windowRelative = [window convertPointToBacking:windowRelative];
	}
	void *inputManager = unityMethods.GetInputManager();
	Pointf *output = getField(inputManager, 0xb0);
	*output = (Pointf){ windowRelative.x, screenHeight - windowRelative.y };
}
