# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

cmake_minimum_required(VERSION 2.8)
project(opusfile LANGUAGES C)

option(
	OP_FIXED_POINT
	"Compile as fixed-point"
	OFF
)

set(OPUSFILE_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../opusfile-src)

set(OPUSFILE_HEADER
	${OPUSFILE_ROOT}/include/opusfile.h
)

set(OPUSFILE_SOURCE
	${OPUSFILE_ROOT}/src/info.c
	${OPUSFILE_ROOT}/src/internal.c
	${OPUSFILE_ROOT}/src/opusfile.c
	${OPUSFILE_ROOT}/src/stream.c
)

set(OPUSFILE_DEPENDENCIES
	ogg
	opus
)

add_library(opusfile ${OPUSFILE_HEADER} ${OPUSFILE_SOURCE})
target_link_libraries(opusfile ${OPUSFILE_DEPENDENCIES})
target_include_directories(opusfile
	PRIVATE
		${OPUSFILE_ROOT}/src
	PUBLIC
		${OPUSFILE_ROOT}/include
)
set_target_properties(opusfile
	PROPERTIES
		PUBLIC_HEADER "${OPUSFILE_HEADER}"
)

if(OP_FIXED_POINT)
	target_compile_definitions(opusfile PRIVATE OP_FIXED_POINT=1)
endif()

install(
	TARGETS opusfile
	ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_PREFIX}/include
)
