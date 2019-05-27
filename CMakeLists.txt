# Copyright (c) 2019 Mezumona Kosaki
# This script is released under the 2-Clause BSD License.
# See https://opensource.org/licenses/BSD-2-Clause

cmake_minimum_required(VERSION 3.0)
project(unity-native-plugin)

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
set(UNITY_PLUGIN_STATIC_FILE ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${UNITY_PLUGIN_OUTPUT_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX})
set(UNITY_PLUGIN_LIBRARIES
	ogg
	opus
	opusfile
	sqlite3
)
set(UNITY_PLUGIN_TARGET_FILE_GENERATORS "")
foreach(library IN LISTS UNITY_PLUGIN_LIBRARIES)
	add_subdirectory(${library})
	set(UNITY_PLUGIN_TARGET_FILE_GENERATORS ${UNITY_PLUGIN_TARGET_FILE_GENERATORS} "$<TARGET_FILE:${library}>")
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
	# static library
	get_filename_component(UNITY_PLUGIN_VS_BIN_DIR "${CMAKE_LINKER}" DIRECTORY)
	add_custom_target(unity-native-plugin-static ALL
		COMMAND ${UNITY_PLUGIN_VS_BIN_DIR}/LIB.exe
			/out:${UNITY_PLUGIN_STATIC_FILE}
			${UNITY_PLUGIN_TARGET_FILE_GENERATORS}
		DEPENDS ${UNITY_PLUGIN_LIBRARIES}
	)
	
	# shared library
	target_link_libraries(unity-native-plugin-shared ${UNITY_PLUGIN_LIBRARIES})
	foreach (lib in LISTS UNITY_PLUGIN_LIBRARIES)
		target_link_libraries(unity-native-plugin-shared /WHOLEARCHIVE:$<TARGET_FILE:${lib}>)
	endforeach()
elseif(CMAKE_GENERATOR STREQUAL Xcode)
	# static library
	add_custom_target(unity-native-plugin-static ALL
		COMMAND xcrun libtool -static
			-o ${UNITY_PLUGIN_STATIC_FILE}
			${UNITY_PLUGIN_TARGET_FILE_GENERATORS}
		DEPENDS ${UNITY_PLUGIN_LIBRARIES}
	)
	
	# shared library
	target_link_libraries(unity-native-plugin-shared ${UNITY_PLUGIN_LIBRARIES})
	set_target_properties(unity-native-plugin-shared
		PROPERTIES
			LINK_FLAGS "-all_load"
	)
else()
	# static library
	set(UNITY_PLUGIN_MRI ${CMAKE_CURRENT_BINARY_DIR}/merge.mri)
	set(UNITY_PLUGIN_MRI_CONTENT "create ${UNITY_PLUGIN_STATIC_FILE}\n")
	foreach (lib IN LISTS UNITY_PLUGIN_TARGET_FILE_GENERATORS)
		# file(generate ...) evaluetes generator expression.
		set(UNITY_PLUGIN_MRI_CONTENT "${UNITY_PLUGIN_MRI_CONTENT}addlib ${lib}\n")
	endforeach()
	set(UNITY_PLUGIN_MRI_CONTENT "${UNITY_PLUGIN_MRI_CONTENT}save\nend\n")
	file(GENERATE OUTPUT ${UNITY_PLUGIN_MRI} CONTENT "${UNITY_PLUGIN_MRI_CONTENT}")
	add_custom_target(unity-native-plugin-static ALL
		COMMAND ${CMAKE_AR} -M <${UNITY_PLUGIN_MRI}
		DEPENDS ${UNITY_PLUGIN_LIBRARIES}
	)
	
	# shared library
	target_link_libraries(unity-native-plugin-shared
		"-Wl,-whole-archive"
		${UNITY_PLUGIN_LIBRARIES}
		"-Wl,-no-whole-archive"
	)
endif()

# install
install(
	FILES ${UNITY_PLUGIN_STATIC_FILE}
	DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
)
install(
	TARGETS unity-native-plugin-shared
	ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
	PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_PREFIX}/include
)