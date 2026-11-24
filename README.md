# WiiExtract

An Android application for extracting files from Wii disc images.

WiiExtract provides a simple, dark-themed interface for extracting
ISO and RVZ disc images directly on Android devices.

## Features

- ISO and RVZ support
- Extracts game files and system data
- Exports files/, sys/ and available disc metadata
- Automatically creates a folder named after the selected image
- Works entirely offline
- Native ARM64 extraction engine

## Requirements

- Android device with ARM64 support
- Sufficient free storage for temporary files and extracted data

## How to use

1. Open WiiExtract.
2. Select a Wii ISO or RVZ image.
3. Wait for the image to be inspected.
4. Tap Extract.
5. Select a destination folder.
6. WiiExtract creates a subfolder named after the image.

## Credits

WiiExtract uses components from the Dolphin Emulator project.

https://github.com/dolphin-emu/dolphin

WiiExtract is an independent application and is not affiliated
with or endorsed by the Dolphin development team.

## Source and licensing

WiiExtract incorporates code from Dolphin Emulator, licensed under
GPL-2.0-or-later.

The source distribution must preserve applicable copyright notices,
license terms and corresponding source requirements.

## Building from source

WiiExtract has been built and tested using Termux on an
ARM64 Android device.

### Build requirements

- Termux with Clang, CMake, Ninja, Git, Python and Java
- Android SDK with platform android-35
- Android build tools providing aapt, d8, zipalign and apksigner
- Android NDK r27d sysroot and libc++ runtime
- Sufficient storage for Dolphin and its submodules

The build scripts currently assume the Termux filesystem
layout and are not yet portable to other host environments.

### Source dependencies

The build system prepares:

- Dolphin Emulator at commit
  432b41f93cc77cc261a11fd182c74c21cfbcd149
- fmt 12.2.1
- Dolphin's required Git submodules

Additional static dependencies are built from the
Dolphin source tree.

### Build

Clone this repository and enter its directory.

Prepare the required Android SDK, NDK and Termux tools.

Run:

    ./scripts/build-all.sh

The script prepares the sources, configures and builds
the native components, and packages the Android APK.

The default output is:

    build/standalone/WiiExtract-test.apk

### APK signing

The build requires a local signing keystore.

By default, the signing script looks for:

    dolphintool-debug.jks

You can specify another keystore using:

    WIIEXTRACT_KEYSTORE=/path/to/your-key.jks

The signing tool prompts for the required credentials.

Never commit private signing keys or passwords.

### Licensing

WiiExtract incorporates modified components from
Dolphin Emulator.

Dolphin source:
https://github.com/dolphin-emu/dolphin

The repository includes Dolphin-related licensing
information under licenses/.

See the corresponding source files and SPDX notices
for applicable licenses and copyright information.

The build and source distribution must comply with
the licenses of all included components.
