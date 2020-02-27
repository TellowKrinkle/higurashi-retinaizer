CC=clang
GITVER=$(shell A=`git describe --tags --always 2>/dev/null` && echo -DGIT_VER=\\\"$$A\\\")
CFLAGS=-stdlib=libc++ -std=gnu++14 -fno-rtti -fno-objc-exceptions -fno-exceptions -mmacosx-version-min=10.7 -Os -flto=full -fobjc-arc $(GITVER)
LDFLAGS=-mmacosx-version-min=10.7 -Os -flto=full -framework Cocoa -framework OpenGL -framework Carbon

libRetinaizer.dylib: Replacements.o Retinaizer.o
	$(CC) -o $@ -shared $^ $(LDFLAGS)

%.o: %.mm
	$(CC) -MMD -c -o $@ $< $(CFLAGS)

-include *.d

.PHONY: clean

clean:
	rm -f libRetinaizer.dylib *.o *.d
