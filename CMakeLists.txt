# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

cmake_minimum_required(VERSION 3.0)

add_subdirectory(ogg)
# FIXME: wait for libogg's CMakeLists.txt fix.
target_include_directories(ogg
	PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR}/ogg/include
)
add_subdirectory(opus)
add_subdirectory(opusfile-cmake)
