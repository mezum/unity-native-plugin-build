#!/bin/bash

# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

# @(#)Build static/shared libraries.
# @(#)Usage:
# @(#)    TARGET=<TARGET_NAME> [BUILD_TYPE=<BUILD_TYPE>] ./build-ogg.sh
# @(#)<TARGET_NAME>:
# @(#)    android
# @(#)    android_armv7
# @(#)    android_arm64
# @(#)    android_x86
# @(#)    ios
# @(#)    macos
# @(#)    win64
# @(#)    linux_x86_64
# @(#)    default
# @(#)<BUILD_TYPE> (case sensitive!):
# @(#)    Debug
# @(#)    Release
# @(#)    MinSizeRel     (default)
# @(#)    RelWithDebInfo

set -u

# common variables
PROJ_DIR="$(cd "$(dirname "${BASH_SCRIPT:-$0}")"; pwd)"
CMAKE_TOOLCHAIN_DIR="$PROJ_DIR/polly"
BUILD_DIR="$PWD/_build"
INSTALL_DIR="$PWD/_install"
BIN_DIR="$PWD/_bin"
PLUGINS_DIR="$BIN_DIR/Plugins"
LIBRARY_NAME='unityplugin'

# toolchains
TOOLCHAIN_ANDROID_ARMV7="$CMAKE_TOOLCHAIN_DIR/android-ndk-r16b-api-16-armeabi-v7a-thumb-clang-libcxx14.cmake"
TOOLCHAIN_ANDROID_ARM64="$CMAKE_TOOLCHAIN_DIR/android-ndk-r16b-api-21-arm64-v8a-neon-clang-libcxx14.cmake"
TOOLCHAIN_ANDROID_X86="$CMAKE_TOOLCHAIN_DIR/android-ndk-r16b-api-16-x86-clang-libcxx14.cmake"
TOOLCHAIN_IOS="$CMAKE_TOOLCHAIN_DIR/ios-nocodesign.cmake"
TOOLCHAIN_MACOS="$CMAKE_TOOLCHAIN_DIR/xcode.cmake"
TOOLCHAIN_WIN64="$CMAKE_TOOLCHAIN_DIR/vs-15-2017.cmake"
TOOLCHAIN_LINUX_X86_64="$CMAKE_TOOLCHAIN_DIR/linux-gcc-x64.cmake"
TOOLCHAIN_DEFAULT="$CMAKE_TOOLCHAIN_DIR/cxx11.cmake"

# License files
LICENSE_FILES="$(cat <<- __EOL__
	${PROJ_DIR}/ogg/COPYING	$BIN_DIR/COPYING-ogg
	${PROJ_DIR}/opus/COPYING	$BIN_DIR/COPYING-opus
	${PROJ_DIR}/opusfile-src/COPYING	$BIN_DIR/COPYING-opusfile
__EOL__
)"

# arguments
TARGET="${TARGET:?unspecified target}"
BUILD_TYPE="${BUILD_TYPE:-MinSizeRel}"

__main__()
{
	local TARGET_LOWER="$(tr '[A-Z]' '[a-z]' <<< $TARGET)"
	local TARGET_UPPER="$(tr '[a-z]' '[A-Z]' <<< $TARGET)"
	case "$TARGET_LOWER" in
		"android")
			cmake_build android_armv7 "$TOOLCHAIN_ANDROID_ARMV7" "$@" || return $?
			cmake_build android_arm64 "$TOOLCHAIN_ANDROID_ARM64" "$@" || return $?
			cmake_build android_x86 "$TOOLCHAIN_ANDROID_X86" "$@" || return $?
			;;
		"ios")
			export XCODE_XCCONFIG_FILE="$PROJ_DIR/polly/scripts/NoCodeSign.xcconfig"
			cmake_build iOS "$TOOLCHAIN_IOS" -GXcode -DIOS_DEPLOYMENT_SDK_VERSION=9.0 "$@" || return $?
			;;
		"macos")
			cmake_build macOS_x86_64 "$TOOLCHAIN_MACOS" -GXcode "$@" || return $?
			;;
		"win64")
			cmake_build Windows_x86_64 "$TOOLCHAIN_WIN64" -G'Visual Studio 15 2017' "$@" || return $?
			;;
		"linux_x86_64")
			if [[ $(uname) == Linux && $(uname -m) == x86_64 ]]; then
				cmake_build Linux_x86_64 "$TOOLCHAIN_DEFAULT" "$@" || return $?
			else
				cmake_build Linux_x86_64 "$TOOLCHAIN_LINUX_X86_64" "$@" || return $?
			fi
			;;
		*)
			local TOOLCHAIN_FILE=$(eval echo '${TOOLCHAIN_'$TARGET_UPPER'}')
			cmake_build $TARGET_LOWER "$TOOLCHAIN_FILE" "$@" || return $?
			;;
	esac
	
	# license files
	while read src dst; do
		mkdir -p "$(dirname "$dst")" || return $?
		cp "$src" "$dst" || return $?
	done < <(echo "$LICENSE_FILES")
}

cmake_build()
{
	local SUBDIR="$1"
	local CMAKE_TOOLCHAIN_FILE="$2"
	shift 2

	local CMAKE_BUILD_DIR="$BUILD_DIR/$SUBDIR"
	local CMAKE_INSTALL_PREFIX="$INSTALL_DIR/$SUBDIR"
	local OUTPUT_DIR="$BIN_DIR/$SUBDIR"
	
	rm -rf "$CMAKE_BUILD_DIR" "$CMAKE_INSTALL_PREFIX" "$OUTPUT_DIR"
	mkdir -p "$CMAKE_BUILD_DIR" "$CMAKE_INSTALL_PREFIX" "$OUTPUT_DIR"
	
	pushd "$CMAKE_BUILD_DIR" >/dev/null 2>/dev/null
	cmake "$PROJ_DIR" \
		-DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
		-DCMAKE_INSTALL_PREFIX="$CMAKE_INSTALL_PREFIX" \
		-DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
		"$@" \
		|| return $?
	cmake --build . --target install --config Release || return $?
	popd >/dev/null 2>/dev/null
	
	while read LIBRARY_FILE; do
		local FILE_NAME_EXT="$(basename "$LIBRARY_FILE")"
		local FILE_EXT="${FILE_NAME_EXT##*.}"
		local FILE_NAME="${FILE_NAME_EXT%.*}"
	
		local FILE_EXT_FIX="$FILE_EXT"
		if [[ $FILE_EXT == dylib ]]; then
			FILE_NAME="${FILE_NAME:3}"
			FILE_EXT_FIX="bundle"
		fi
	
		cp -L "$LIBRARY_FILE" "$OUTPUT_DIR/$FILE_NAME.$FILE_EXT_FIX" || return $?
	done < <(
		find "$CMAKE_INSTALL_PREFIX/lib" \
			-iname "lib*.a" \
			-o -iname "lib*.so" \
			-o -iname "lib*.dylib" \
			-o -iname "*.lib" \
			-o -iname "*.dll"
	)
}

__main__ "$@"
