#!/bin/bash

# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

# @(#)Build static/shared libraries.
# @(#)Usage:
# @(#)    source ./build.sh
# @(#)    LIBRARY_NAME="..."
# @(#)    CONFIGURE_OPTS="..."
# @(#)    [BUILD_TYPE="..."]
# @(#)    cmake_build_target <TARGET>
# @(#)
# @(#)Variables:
# @(#)    LIBRARY_NAME   ---- library name / directory
# @(#)    CONFIGURE_OPTS ---- configure options passed to cmake (default:(empty))
# @(#)    BUILD_TYPE     ---- build type passed to cmake (default:MinSizeRel)
# @(#)Arguments:
# @(#)    TARGET         ---- target platform
# @(#)        TARGET=android
# @(#)        TARGET=android_armv7
# @(#)        TARGET=android_arm64
# @(#)        TARGET=android_x86
# @(#)        TARGET=ios
# @(#)        TARGET=macos
# @(#)        TARGET=win64
# @(#)        TARGET=linux_x86_64
# @(#)        TARGET=default

# Exported constants
TOOLCHAIN_ANDROID_ARMV7=android-ndk-r16b-api-16-armeabi-v7a-thumb-clang-libcxx14
TOOLCHAIN_ANDROID_ARM64=android-ndk-r16b-api-21-arm64-v8a-neon-clang-libcxx14
TOOLCHAIN_ANDROID_X86=android-ndk-r16b-api-16-x86-clang-libcxx14
TOOLCHAIN_IOS=ios-nocodesign
TOOLCHAIN_MACOS=xcode
TOOLCHAIN_WIN64=vs-15-2017
TOOLCHAIN_LINUX_X86_64=linux-gcc-x64
TOOLCHAIN_DEFAULT=cxx11

# Exported variables
PROJ_DIR="$(cd "$(dirname "${BASH_SCRIPT:-$0}")"; pwd)"
CMAKE_TOOLCHAIN_DIR="$PROJ_DIR/polly"

# Imported variables
CONFIGURE_OPTS=""
BUILD_TYPE="MinSizeRel"

cmake_build_target()
{
	local TARGET="${1:?unspecified target}"
	shift 1
	
	local TARGET_LOWER="$(tr '[A-Z]' '[a-z]' <<< $TARGET)"
	local TARGET_UPPER="$(tr '[a-z]' '[A-Z]' <<< $TARGET)"
	case "$TARGET_LOWER" in
		"android")
			cmake_build android_armv7 static $TOOLCHAIN_ANDROID_ARMV7 "$@" || return $?
			cmake_build android_armv7 shared $TOOLCHAIN_ANDROID_ARMV7 "$@" || return $?
			cmake_build android_arm64 static $TOOLCHAIN_ANDROID_ARM64 "$@" || return $?
			cmake_build android_arm64 shared $TOOLCHAIN_ANDROID_ARM64 "$@" || return $?
			cmake_build android_x86 static $TOOLCHAIN_ANDROID_X86 "$@" || return $?
			cmake_build android_x86 shared $TOOLCHAIN_ANDROID_X86 "$@" || return $?
			;;
		"ios")
			export XCODE_XCCONFIG_FILE="$PROJ_DIR/polly/scripts/NoCodeSign.xcconfig"
			cmake_build $TARGET_LOWER static $TOOLCHAIN_IOS -GXcode "$@" || return $?
			;;
		"macos")
			cmake_build $TARGET_LOWER static $TOOLCHAIN_MACOS -GXcode "$@" || return $?
			cmake_build $TARGET_LOWER shared $TOOLCHAIN_MACOS -GXcode "$@" || return $?
			;;
		"win64")
			cmake_build $TARGET_LOWER static $TOOLCHAIN_WIN64 -G'Visual Studio 15 2017' "$@" || return $?
			cmake_build $TARGET_LOWER shared $TOOLCHAIN_WIN64 -G'Visual Studio 15 2017' "$@" || return $?
			;;
		"linux_x86_64")
			if [[ $(uname) == Linux && $(uname -m) == x86_64 ]]; then
				cmake_build $TARGET_LOWER static $TOOLCHAIN_DEFAULT "$@" || return $?
				cmake_build $TARGET_LOWER shared $TOOLCHAIN_DEFAULT "$@" || return $?
			else
				cmake_build $TARGET_LOWER static $TOOLCHAIN_LINUX_X86_64 "$@" || return $?
				cmake_build $TARGET_LOWER shared $TOOLCHAIN_LINUX_X86_64 "$@" || return $?
			fi
		*)
			local TOOLCHAIN_FILE=$(eval echo '${TOOLCHAIN_'$TARGET_UPPER'}')
			cmake_build $TARGET_LOWER static $TOOLCHAIN_FILE "$@" || return $?
			cmake_build $TARGET_LOWER shared $TOOLCHAIN_FILE "$@" || return $?
			;;
	esac
}

cmake_build()
{
	local TARGET_NAME="$1"
	local LIBRARY_TYPE="$2"
	local TOOLCHAIN_NAME="$3"
	shift 3
	
	local TOOLCHAIN="$CMAKE_TOOLCHAIN_DIR/$TOOLCHAIN_NAME.cmake"
	local SOURCE_DIR="$PROJ_DIR/$LIBRARY_NAME"
	local BUILD_DIR="$PWD/_build/$LIBRARY_NAME/$TARGET_NAME/$LIBRARY_TYPE"
	local INSTALL_PREFIX="$PWD/_lib/$LIBRARY_NAME/$TARGET_NAME"
	local BUILD_SHARED_LIBS="$([[ $LIBRARY_TYPE == shared ]] && echo ON)"
	
	mkdir -p "$BUILD_DIR"
	rm -rf "$BUILD_DIR/*"
	pushd "$BUILD_DIR" >/dev/null
	cmake "$SOURCE_DIR" \
		-DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
		-DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
		-DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
		-DBUILD_SHARED_LIBS="$BUILD_SHARED_LIBS" \
		"$@" \
		|| return $?
	cmake --build . --target install --config Release || return $?
	popd >/dev/null
	
	local BIN_DIR="$PWD/_bin/$TARGET_NAME"
	mkdir -p "$BIN_DIR"
	rm -rf "$BIN_DIR/*"
	while read LIBRARY_FILE; do
		cp -L "$LIBRARY_FILE" "$BIN_DIR"
	done < <(find "$INSTALL_PREFIX" -name *$LIBRARY_NAME.a -o -name *$LIBRARY_NAME.so -o -name *$LIBRARY_NAME.dylib -o -name *$LIBRARY_NAME.dll)
}
