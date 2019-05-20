#!/bin/bash

# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

# @(#)Build static/shared libraries.
# @(#)Usage:
# @(#)    TARGET=<TARGET_NAME> [BUILD_TYPE="..."] ./build-ogg.sh
# @(#)TARGET_NAME:
# @(#)    android
# @(#)    android_armv7
# @(#)    android_arm64
# @(#)    android_x86
# @(#)    ios
# @(#)    macos
# @(#)    win64
# @(#)    linux_x86_64
# @(#)    default
# @(#)BUILD_TYPE(case sensitive):
# @(#)    Debug
# @(#)    Release
# @(#)    MinSizeRel
# @(#)    RelWithDebInfo

# common variables
PROJ_DIR="$(cd "$(dirname "${BASH_SCRIPT:-$0}")"; pwd)"
CMAKE_TOOLCHAIN_DIR="$PROJ_DIR/polly"

# toolchains
TOOLCHAIN_ANDROID_ARMV7=$CMAKE_TOOLCHAIN_DIR/android-ndk-r16b-api-16-armeabi-v7a-thumb-clang-libcxx14.cmake
TOOLCHAIN_ANDROID_ARM64=$CMAKE_TOOLCHAIN_DIR/android-ndk-r16b-api-21-arm64-v8a-neon-clang-libcxx14.cmake
TOOLCHAIN_ANDROID_X86=$CMAKE_TOOLCHAIN_DIR/android-ndk-r16b-api-16-x86-clang-libcxx14.cmake
TOOLCHAIN_IOS=$CMAKE_TOOLCHAIN_DIR/ios-nocodesign.cmake
TOOLCHAIN_MACOS=$CMAKE_TOOLCHAIN_DIR/xcode.cmake
TOOLCHAIN_WIN64=$CMAKE_TOOLCHAIN_DIR/vs-15-2017.cmake
TOOLCHAIN_LINUX_X86_64=$CMAKE_TOOLCHAIN_DIR/linux-gcc-x64.cmake
TOOLCHAIN_DEFAULT=$CMAKE_TOOLCHAIN_DIR/cxx11.cmake

# library list
LIBRARIES="
	ogg
	opus
"

# libogg config
CONFIGURE_OPTS_OGG=""

# libopus config
CONFIGURE_OPTS_OPUS="
	-DOPUS_INSTALL_PKG_CONFIG_MODULE=NO
	-DOPUS_INSTALL_CMAKE_CONFIG_MODULE=NO
	-DOPUS_STACK_PROTECTOR=NO
	-DOPUS_FIXED_POINT=YES
	-DOPUS_ENABLE_FLOAT_API=YES
"


# arguments
TARGET="${TARGET:?unspecified target}"
BUILD_TYPE="${BUILD_TYPE:-MinSizeRel}"

__main__()
{
	local CONFIGURE_OPTS=
	while read LIB; do
		local LIB_UPPER="$(tr '[a-z]' '[A-Z]' <<< $LIB)"
		CONFIGURE_OPTS="$CONFIGURE_OPTS $(eval echo '${CONFIGURE_OPTS_'$LIB_UPPER'}')"
	done < <(echo "$LIBRARIES")
	
	local TARGET_LOWER="$(tr '[A-Z]' '[a-z]' <<< $TARGET)"
	local TARGET_UPPER="$(tr '[a-z]' '[A-Z]' <<< $TARGET)"
	case "$TARGET_LOWER" in
		"android")
			cmake_build android_armv7 static "$TOOLCHAIN_ANDROID_ARMV7" $CONFIGURE_OPTS "$@" || return $?
			cmake_build android_armv7 shared "$TOOLCHAIN_ANDROID_ARMV7" $CONFIGURE_OPTS "$@" || return $?
			cmake_build android_arm64 static "$TOOLCHAIN_ANDROID_ARM64" $CONFIGURE_OPTS "$@" || return $?
			cmake_build android_arm64 shared "$TOOLCHAIN_ANDROID_ARM64" $CONFIGURE_OPTS "$@" || return $?
			cmake_build android_x86 static "$TOOLCHAIN_ANDROID_X86" $CONFIGURE_OPTS "$@" || return $?
			cmake_build android_x86 shared "$TOOLCHAIN_ANDROID_X86" $CONFIGURE_OPTS "$@" || return $?
			;;
		"ios")
			export XCODE_XCCONFIG_FILE="$PROJ_DIR/polly/scripts/NoCodeSign.xcconfig"
			cmake_build $TARGET_LOWER static "$TOOLCHAIN_IOS" -GXcode $CONFIGURE_OPTS "$@" || return $?
			;;
		"macos")
			cmake_build $TARGET_LOWER static "$TOOLCHAIN_MACOS" -GXcode $CONFIGURE_OPTS "$@" || return $?
			cmake_build $TARGET_LOWER shared "$TOOLCHAIN_MACOS" -GXcode $CONFIGURE_OPTS "$@" || return $?
			;;
		"win64")
			cmake_build $TARGET_LOWER static "$TOOLCHAIN_WIN64" -G'Visual Studio 15 2017' $CONFIGURE_OPTS "$@" || return $?
			cmake_build $TARGET_LOWER shared "$TOOLCHAIN_WIN64" -G'Visual Studio 15 2017' $CONFIGURE_OPTS "$@" || return $?
			;;
		"linux_x86_64")
			if [[ $(uname) == Linux && $(uname -m) == x86_64 ]]; then
				cmake_build $TARGET_LOWER static "$TOOLCHAIN_DEFAULT" $CONFIGURE_OPTS "$@" || return $?
				cmake_build $TARGET_LOWER shared "$TOOLCHAIN_DEFAULT" $CONFIGURE_OPTS "$@" || return $?
			else
				cmake_build $TARGET_LOWER static "$TOOLCHAIN_LINUX_X86_64" $CONFIGURE_OPTS "$@" || return $?
				cmake_build $TARGET_LOWER shared "$TOOLCHAIN_LINUX_X86_64" $CONFIGURE_OPTS "$@" || return $?
			fi
			;;
		*)
			local TOOLCHAIN_FILE=$(eval echo '${TOOLCHAIN_'$TARGET_UPPER'}')
			cmake_build $TARGET_LOWER static "$TOOLCHAIN_FILE" $CONFIGURE_OPTS "$@" || return $?
			cmake_build $TARGET_LOWER shared "$TOOLCHAIN_FILE" $CONFIGURE_OPTS "$@" || return $?
			;;
	esac
	
	# license
	cp "${PROJ_DIR}/ogg/COPYING" "_bin/LICENSE-ogg"
	cp "${PROJ_DIR}/opus/COPYING" "_bin/LICENSE-opus"
}

cmake_build()
{
	local TARGET_NAME="$1"
	local LIBRARY_TYPE="$2"
	local TOOLCHAIN="$3"
	shift 3
	
	local INSTALL_PREFIX="$PWD/_lib/$TARGET_NAME"
	local BUILD_SHARED_LIBS="$([[ $LIBRARY_TYPE == shared ]] && echo ON)"

	local BUILD_DIR="$PWD/_build/$TARGET_NAME/$LIBRARY_TYPE"
	mkdir -p "$BUILD_DIR"
	rm -rf "$BUILD_DIR/*"
	pushd "$BUILD_DIR" >/dev/null 2>/dev/null
	cmake "$PROJ_DIR" \
		$CONFIGURE_OPTS \
		-DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
		-DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
		-DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
		-DBUILD_SHARED_LIBS="$BUILD_SHARED_LIBS" \
		"$@" \
		|| return $?
	cmake --build . --target install --config Release || return $?
	popd >/dev/null 2>/dev/null
	
	local BIN_DIR="$PWD/_bin/$TARGET_NAME"
	mkdir -p "$BIN_DIR"
	rm -rf "$BIN_DIR/*"
	while read LIBRARY_FILE; do
		local FILE_NAME_EXT="$(basename "$LIBRARY_FILE")"
		local FILE_EXT="${FILE_NAME_EXT##*.}"
		local FILE_NAME="${FILE_NAME_EXT%.*}"
		
		local FILE_EXT_FIX="$FILE_EXT"
		if [[ $FILE_EXT == dylib ]]; then
			FILE_EXT_FIX="bundle"
		fi
		
		cp -L "$LIBRARY_FILE" "$BIN_DIR/$FILE_NAME.$FILE_EXT_FIX"
	done < <(find -E "$INSTALL_PREFIX" -iregex '[^.]+\.(a|so|dylib|lib|dll)')
}

__main__ "$@"
