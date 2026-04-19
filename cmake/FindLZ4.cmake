# Copyright (c) Meta Platforms, Inc. and affiliates.
# Licensed under the Apache License, Version 2.0
#
# Finds liblz4.
# LZ4_FOUND, LZ4_INCLUDE_DIR, LZ4_LIBRARY

find_path(LZ4_INCLUDE_DIR NAMES lz4.h)

find_library(LZ4_LIBRARY_DEBUG NAMES lz4d)
find_library(LZ4_LIBRARY_RELEASE NAMES lz4)

include(SelectLibraryConfigurations)
SELECT_LIBRARY_CONFIGURATIONS(LZ4)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(
    LZ4 DEFAULT_MSG
    LZ4_LIBRARY LZ4_INCLUDE_DIR
)

mark_as_advanced(LZ4_INCLUDE_DIR LZ4_LIBRARY)

if(LZ4_FOUND AND NOT (TARGET LZ4::LZ4))
  add_library (LZ4::LZ4 UNKNOWN IMPORTED)
  set_target_properties(LZ4::LZ4
    PROPERTIES
    IMPORTED_LOCATION ${LZ4_LIBRARY}
    INTERFACE_INCLUDE_DIRECTORIES ${LZ4_INCLUDE_DIR})
endif()
