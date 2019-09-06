#ifndef CppTypes_h
#define CppTypes_h

typedef struct StdString {
	char *c_str;
} StdString;

typedef struct Resolution {
	int width;
	int height;
	int refreshRate;
} Resolution;

typedef struct ResolutionVector {
	Resolution *begin;
	Resolution *end;
	Resolution *end_cap;
} ResolutionVector;

typedef struct IntVector {
	int *begin;
	int *end;
	int *end_cap;
} IntVector;

typedef struct GraphicsContextGL {
	void *cglContext;
	uint64_t unk1;
	uint32_t unk2;
	bool unk3;
} GraphicsContextGL;

#endif /* CppTypes_h */
