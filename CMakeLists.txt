# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

cmake_minimum_required(VERSION 3.0)
project(unity-native-plugin)

# check required definitions for unity plugin.
if (NOT DEFINED UNITY_PLUGIN_INSTALL_PREFIX)
	message(FATAL_ERROR "must define UNITY_PLUGIN_INSTALL_PREFIX.")
endif()

# definition for modules.
option(OPUS_INSTALL_PKG_CONFIG_MODULE "" NO)
option(OPUS_INSTALL_CMAKE_CONFIG_MODULE "" NO)
option(OPUS_STACK_PROTECTOR "" NO)
option(OPUS_FIXED_POINT "" YES)
option(OPUS_ENABLE_FLOAT_API "" YES)
option(OP_FIXED_POINT "" YES)
option(SQLITE_THREADSAFE "" YES)
option(SQLITE_DEFAULT_MEMSTATUS "" NO)
option(SQLITE_DEFAULT_WAL_SYNCHRONOUS "" YES)
option(SQLITE_LIKE_DOESNT_MATCH_BLOBS "" YES)
option(SQLITE_OMIT_DECLTYPE "" YES)
option(SQLITE_OMIT_SHARED_CACHE "" YES)
option(SQLITE_USE_ALLOCA "" YES)

# properties for unity native plugin
set(UNITY_PLUGIN_OUTPUT_NAME unityplugin)
set(UNITY_PLUGIN_LIBRARIES
	ogg
	opus
	opusfile
	sqlite3
)

# generates variables for unity native plugin
set(UNITY_PLUGIN_STATIC_FILE ${UNITY_PLUGIN_INSTALL_PREFIX}/${CMAKE_STATIC_LIBRARY_PREFIX}${UNITY_PLUGIN_OUTPUT_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX})
set(UNITY_PLUGIN_SUB_STATIC_FILE_GENERATORS)
foreach(library IN LISTS UNITY_PLUGIN_LIBRARIES)
	add_subdirectory(${library})
	set(UNITY_PLUGIN_SUB_STATIC_FILE_GENERATORS
		${UNITY_PLUGIN_SUB_STATIC_FILE_GENERATORS}
		$<TARGET_FILE:${library}>
	)
	if(IOS)
		set_target_properties(${library}
			PROPERTIES
				XCODE_ATTRIBUTE_ENABLE_BITCODE YES
				XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE bitcode
				XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE[variant=Debug] marker
		)
	endif()
endforeach()

# make shared library target
add_library(unity-native-plugin-shared SHARED dummy.c)
set_target_properties(unity-native-plugin-shared ${UNITY_PLUGIN_LIBRARIES}
	PROPERTIES
		OUTPUT_NAME ${UNITY_PLUGIN_OUTPUT_NAME}
		POSITION_INDEPENDENT_CODE ON
)

# platform-dependent configuration
if (MSVC AND NOT ANDROID)
	# shared library
	target_link_libraries(unity-native-plugin-shared ${UNITY_PLUGIN_LIBRARIES})
	foreach (lib IN LISTS UNITY_PLUGIN_LIBRARIES)
		target_link_libraries(unity-native-plugin-shared -WHOLEARCHIVE:$<TARGET_FILE:${lib}>)
	endforeach()
	
	# static library
	get_filename_component(UNITY_PLUGIN_VS_BIN_DIR "${CMAKE_LINKER}" DIRECTORY)
	add_custom_target(unity-native-plugin-static ALL
		COMMAND
			${UNITY_PLUGIN_VS_BIN_DIR}/LIB.exe
			/out:${UNITY_PLUGIN_STATIC_FILE}
			${UNITY_PLUGIN_SUB_STATIC_FILE_GENERATORS}
		DEPENDS
			${UNITY_PLUGIN_LIBRARIES}
	)
elseif(CMAKE_GENERATOR STREQUAL Xcode)
	# shared library
	target_link_libraries(unity-native-plugin-shared ${UNITY_PLUGIN_LIBRARIES})
	set_target_properties(unity-native-plugin-shared
		PROPERTIES
			LINK_FLAGS "-all_load"
	)
	
	# static library
	add_custom_target(unity-native-plugin-static ALL
		COMMAND
			xcrun libtool
			-static
			-o ${UNITY_PLUGIN_STATIC_FILE}
			${UNITY_PLUGIN_SUB_STATIC_FILE_GENERATORS}
		DEPENDS
			${UNITY_PLUGIN_LIBRARIES}
	)
else()
	# shared library
	target_link_libraries(unity-native-plugin-shared
		"-Wl,-whole-archive"
		${UNITY_PLUGIN_LIBRARIES}
		"-Wl,-no-whole-archive"
	)
	
	# static library
	set(UNITY_PLUGIN_MRI ${CMAKE_CURRENT_BINARY_DIR}/merge.mri)
	set(UNITY_PLUGIN_MRI_CONTENT "create ${UNITY_PLUGIN_STATIC_FILE}\n")
	foreach (lib IN LISTS UNITY_PLUGIN_SUB_STATIC_FILE_GENERATORS)
		set(UNITY_PLUGIN_MRI_CONTENT "${UNITY_PLUGIN_MRI_CONTENT}addlib ${lib}\n")
	endforeach()
	set(UNITY_PLUGIN_MRI_CONTENT "${UNITY_PLUGIN_MRI_CONTENT}save\nend\n")
	file(GENERATE OUTPUT ${UNITY_PLUGIN_MRI} CONTENT "${UNITY_PLUGIN_MRI_CONTENT}")
	add_custom_target(unity-native-plugin-static ALL
		COMMAND
			${CMAKE_AR} -M < ${UNITY_PLUGIN_MRI}
		DEPENDS
			${UNITY_PLUGIN_LIBRARIES}
	)
endif()

# install
install(
	TARGETS unity-native-plugin-shared
	ARCHIVE DESTINATION ${UNITY_PLUGIN_INSTALL_PREFIX}
	LIBRARY DESTINATION ${UNITY_PLUGIN_INSTALL_PREFIX}
	RUNTIME DESTINATION ${UNITY_PLUGIN_INSTALL_PREFIX}
)