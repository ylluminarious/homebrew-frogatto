# homebrew-frogatto

Homebrew tap for [Frogatto & Friends](https://frogatto.com), an action-adventure
game starring a quixotic frog, built from source on macOS.

## Install

```bash
brew tap ylluminarious/frogatto
brew install frogatto
```

The build takes roughly 2 minutes on Apple Silicon and installs about 1.2 GB
(most of that is game assets: music, art, levels).

## Play

```bash
frogatto
```

Game saves and preferences are stored in
`~/Library/Application Support/frogatto4/`.

## Update

```bash
brew update
brew upgrade frogatto
```

## Uninstall

```bash
brew uninstall frogatto
brew untap ylluminarious/frogatto
```

## What this builds

The formula clones two repositories:

| Repository | Role | License |
|---|---|---|
| [anura-engine/anura](https://github.com/anura-engine/anura) | Game engine (C++17, SDL2, OpenGL) | Zlib |
| [frogatto/frogatto](https://github.com/frogatto/frogatto) | Game data module (levels, art, music, scripts) | CC-BY 3.0 / CC-BY-NC-SA 4.0 |

Anura is the runtime engine; Frogatto is a "module" that provides all game
content. The formula builds the engine from source, installs the game data
alongside it, and creates the `frogatto` command.

## Dependencies

All installed automatically by Homebrew:

- `boost@1.85` (pinned — Boost 1.87+ breaks the build; [anura#419](https://github.com/anura-engine/anura/issues/419))
- `sdl2`, `sdl2_image`, `sdl2_mixer`, `sdl2_ttf`
- `cairo`, `freetype`, `glew`, `libogg`, `libvorbis`
- `cmake` (build only)

## Licensing

- **Anura engine source code:** [Zlib license](https://github.com/anura-engine/anura/blob/trunk/LICENSE)
- **Engine data and images:** CC0 (public domain)
- **Most Frogatto game files:** [CC-BY 3.0](https://creativecommons.org/licenses/by/3.0/)
- **Levels, character art, tiles, sounds, music:** [CC-BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

The CC-BY-NC-SA restriction on game assets is why this formula lives in a
third-party tap rather than homebrew-core (which requires DFSG-compliant
licenses). This is the same reason Debian places `frogatto-data` in `non-free`
and Fedora distributes it via RPM Fusion. Frogatto has been packaged across
Linux distributions (Debian, Fedora, Arch, FreeBSD, NixOS, openSUSE) for
over a decade without legal issue.

**If you enjoy the game, please support the developers by purchasing it on
[Steam](https://store.steampowered.com/app/232150/Frogatto__Friends/).**

## Troubleshooting

### No sound

If you previously ran the game with `--no-sound`, that setting is persisted.
Edit `~/Library/Application Support/frogatto4/preferences.cfg` and set
`"no_sound": false`, or launch once with:

```bash
frogatto --sound
```

### Build fails on Boost

If Homebrew upgrades past `boost@1.85`, the build will fail. The formula
already pins to `boost@1.85`. If you see Boost-related errors, verify:

```bash
brew list boost@1.85
```

### Other issues

The engine writes logs to stderr. To capture them:

```bash
frogatto 2>frogatto.log
```

## macOS build details

The upstream Anura build system only targets Linux (CMake). The Xcode project
in the repo is stale (references a removed `vcpkg.json`). This formula ships
an adapted CMakeLists.txt that handles the following macOS-specific issues:

1. **No librt on macOS.** The Linux build requires `find_package(RT REQUIRED)`.
   On macOS these functions are part of libc — the dependency is removed.

2. **main.cpp needs Objective-C++.** It uses `#import <Cocoa/Cocoa.h>` for
   NSBundle path resolution. The CMake project enables the `OBJCXX` language
   and compiles that file accordingly.

3. **AppleClang vs Clang compiler ID.** The engine's per-file warning
   suppression rules check for `CMAKE_CXX_COMPILER_ID STREQUAL "Clang"`, but
   Apple's compiler reports `"AppleClang"`. The build temporarily maps
   AppleClang to Clang before including the shared rules.

4. **macOS SDK headers vs -Werror.** System headers (CoreFoundation, etc.)
   trigger warnings under `-pedantic` that don't appear on Linux. The macOS
   build drops `-Werror` (the Linux CI handles warning discipline) and
   suppresses specific SDK-triggered warnings (`-Wno-nullability-extension`,
   `-Wno-variadic-macro-arguments-omitted`, etc.).

5. **Framework search order.** Systems with old x86\_64-only framework
   installs in `/Library/Frameworks/` (freetype, ogg, vorbis) need
   `CMAKE_FIND_FRAMEWORK LAST` to prefer Homebrew's arm64 libraries.

6. **Boost 1.87+ incompatibility.** Breaking changes in Boost.Asio prevent
   building with Boost 1.87 or later. The formula pins to `boost@1.85`.

## Architecture

- Anura uses its own scripting language (FFL) for game logic
- Rendering: OpenGL (deprecated on macOS but functional)
- Windowing/input: SDL2
- Audio: SDL2 raw audio API with Ogg/Vorbis decoding (not SDL\_mixer)
- The engine resolves data paths via `[[NSBundle mainBundle] resourcePath]`
  on macOS, which means the binary, engine data, and modules directory must
  be co-located
