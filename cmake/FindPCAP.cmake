# - Try to find libpcap
# PCAP_FOUND, PCAP::PCAP

find_path(PCAP_ROOT_DIR
	NAMES include/pcap.h
)

find_path(PCAP_INCLUDE_DIR
	NAMES pcap.h
	HINTS ${PCAP_ROOT_DIR}/include
)

find_library(PCAP_LIBRARY
	NAMES pcap
	HINTS ${PCAP_ROOT_DIR}/lib
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PCAP DEFAULT_MSG
	PCAP_LIBRARY
	PCAP_INCLUDE_DIR
)

include(CheckCSourceCompiles)
if(PCAP_LIBRARY)
	set(CMAKE_REQUIRED_LIBRARIES ${PCAP_LIBRARY})
	check_c_source_compiles("int main() { return 0; }" PCAP_LINKS_SOLO)
	set(CMAKE_REQUIRED_LIBRARIES)

	if (NOT PCAP_LINKS_SOLO)
		find_package(Threads)
		if (THREADS_FOUND)
			set(CMAKE_REQUIRED_LIBRARIES ${PCAP_LIBRARY} ${CMAKE_THREAD_LIBS_INIT})
			check_c_source_compiles("int main() { return 0; }" PCAP_NEEDS_THREADS)
			set(CMAKE_REQUIRED_LIBRARIES)
		endif ()
		if (THREADS_FOUND AND PCAP_NEEDS_THREADS)
			set(_tmp ${PCAP_LIBRARY} ${CMAKE_THREAD_LIBS_INIT})
			list(REMOVE_DUPLICATES _tmp)
			set(PCAP_LIBRARY ${_tmp}
				CACHE STRING "Libraries needed to link against libpcap" FORCE)
		endif ()
	endif ()
endif()

if(PCAP_LIBRARY AND NOT TARGET PCAP::PCAP)
	add_library(PCAP::PCAP UNKNOWN IMPORTED GLOBAL)
	set_target_properties(PCAP::PCAP PROPERTIES
		IMPORTED_LOCATION "${PCAP_LIBRARY}"
		INTERFACE_INCLUDE_DIRECTORIES "${PCAP_INCLUDE_DIR}")
endif()

mark_as_advanced(
	PCAP_ROOT_DIR
	PCAP_INCLUDE_DIR
	PCAP_LIBRARY
)
