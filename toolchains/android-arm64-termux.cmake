set(CMAKE_SYSTEM_NAME Android)
set(CMAKE_SYSTEM_VERSION 24)
set(CMAKE_ANDROID_ARCH_ABI arm64-v8a)

set(NDK_ROOT "$ENV{HOME}/android-ndk/android-ndk-r27d")
set(NDK_SYSROOT "${NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/sysroot")

set(CMAKE_SYSROOT "${NDK_SYSROOT}")

set(CMAKE_C_COMPILER "$ENV{PREFIX}/bin/clang")
set(CMAKE_CXX_COMPILER "$ENV{PREFIX}/bin/clang++")

set(CMAKE_C_COMPILER_TARGET aarch64-linux-android24)
set(CMAKE_CXX_COMPILER_TARGET aarch64-linux-android24)

set(CMAKE_AR "$ENV{PREFIX}/bin/llvm-ar")
set(CMAKE_RANLIB "$ENV{PREFIX}/bin/llvm-ranlib")

set(CMAKE_CXX_FLAGS_INIT
    "-nostdinc++ -nostdlib++ -unwindlib=none -isystem ${NDK_SYSROOT}/usr/include/c++/v1")

set(CMAKE_EXE_LINKER_FLAGS_INIT
    "-unwindlib=none -L${NDK_SYSROOT}/usr/lib/aarch64-linux-android/24 -lc++_shared")

set(CMAKE_SHARED_LINKER_FLAGS_INIT
    "-unwindlib=none -L${NDK_SYSROOT}/usr/lib/aarch64-linux-android/24 -lc++_shared")

set(CMAKE_FIND_ROOT_PATH "${NDK_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_SKIP_RPATH TRUE)
set(CMAKE_SKIP_BUILD_RPATH TRUE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH "")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)

set(CMAKE_SKIP_RPATH TRUE CACHE BOOL "" FORCE)
set(CMAKE_SKIP_BUILD_RPATH TRUE CACHE BOOL "" FORCE)
