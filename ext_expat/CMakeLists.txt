cmake_minimum_required(VERSION 3.29)

project(ext_expat)
include(${CMAKE_SOURCE_DIR}/../cmake/base-dep-options.cmake)

if (IOS)
# The iOS SDK ships expat (libexpat.tbd); as with zlib, nothing is built
# and an expat.pc pointing at the SDK's copy is installed for meson and
# pkg-config users (fontconfig).
set(_sdk_expat_h "${KRITA_IOS_SDK_PATH}/usr/include/expat.h")
foreach(_part MAJOR MINOR MICRO)
    file(STRINGS ${_sdk_expat_h} _line REGEX "define XML_${_part}_VERSION ")
    string(REGEX REPLACE ".*XML_${_part}_VERSION ([0-9]+).*" "\\1" _v_${_part} "${_line}")
endforeach()
set(EXPAT_SDK_VERSION "${_v_MAJOR}.${_v_MINOR}.${_v_MICRO}")
message(STATUS "Using the iOS SDK's expat ${EXPAT_SDK_VERSION}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/expat.pc
"Name: expat
Description: expat XML parser (from the iOS SDK)
Version: ${EXPAT_SDK_VERSION}
Libs: -lexpat
Cflags:
")
ExternalProject_Add(
    ext_expat
    DOWNLOAD_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory ${EXTPREFIX}/lib/pkgconfig
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/expat.pc ${EXTPREFIX}/lib/pkgconfig/expat.pc
    UPDATE_COMMAND ""
)
else()
ExternalProject_Add(
    ext_expat
    DOWNLOAD_DIR ${EXTERNALS_DOWNLOAD_DIR}
    URL https://github.com/libexpat/libexpat/releases/download/R_2_7_5/expat-2.7.5.tar.xz
    URL_HASH SHA256=1032dfef4ff17f70464827daa28369b20f6584d108bc36f17ab1676e1edd2f91

    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTPREFIX} -DBUILD_tests=OFF -DBUILD_examples=OFF -DBUILD_tools=OFF -DCMAKE_BUILD_TYPE=${GLOBAL_BUILD_TYPE} ${GLOBAL_PROFILE} <SOURCE_DIR>/expat
    UPDATE_COMMAND ""
)
endif()

krita_add_to_ci_targets(ext_expat)
