# Higurashi Retinaizer

Enables retina display support for Higurashi games on macOS

## Compiling
Compile with `clang -mmacosx-version-min=10.7 -shared -O3 -framework Cocoa -framework OpenGL -framework Carbon Retinaizer.m Replacements.m -o libRetinaizer.dylib`

## Installation
Copy the compiled `libRetinaizer.dylib` to `HigurashiGame.app/Contents/Frameworks/MonoEmbedRuntime/osx/`.  You will need a version of `Assembly-CSharp.dll` that has [this commit](https://github.com/07th-mod/higurashi-assembly/commit/0f625a5bcebdb07674531b92eb68f8d16a9bc14f) in it.

## Known Issues
- The game window moves to the upper right immediately after launch
- Fullscreen mode is horribly broken.  Don't try it if you don't want to have a seizure.
- The vtable offsets used are known to work properly with the version of Unity used by Onikakushi but have not been tested with later games.  It may break horribly on them.

## Development
To ease development and debugging, use of Xcode is recommended.

Create a new Xcode project and select Library.  Then set the framework to Cocoa and the type to Dynamic.  Delete the `.h` and `.m` files it defaults to, and drag `Retinaizer.m` into the Xcode file manager, making sure to uncheck `Copy items if needed`.  Build once, then use `ln -s` to make a soft link from the Xcode build product to install directory of the game you want to test with (path above in `Installation`).  Finally, add a new build scheme and edit the `Executable` to be the game you soft-linked the dylib into.  Now you can run with ⌘R and breakpoints will work as expected. 
