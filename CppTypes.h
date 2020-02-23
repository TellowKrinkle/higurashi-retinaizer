#ifndef CppTypes_h
#define CppTypes_h

typedef struct StdString {
	char *c_str;
} StdString;

typedef struct StringStorageDefault {
	char *data;
	union {
		char inlineData[16];
		size_t capacity;
	};
	size_t len;
	int memLabel;
} StringStorageDefault;
static_assert(sizeof(StringStorageDefault) == 40, "Expected size of StringStorageDefault to be 40");

typedef struct IntVector {
	int *begin;
	int *end;
	int *end_cap;
} IntVector;

template<typename T>
struct RectT {
	T x;
	T y;
	T width;
	T height;
};

typedef struct Matrix4x4f {
	float m00;
	float m01;
	float m02;
	float m03;
	float m10;
	float m11;
	float m12;
	float m13;
	float m20;
	float m21;
	float m22;
	float m23;
	float m30;
	float m31;
	float m32;
	float m33;
} Matrix4x4f;
static_assert(sizeof(Matrix4x4f) == 64, "Expected size of Matrix4x4f");

typedef struct GfxDevice GfxDevice;
typedef struct InputManager InputManager;
typedef struct PlayerSettings PlayerSettings;
typedef struct QualitySetting QualitySetting;
typedef struct QualitySettings QualitySettings;
typedef struct RenderSurface RenderSurface;
typedef struct ScreenManager ScreenManager;
typedef struct MetalSurfaceHelper MetalSurfaceHelper;

#endif /* CppTypes_h */
