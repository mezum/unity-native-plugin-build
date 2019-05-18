#!/bin/bash

# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

# @(#)Build ogg static/shared library.
# @(#)Usage:
# @(#)    TARGET=<TARGET_NAME> ./build-ogg.sh
# @(#)See ./build.sh to more detail.

source ./build.sh

LIBRARY_NAME=ogg
CONFIGURE_OPTS="
	-DINSTALL_DOCS=NO
	-DINSTALL_PKG_CONFIG_MODULE=NO
	-DINSTALL_CMAKE_PACKAGE_MODULE=NO
	$CONFIGURE_OPTS
"
cmake_build_target $TARGET || exit $1
cp "$PROJ_DIR/$LIBRARY_NAME/COPYING" "$PWD/_bin/LICENSE-$LIBRARY_NAME"