function(detect_operating_system)
	message(STATUS "CMake Version: ${CMAKE_VERSION}")
	message(STATUS "CMake System Name: ${CMAKE_SYSTEM_NAME}")

	# LINUX wasn't added until CMake 3.25.
	if (CMAKE_VERSION VERSION_LESS 3.25.0 AND CMAKE_SYSTEM_NAME MATCHES "Linux")
		# Have to make it visible in this scope as well for below.
		set(LINUX TRUE PARENT_SCOPE)
		set(LINUX TRUE)
	endif()

	if(WIN32)
		message(STATUS "Building for Windows.")
	elseif(APPLE AND NOT IOS)
		message(STATUS "Building for MacOS.")
	elseif(CMAKE_SYSTEM_NAME STREQUAL "iOS")
		message(STATUS "Building for iOS.")
	elseif(LINUX)
		message(STATUS "Building for Linux.")
	elseif(BSD)
		message(STATUS "Building for *BSD.")
	else()
		message(STATUS "Building for unknown platform: ${CMAKE_SYSTEM_NAME}")
	endif()
endfunction()

function(detect_compiler)
	if(MSVC AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
		set(USE_CLANG_CL TRUE PARENT_SCOPE)
		set(IS_SUPPORTED_COMPILER TRUE PARENT_SCOPE)
		message(STATUS "Building with Clang-CL.")
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
		set(USE_CLANG TRUE PARENT_SCOPE)
		set(IS_SUPPORTED_COMPILER TRUE PARENT_SCOPE)
		message(STATUS "Building with Clang/LLVM.")
	elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		set(USE_GCC TRUE PARENT_SCOPE)
		set(IS_SUPPORTED_COMPILER FALSE PARENT_SCOPE)
		message(STATUS "Building with GNU GCC.")
	elseif(MSVC)
		set(IS_SUPPORTED_COMPILER TRUE PARENT_SCOPE)
		message(STATUS "Building with MSVC.")
	else()
		message(STATUS "Unknown compiler: ${CMAKE_CXX_COMPILER_ID} — continuing anyway.")
		set(IS_SUPPORTED_COMPILER FALSE PARENT_SCOPE)
	endif()
endfunction()

function(get_git_version_info)
	set(PCSX2_GIT_REV "")
	set(PCSX2_GIT_TAG "")
	set(PCSX2_GIT_HASH "")
	if (GIT_FOUND AND EXISTS ${PROJECT_SOURCE_DIR}/.git)
		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} describe --tags
			OUTPUT_VARIABLE PCSX2_GIT_REV
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)

		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} tag --points-at HEAD --sort=version:refname
			OUTPUT_VARIABLE PCSX2_GIT_TAG_LIST
			RESULT_VARIABLE TAG_RESULT
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)

		if(PCSX2_GIT_TAG_LIST AND TAG_RESULT EQUAL 0)
			string(REPLACE "\n" ";" PCSX2_GIT_TAG_LIST "${PCSX2_GIT_TAG_LIST}")
			if (PCSX2_GIT_TAG_LIST)
				list(GET PCSX2_GIT_TAG_LIST -1 PCSX2_GIT_TAG)
				message("Using tag: ${PCSX2_GIT_TAG}")
			endif()
		endif()

		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
			OUTPUT_VARIABLE PCSX2_GIT_HASH
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)

		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} log -1 --format=%cd --date=local
			OUTPUT_VARIABLE PCSX2_GIT_DATE
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)
	endif()
	if (NOT PCSX2_GIT_REV)
		EXECUTE_PROCESS(WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
			OUTPUT_VARIABLE PCSX2_GIT_REV
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)
		if (NOT PCSX2_GIT_REV)
			set(PCSX2_GIT_REV "Unknown")
		endif()
	endif()

	set(PCSX2_GIT_REV "${PCSX2_GIT_REV}" PARENT_SCOPE)
	set(PCSX2_GIT_TAG "${PCSX2_GIT_TAG}" PARENT_SCOPE)
	set(PCSX2_GIT_HASH "${PCSX2_GIT_HASH}" PARENT_SCOPE)
	set(PCSX2_GIT_DATE "${PCSX2_GIT_DATE}" PARENT_SCOPE)
endfunction()

function(write_svnrev_h)
	if ("${PCSX2_GIT_TAG}" MATCHES "^v([0-9]+)\\.([0-9]+)\\.([0-9]+)$")
		file(WRITE ${CMAKE_BINARY_DIR}/common/include/svnrev.h
			"#define GIT_TAG \"${PCSX2_GIT_TAG}\"\n"
			"#define GIT_TAGGED_COMMIT 1\n"
			"#define GIT_TAG_HI  ${CMAKE_MATCH_1}\n"
			"#define GIT_TAG_MID ${CMAKE_MATCH_2}\n"
			"#define GIT_TAG_LO  ${CMAKE_MATCH_3}\n"
			"#define GIT_REV \"${PCSX2_GIT_TAG}\"\n"
			"#define GIT_HASH \"${PCSX2_GIT_HASH}\"\n"
			"#define GIT_DATE \"${PCSX2_GIT_DATE}\"\n"
		)
	elseif ("${PCSX2_GIT_REV}" MATCHES "^v([0-9]+)\\.([0-9]+)\\.([0-9]+)")
		file(WRITE ${CMAKE_BINARY_DIR}/common/include/svnrev.h
			"#define GIT_TAG \"${PCSX2_GIT_TAG}\"\n"
			"#define GIT_TAGGED_COMMIT 0\n"
			"#define GIT_TAG_HI  ${CMAKE_MATCH_1}\n"
			"#define GIT_TAG_MID ${CMAKE_MATCH_2}\n"
			"#define GIT_TAG_LO  ${CMAKE_MATCH_3}\n"
			"#define GIT_REV \"${PCSX2_GIT_REV}\"\n"
			"#define GIT_HASH \"${PCSX2_GIT_HASH}\"\n"
			"#define GIT_DATE \"${PCSX2_GIT_DATE}\"\n"
		)
	else()
		file(WRITE ${CMAKE_BINARY_DIR}/common/include/svnrev.h
			"#define GIT_TAG \"${PCSX2_GIT_TAG}\"\n"
			"#define GIT_TAGGED_COMMIT 0\n"
			"#define GIT_TAG_HI 0\n"
			"#define GIT_TAG_MID 0\n"
			"#define GIT_TAG_LO 0\n"
			"#define GIT_REV \"${PCSX2_GIT_REV}\"\n"
			"#define GIT_HASH \"${PCSX2_GIT_HASH}\"\n"
			"#define GIT_DATE \"${PCSX2_GIT_DATE}\"\n"
		)
	endif()
endfunction()

function(check_no_parenthesis_in_path)
	if ("${CMAKE_BINARY_DIR}" MATCHES "[()]" OR "${CMAKE_SOURCE_DIR}" MATCHES "[()]")
		message(FATAL_ERROR "Your path contains some parenthesis. Unfortunately Cmake doesn't support them correctly.\nPlease rename your directory to avoid '(' and ')' characters\n")
	endif()
endfunction()

# like add_library(new ALIAS old) but avoids issues on older cmake
function(alias_library new old)
	string(REPLACE "::" "" library_no_namespace ${old})
	if (NOT TARGET _alias_${library_no_namespace})
		add_library(_alias_${library_no_namespace} INTERFACE)
		target_link_libraries(_alias_${library_no_namespace} INTERFACE ${old})
	endif()
	add_library(${new} ALIAS _alias_${library_no_namespace})
endfunction()

function(source_groups_from_vcxproj_filters file)
	file(READ "${file}" filecontent)
	get_filename_component(parent "${file}" DIRECTORY)
	if (parent STREQUAL "")
		set(parent ".")
	endif()
	set(regex "<[^ ]+ Include=\"([^\"]+)\">[ \t\r\n]+<Filter>([^<]+)<\\/Filter>[ \t\r\n]+<\\/[^ >]+>")
	string(REGEX MATCHALL "${regex}" filterstrings "${filecontent}")
	foreach(filterstring IN LISTS filterstrings)
		string(REGEX REPLACE "${regex}" "\\1" path "${filterstring}")
		string(REGEX REPLACE "${regex}" "\\2" group "${filterstring}")
		source_group("${group}" FILES "${parent}/${path}")
	endforeach()
endfunction()

function(fixup_file_properties target)
	get_target_property(SOURCES ${target} SOURCES)
	if(APPLE)
		foreach(source IN LISTS SOURCES)
			if("${source}" MATCHES "\\.(inl|h)$")
				set_source_files_properties("${source}" PROPERTIES XCODE_EXPLICIT_FILE_TYPE sourcecode.cpp.h)
			endif()
			if("${source}" MATCHES "\\.(qm)$")
				set_source_files_properties("${source}" PROPERTIES XCODE_EXPLICIT_FILE_TYPE compiled)
			endif()
			if("${source}" MATCHES "\\.mm$")
				set_source_files_properties("${source}" PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
			endif()
		endforeach()
	endif()
endfunction()

function(disable_compiler_warnings_for_target target)
	if(MSVC)
		target_compile_options(${target} PRIVATE "/W0")
	else()
		target_compile_options(${target} PRIVATE "-w")
	endif()
endfunction()

function(get_recursive_include_directories output target inc_prop link_prop)
	get_target_property(dirs ${target} ${inc_prop})
	if(NOT dirs)
		set(dirs)
	endif()
	get_target_property(deps ${target} ${link_prop})
	if(deps)
		foreach(dep IN LISTS deps)
			if(TARGET ${dep})
				get_recursive_include_directories(depdirs ${dep} INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES)
				foreach(depdir IN LISTS depdirs)
					if(depdir MATCHES "^/")
						list(APPEND dirs ${depdir})
					endif()
				endforeach()
			endif()
		endforeach()
		list(REMOVE_DUPLICATES dirs)
	endif()
	set(${output} "${dirs}" PARENT_SCOPE)
endfunction()

function(force_include_last_impl target include inc_prop link_prop)
	get_recursive_include_directories(dirs ${target} ${inc_prop} ${link_prop})
	set(remove)
	foreach(dir IN LISTS dirs)
		if("${dir}" MATCHES "${include}")
			list(APPEND remove ${dir})
		endif()
	endforeach()
	if(NOT "${remove}" STREQUAL "")
		get_target_property(sysdirs ${target} INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
		if(NOT sysdirs)
			set(sysdirs)
		endif()
		list(REMOVE_ITEM dirs ${remove})
		list(APPEND dirs ${remove})
		list(APPEND sysdirs ${remove})
		list(REMOVE_DUPLICATES sysdirs)
		set_target_properties(${target} PROPERTIES
			${inc_prop} "${dirs}"
			INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${sysdirs}"
		)
	endif()
endfunction()

function(force_include_last target include)
	force_include_last_impl(${target} "${include}" INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_LIBRARIES)
	force_include_last_impl(${target} "${include}" INCLUDE_DIRECTORIES LINK_LIBRARIES)
endfunction()
