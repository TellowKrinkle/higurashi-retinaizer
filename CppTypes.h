#ifndef CppTypes_h
#define CppTypes_h

typedef struct StdString {
	char *c_str;
} StdString;

typedef struct IntVector {
	int *begin;
	int *end;
	int *end_cap;
} IntVector;

typedef struct RectTInt {
	int x;
	int y;
	int width;
	int height;
} RectTInt;

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

#endif /* CppTypes_h */
