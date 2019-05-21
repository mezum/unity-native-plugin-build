# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

cmake_minimum_required(VERSION 2.8)
project(sqlite3 LANGUAGES C)

option(
	SQLITE_THREADSAFE
	"Enables the mutex and thread-safety logic."
	ON
)
option(
	SQLITE_DEFAULT_MEMSTATUS
	"Enables 'sqlite3_status' tracks memory usage."
	ON
)
option(
	SQLITE_DEFAULT_WAL_SYNCHRONOUS
	"Changes default synchronous mode from FULL to NORMAL which is convenient in Write-Ahead-Log open mode."
	OFF
)
option(
	SQLITE_LIKE_DOESNT_MATCH_BLOBS
	"Omits the LIKE and BLOB SQL operators for a BLOB column."
	OFF
)
option(
	SQLITE_OMIT_DECLTYPE
	"Omits the ability to return the declared type of columns from the result set of query."
	OFF
)
option(
	SQLITE_OMIT_SHARED_CACHE
	"Omits possibility of using shared cache."
	OFF
)
option(
	SQLITE_USE_ALLOCA
	"Enables to use alloca() for dynamically allocation temporary stack space if the systems supports alloca()."
	OFF
)

set(SQLITE3_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../sqlite3)

set(SQLITE3_HEADER
	${SQLITE3_ROOT}/sqlite3.h
	${SQLITE3_ROOT}/sqlite3ext.h
)

set(SQLITE3_SOURCE
	${SQLITE3_ROOT}/sqlite3.c
)

add_library(sqlite3 ${SQLITE3_HEADER} ${SQLITE3_SOURCE})
target_include_directories(sqlite3
	PUBLIC
		${SQLITE3_ROOT}/src
)
set_target_properties(sqlite3
	PROPERTIES
		PUBLIC_HEADER "${SQLITE3_HEADER}"
)

if(!SQLITE_THREADSAFE)
	target_compile_definitions(sqlite3 PRIVATE SQLITE_THREADSAFE=0)
endif()

if(!SQLITE_DEFAULT_MEMSTATUS)
	target_compile_definitions(sqlite3 PRIVATE SQLITE_DEFAULT_MEMSTATUS=0)
endif()

if(SQLITE_DEFAULT_WAL_SYNCHRONOUS)
	target_compile_definitions(sqlite3 PRIVATE SQLITE_DEFAULT_WAL_SYNCHRONOUS=1)
endif()

if(SQLITE_LIKE_DOESNT_MATCH_BLOBS)
	target_compile_definitions(sqlite3 PRIVATE SQLITE_LIKE_DOESNT_MATCH_BLOBS)
endif()

if(SQLITE_OMIT_DECLTYPE)
	target_compile_definitions(sqlite3 PRIVATE SQLITE_OMIT_DECLTYPE)
endif()

if(SQLITE_OMIT_SHARED_CACHE)
	target_compile_definitions(sqlite3 PRIVATE SQLITE_OMIT_SHARED_CACHE)
endif()

if(SQLITE_USE_ALLOCA)
	target_compile_definitions(sqlite3 PRIVATE SQLITE_USE_ALLOCA)
endif()

install(
	TARGETS sqlite3
	ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_PREFIX}/include
)
