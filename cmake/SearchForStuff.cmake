# SearchForStuff.cmake — iOS-only variant
# -----------------------------------------------------------------------
# This file replaces the upstream SearchForStuff.cmake which requires
# system packages (Qt6, SDL2, PNG, JPEG, WebP, etc.) not available in
# a headless iOS cross-compilation environment.
#
# Strategy: include only the bundled 3rdparty subdirectories that
#   (a) have a CMakeLists.txt
#   (b) are referenced by the iOS build targets in cpp/CMakeLists.txt
#   (c) compile correctly for iOS / arm64
#
# Anything guarded by if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS") in
# SearchForStuff or pcsx2/CMakeLists is skipped here.
# -----------------------------------------------------------------------

find_package(Git)
find_package(Threads REQUIRED)

# ── Platform feature flags ─────────────────────────────────────────────
# Must be set BEFORE any add_subdirectory() that might read these options.
# USE_VULKAN=OFF: iOS uses Metal. No Vulkan SDK available in CI.
# Setting this here ensures any subdirectory 'option(USE_VULKAN ...)' call
# is overridden by our cached OFF value.
set(USE_VULKAN OFF CACHE BOOL "Enable Vulkan GS renderer" FORCE)
# SDL_VULKAN/SDL_RENDER_VULKAN are also set below before add_subdirectory(SDL3)
# but we also set them here in case SDL picks up the cache before that block runs.
set(SDL_VULKAN        OFF CACHE BOOL "SDL: Vulkan support"          FORCE)
set(SDL_RENDER_VULKAN OFF CACHE BOOL "SDL: Vulkan render backend"   FORCE)

# ── Core utility libraries (always needed) ─────────────────────────────
add_subdirectory(3rdparty/fast_float EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/fmt        EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/rapidyaml  EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/rapidjson  EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/simpleini  EXCLUDE_FROM_ALL)

# ── Compression / archive libs ─────────────────────────────────────────
add_subdirectory(3rdparty/zlib      EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/zstd      EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/lz4       EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/lzma      EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/libchdr   EXCLUDE_FROM_ALL)
disable_compiler_warnings_for_target(libchdr)
add_subdirectory(3rdparty/libzip    EXCLUDE_FROM_ALL)

# ── Achievements / online features ─────────────────────────────────────
add_subdirectory(3rdparty/rcheevos  EXCLUDE_FROM_ALL)

# ── Image / texture libs ───────────────────────────────────────────────
# Disable libwebp CLI tools (dwebp, cwebp, img2webp, webpinfo, webpmux).
# On iOS, their install() rules require a BUNDLE DESTINATION which doesn't
# exist, causing CMake to error. We only need the library, not the tools.
set(WEBP_BUILD_ANIM_UTILS  OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_CWEBP       OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_DWEBP       OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_GIF2WEBP    OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_IMG2WEBP    OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_VWEBP       OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_WEBPINFO    OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_WEBPMUX     OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_EXTRAS      OFF CACHE BOOL "" FORCE)
add_subdirectory(3rdparty/libwebp   EXCLUDE_FROM_ALL)
# add_subdirectory(libwebp) creates a target called "webp" (no namespace).
# common/CMakeLists.txt and pcsx2/CMakeLists.txt both link against
# "WebP::libwebp" — the name that FindWebP.cmake would produce.
# Create the alias so both naming conventions resolve to the same target.
if(NOT TARGET WebP::libwebp)
  add_library(WebP::libwebp ALIAS webp)
endif()
if(NOT TARGET WebP::webp)
  add_library(WebP::webp ALIAS webp)
endif()

# ── UI / rendering ─────────────────────────────────────────────────────
add_subdirectory(3rdparty/imgui      EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/freetype   EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/plutosvg1  EXCLUDE_FROM_ALL)

# ── Audio ──────────────────────────────────────────────────────────────
# cubeb_audiounit.cpp uses macOS-only CoreAudio hardware enumeration APIs
# (AudioObjectPropertyAddress, kAudioHardwarePropertyDefaultInputDevice, etc.)
# which are NOT available on iOS — iOS has AudioUnit but not AudioHardware.h.
# Force USE_AUDIOUNIT=OFF so cubeb skips that backend entirely.
# check_include_files() in cubeb's CMakeLists only runs if the variable is
# not already cached, so setting it here prevents the check from overriding us.
set(USE_AUDIOUNIT OFF CACHE BOOL "cubeb: disable AudioUnit (macOS-only) backend on iOS" FORCE)
add_subdirectory(3rdparty/cubeb EXCLUDE_FROM_ALL)
disable_compiler_warnings_for_target(cubeb)

# freesurround (surround sound post-processor)
add_subdirectory(3rdparty/freesurround EXCLUDE_FROM_ALL)

# soundtouch (pitch / tempo processing)
add_subdirectory(3rdparty/soundtouch EXCLUDE_FROM_ALL)

# ── Input / controller ─────────────────────────────────────────────────
# SDL3 is used for gamepad input and is shipped bundled.
# We set it to build as a static library for iOS.
# SDL_VULKAN=ON (SDL3 default on Apple) causes SDL3 public headers to include
# vulkan/vulkan.h. Since we have no Vulkan SDK in the iOS build environment,
# any PCSX2 file that includes <SDL3/SDL.h> fails with 'vulkan/vulkan.h not found'.
# Disable both SDL_VULKAN and SDL_RENDER_VULKAN to remove the dependency.
set(SDL_SHARED        OFF CACHE BOOL "Build SDL as shared lib"          FORCE)
set(SDL_STATIC        ON  CACHE BOOL "Build SDL as static lib"          FORCE)
set(SDL_VULKAN        OFF CACHE BOOL "SDL: disable Vulkan (no SDK)"     FORCE)
set(SDL_RENDER_VULKAN OFF CACHE BOOL "SDL: disable Vulkan renderer"     FORCE)
add_subdirectory(3rdparty/SDL3  EXCLUDE_FROM_ALL)

# ── Shader / GPU ───────────────────────────────────────────────────────
# glslang (SPIR-V compiler) and Vulkan headers are only needed when
# USE_VULKAN=ON. On iOS we use Metal, so both are skipped.
if(USE_VULKAN)
  add_subdirectory(3rdparty/glslang EXCLUDE_FROM_ALL)
  add_subdirectory(3rdparty/vulkan  EXCLUDE_FROM_ALL)
endif()

# ── Debug / profiling tools ────────────────────────────────────────────
add_subdirectory(3rdparty/demangler EXCLUDE_FROM_ALL)
add_subdirectory(3rdparty/ccc       EXCLUDE_FROM_ALL)

# ── CPU intrinsics ─────────────────────────────────────────────────────
add_subdirectory(3rdparty/cpuinfo EXCLUDE_FROM_ALL)
disable_compiler_warnings_for_target(cpuinfo)

# ARM64-specific JIT assembler
if(_M_ARM64)
  add_subdirectory(3rdparty/vixl EXCLUDE_FROM_ALL)
endif()

# ── Discord (optional, off by default) ─────────────────────────────────
if(USE_DISCORD_SDK)
  add_subdirectory(3rdparty/discord-rpc EXCLUDE_FROM_ALL)
endif()

# ── Global compile flags ───────────────────────────────────────────────
# Prevent fmt from being built with exceptions.
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DFMT_EXCEPTIONS=0")

# Force TARGET_OS_IPHONE=1 so that every source file (including those that
# use #if TARGET_OS_IPHONE before they include <TargetConditionals.h>) takes
# the iOS code path. Without this, ~20 PCSX2 files evaluate TARGET_OS_IPHONE
# to 0, compile the desktop/libpng code path, and produce link errors because
# libpng is not present in the iOS build environment.
add_compile_definitions(
    TARGET_OS_IPHONE=1
    TARGET_IPHONE_SIMULATOR=0
)
