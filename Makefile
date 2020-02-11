CC=clang
CFLAGS=-stdlib=libc++ -std=gnu++14 -fno-rtti -fno-objc-exceptions -fno-exceptions -mmacosx-version-min=10.7 -O3 -flto=full
LDFLAGS=-mmacosx-version-min=10.7 -O3 -flto=full -framework Cocoa -framework OpenGL -framework Carbon

%.o: %.mm
	$(CC) -c -o $@ $< $(CFLAGS)

libRetinaizer.dylib: Replacements.o Retinaizer.o
	$(CC) -o $@ -shared $^ $(LDFLAGS)

.PHONY: clean

clean:
	rm -f libRetinaizer.dylib *.o
