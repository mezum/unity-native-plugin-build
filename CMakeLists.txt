# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

cmake_minimum_required(VERSION 3.0)

add_subdirectory(ogg)
add_subdirectory(opus)
add_subdirectory(opusfile-cmake)
add_subdirectory(sqlite3-cmake)

add_library(unityplugin dummy.c)
target_link_libraries(unityplugin
	ogg
	opus
	opusfile
	sqlite3
)

install(
	TARGETS unityplugin
	ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_PREFIX}/include
)
