#!/bin/bash

# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

# @(#)Build opus static/shared libraries.
# @(#)Usage:
# @(#)    TARGET=<TARGET_NAME> ./build-ogg.sh
# @(#)See ./build.sh to more detail.

source ./build.sh

LIBRARY_NAME=opus
CONFIGURE_OPTS="
	-DOPUS_INSTALL_PKG_CONFIG_MODULE=NO
	-DOPUS_INSTALL_CMAKE_CONFIG_MODULE=NO
	-DOPUS_STACK_PROTECTOR=NO
	-DOPUS_FIXED_POINT=YES
	-DOPUS_ENABLE_FLOAT_API=YES
	$CONFIGURE_OPTS
"
cmake_build_target $TARGET || exit $1
cp "$PROJ_DIR/$LIBRARY_NAME/COPYING" "$PWD/_bin/LICENSE-$LIBRARY_NAME"