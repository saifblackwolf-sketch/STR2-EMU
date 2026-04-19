# Copyright (c) Meta Platforms, Inc. and affiliates.
# Licensed under the Apache License, Version 2.0
#
# Try to find Facebook zstd library
# Zstd_FOUND, Zstd_INCLUDE_DIR, Zstd_LIBRARY

find_path(Zstd_INCLUDE_DIR NAMES zstd.h)

find_library(Zstd_LIBRARY_DEBUG NAMES zstdd zstd_staticd)
find_library(Zstd_LIBRARY_RELEASE NAMES zstd zstd_static)

include(SelectLibraryConfigurations)
SELECT_LIBRARY_CONFIGURATIONS(Zstd)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(
    Zstd DEFAULT_MSG
    Zstd_LIBRARY Zstd_INCLUDE_DIR
)

mark_as_advanced(Zstd_INCLUDE_DIR Zstd_LIBRARY)

if(Zstd_FOUND AND NOT (TARGET Zstd::Zstd))
  add_library (Zstd::Zstd UNKNOWN IMPORTED)
  set_target_properties(Zstd::Zstd
    PROPERTIES
    IMPORTED_LOCATION ${Zstd_LIBRARY}
    INTERFACE_INCLUDE_DIRECTORIES ${Zstd_INCLUDE_DIR})
endif()
