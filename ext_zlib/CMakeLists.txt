cmake_minimum_required(VERSION 3.29)

project(ext_zlib)
include(${CMAKE_SOURCE_DIR}/../cmake/base-dep-options.cmake)

if (IOS)
# The iOS SDK ships zlib (libz.tbd), and everything already links against
# it, so nothing is built. Meson and pkg-config users still look for
# zlib.pc, so install one that points at the SDK's copy.
set(_sdk_zlib_h "${KRITA_IOS_SDK_PATH}/usr/include/zlib.h")
file(STRINGS ${_sdk_zlib_h} _zlib_version_line REGEX "^#define ZLIB_VERSION ")
string(REGEX REPLACE "^#define ZLIB_VERSION \"([^\"]+)\".*" "\\1" ZLIB_SDK_VERSION "${_zlib_version_line}")
message(STATUS "Using the iOS SDK's zlib ${ZLIB_SDK_VERSION}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/zlib.pc
"Name: zlib
Description: zlib compression library (from the iOS SDK)
Version: ${ZLIB_SDK_VERSION}
Libs: -lz
Cflags:
")
ExternalProject_Add(
    ext_zlib
    DOWNLOAD_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${EXTPREFIX}/lib/pkgconfig
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/zlib.pc ${EXTPREFIX}/lib/pkgconfig/zlib.pc
    UPDATE_COMMAND ""
)
elseif (NOT APPLE)
ExternalProject_Add(
    ext_zlib
    DOWNLOAD_DIR ${EXTERNALS_DOWNLOAD_DIR}
    URL https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz
    URL_HASH SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16

    PATCH_COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0001-Prevent-invalid-inclusions-when-HAVE_-is-set-to-0.patch

    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTPREFIX} -DCMAKE_BUILD_TYPE=${GLOBAL_BUILD_TYPE} ${GLOBAL_PROFILE}

    UPDATE_COMMAND ""
)

# ZLib had a naming bug on Windows for ages, it is resolved in newer versions:
# https://github.com/madler/zlib/issues/652

else()
ExternalProject_Add(
    ext_zlib
    DOWNLOAD_DIR ${EXTERNALS_DOWNLOAD_DIR}
    URL https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz
    URL_HASH SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16

    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTPREFIX} ${GLOBAL_PROFILE}

    UPDATE_COMMAND ""
)
endif()

krita_add_to_ci_targets(ext_zlib)
