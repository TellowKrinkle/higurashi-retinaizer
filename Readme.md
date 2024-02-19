# Higurashi Retinaizer

Enables retina display support for Higurashi games on macOS.  May also work on other games that use the same unity version as one of the Higurashi games

## Download
You can download a pre-built copy from the releases section [here](https://github.com/tellowkrinkle/higurashi-retinaizer/releases/latest)

## Installation
For games on Unity 2017.x and newer or if you're unsure which Unity version your game is:

Run `/path/to/retinaizer HigurashiGame.app`

If it prints `Try using libRetinaizer.dylib instead`, follow the directions below for a Unity 5.x game.

For games on Unity 5.x:

Copy `libRetinaizer.dylib` to `HigurashiGame.app/Contents/Frameworks/MonoEmbedRuntime/osx/`.  You will need a version of `Assembly-CSharp.dll` that has [this commit](https://github.com/07th-mod/higurashi-assembly/commit/0f625a5bcebdb07674531b92eb68f8d16a9bc14f) in it, which is included in the latest version of the 07th-mod package.

Alternatively, you can run your game with the environment variable `DYLD_INSERT_LIBRARIES` set to `libRetinaizer.dylib`, for example `DYLD_INSERT_LIBRARIES=/path/to/libRetinaizer.dylib HigurashiGame.app/Contents/MacOS/HigurashiGame`

If you find that your game does not retinaize, open your Unity log (`~/Library/Logs/Unity/Player.log`) and search it for `libRetinaizer`.  If anything comes up, it should contain a reason for not loading (or a claim that it tried to enable retina, in which case there's an issue with the library).  If nothing comes up, you messed up the loading of the dylib and should verify that you followed the above steps correctly.

## Compiling
Compile with `make`

## Compatible Games / Unity Versions
libRetinaizer.dylib:
- Onikakushi, Watanagashi (Unity 5.2.2f1)
- Tatarigoroshi (Unity 5.3.4p1 and 5.4.0f1)
- Himatsubushi (Unity 5.4.1f1)
- Meakashi (Unity 5.5.3p1)
- Tsumihoroboshi (Unity 5.5.3p3)
- Minagoroshi (Unity 5.6.7f1)

retinaizer command line tool:
- Matsuribayashi (Unity 2017.2.5f1)
- Rei (Unity 2019.4.36f1)

## Known Issues
- Game screen resolutions are used as pixel resolutions, not display-independent-point resolutions (so 1280x720 will now make a tiny window).  It seemed like less work to do things this way rather than the other way.

## Development
To ease development and debugging, use of Xcode is recommended.

You can use the included `.xcodeproj` to compile and run.  Edit the scheme of the project (click the dropdown by the run button and chose `Edit scheme...`) and set the executable to the game you want to debug under.  You don't need to copy the binary anywhere, the scheme should set `DYLD_INSERT_LIBRARIES` to the built `dylib`.  Now you can run with ⌘R and breakpoints will work as expected. 

Note: Tatarigoroshi crashes on fullscreen and defullscreen when run under lldb (and therefore also when run through xcode).  Don't think that's due to the retinaizer and spend large amounts of time trying to debug it.
