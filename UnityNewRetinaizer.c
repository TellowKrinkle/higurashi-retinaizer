#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum UnityVersion {
	UNITY_VERSION_2017_2_5F1 = 1,
};

#define APP_CATEGORY "public.app-category.games"

static bool getUnityVersion(char (*buf)[16], FILE* file) {
	char tmp[64];
	fseek(file, 0, SEEK_SET);
	ssize_t amt = fread(tmp, 1, sizeof(tmp) - 1, file);
	if (amt < 21)
		return false;
	tmp[amt] = '\0';
	const char* ptr = tmp + 20;
	int dotcnt = 0;
	for (int i = 0; i < 16; i++) {
		if (ptr[i] == '\0') {
			if (dotcnt < 2) {
				return false;
			}
			if (buf)
				memcpy(*buf, ptr, i + 1);
			return true;
		}
		if (ptr[i] == '.') {
			dotcnt++;
		}
	}
	return false;
}

static FILE* tryOpenGlobalGameManagers(const char* path, char (*unityVersion)[16]) {
	FILE* file = fopen(path, "r");
	if (file) {
		if (getUnityVersion(unityVersion, file)) {
			// Unity asset file, open for writing
			fclose(file);
			file = fopen(path, "r+");
			if (!file) {
				fprintf(stderr, "Failed to open %s for writing\n", path);
			}
			return file;
		}
		fclose(file);
	}
	return NULL;
}

static FILE* findGlobalGameManagers(const char* path, char (*unityVersion)[16]) {
	char buf[4096];
	FILE* file;
	if ((file = tryOpenGlobalGameManagers(path, unityVersion))) {
		return file;
	}
	const char* app = strstr(path, ".app");
	if (!app) {
		fprintf(stderr, "%s was not a valid unity archive\n", path);
		return NULL;
	}
	const char* inner;
	while ((inner = strstr(app + 4, ".app"))) {
		// We want the last instance of `.app`
		app = inner;
	}
	size_t len = app + 4 - path;
	snprintf(buf, sizeof(buf), "%.*s/Contents/Resources/Data/globalgamemanagers", (int)len, path);
	if ((file = tryOpenGlobalGameManagers(buf, unityVersion))) {
		return file;
	}
	fprintf(stderr, "Couldn't find globalgamemanagers in %s (tried %s)\n", path, buf);
	return NULL;
}

static enum UnityVersion lookupUnityVersion(const char* version) {
	if (0 == strcmp("2017.2.5f1", version)) {
		return UNITY_VERSION_2017_2_5F1;
	}
	return 0;
}

static int getRetinaModeOffset(enum UnityVersion version) {
	switch (version) {
		case UNITY_VERSION_2017_2_5F1:
			return 22;
	}
	return 0;
}

static uint32_t readU32(const void* buffer) {
	uint32_t out;
	memcpy(&out, buffer, sizeof(out));
	return out;
}

int main(int argc, const char* argv[]) {
	if (argc <= 1) {
		fprintf(stderr, "Usage: %s UnityApplication.app\n", argv[0]);
		return EXIT_FAILURE;
	}
	char unityVersion[16];
	FILE* file = findGlobalGameManagers(argv[1], &unityVersion);
	if (!file) { return EXIT_FAILURE; }
	enum UnityVersion version = lookupUnityVersion(unityVersion);
	if (!version) {
		fprintf(stderr, "Unsupported unity version %s\n", unityVersion);
		if (unityVersion[0] <= '5' && unityVersion[1] == '.') {
			fprintf(stderr, "Try using libRetinaizer.dylib instead\n");
		}
		return EXIT_FAILURE;
	}
	fprintf(stderr, "Detected unity version %s...\n", unityVersion);
	fseek(file, 0, SEEK_END);
	off_t len = ftello(file);
	if (len < 0 || len > SIZE_MAX) {
		perror("Failed to get size of file");
		return EXIT_FAILURE;
	}
	char* buf = malloc(len);
	if (!buf) {
		perror("Failed to allocate memory");
		return EXIT_FAILURE;
	}
	fseek(file, 0, SEEK_SET);
	if (fread(buf, 1, len, file) != len) {
		perror("Failed to read globalgamemanagers");
		return EXIT_FAILURE;
	}
	const char* search = memmem(buf, len, APP_CATEGORY, strlen(APP_CATEGORY));
	if (!search) {
		fprintf(stderr, "globalgamemanagers is missing app category\n");
		return EXIT_FAILURE;
	}
	int offset = getRetinaModeOffset(version);
	if (search - buf < offset) {
		fprintf(stderr, "App category too close to beginning of file\n");
		return EXIT_FAILURE;
	}
	uint32_t size = readU32(search - 4);
	if (size != strlen(APP_CATEGORY)) {
		fprintf(stderr, "App category is missing length prefix\n");
		return EXIT_FAILURE;
	}
	const char* retinaMode = search - offset;
	if (*retinaMode == 0) {
		fprintf(stderr, "Retina mode currently off, enabling...\n");
	} else if (*retinaMode == 1) {
		fprintf(stderr, "Retina mode currently on, disabling...\n");
	} else {
		fprintf(stderr, "Unexpected value for retina mode flag %d\n", (int)*retinaMode);
		return EXIT_FAILURE;
	}
	char newMode = !*retinaMode;
	fseek(file, retinaMode - buf, SEEK_SET);
	if (fwrite(&newMode, 1, 1, file) != 1) {
		perror("Failed to write new retina mode");
		return EXIT_FAILURE;
	}
	fclose(file);
	return EXIT_SUCCESS;
}
