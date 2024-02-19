CC=clang
GITVER=$(shell A=`git describe --tags --always 2>/dev/null` && echo -DGIT_VER=\\\"$$A\\\")
MMFLAGS=-stdlib=libc++ -std=gnu++14 -fno-rtti -fno-objc-exceptions -fno-exceptions -mmacosx-version-min=10.7 -Os -flto=full -fobjc-arc $(GITVER)
CFLAGS=-mmacosx-version-min=10.7 -Os -flto=full $(GITVER)
LDFLAGS=-mmacosx-version-min=10.7 -Os -flto=full -framework Cocoa -framework OpenGL -framework Carbon

all: libRetinaizer.dylib retinaizer

libRetinaizer.dylib: Replacements.o Retinaizer.o
	$(CC) -o $@ -shared $^ $(LDFLAGS)

retinaizer: UnityNewRetinaizer.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.mm
	$(CC) -MMD -c -o $@ $< $(MMFLAGS)

%.o: %.c
	$(CC) -MMD -c -o $@ $< $(CFLAGS)

-include *.d

.PHONY: clean

clean:
	rm -f retinaizer libRetinaizer.dylib *.o *.d
