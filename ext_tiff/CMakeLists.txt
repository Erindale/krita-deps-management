cmake_minimum_required(VERSION 3.29)

project(ext_tiff)
include(${CMAKE_SOURCE_DIR}/../cmake/base-dep-options.cmake)

if(ANDROID)
    # WARNING: this patch should **not** be applied on other platforms,
    # especially on Windows, because it removes a windows specific symbol
    # from the linker script
    set(ANDROID_PATCH_COMMAND
        PATCH_COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0001-android-Remove-windows-specifc-symbols-from-linker-s.patch)
else()
    set(ANDROID_PATCH_COMMAND)
endif()

if (IOS)
    # static libtiff: its CMake config must import zlib, JPEG, WebP and CMath
    set(TIFF_STATIC_PATCH_COMMAND
        PATCH_COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0002-Import-dependencies-of-a-static-libtiff.patch)
else()
    set(TIFF_STATIC_PATCH_COMMAND)
endif()

set(TIFF_EXTRA_ARGS)
if (IOS)
    # The command-line tools are not needed in an app, and with static
    # libwebp they fail to link (libsharpyuv is not pulled in)
    set(TIFF_EXTRA_ARGS -Dtiff-tools=OFF -Dtiff-tests=OFF -Dtiff-contrib=OFF -Dtiff-docs=OFF)
endif()

ExternalProject_Add( ext_tiff
    DOWNLOAD_DIR ${EXTERNALS_DOWNLOAD_DIR}
    URL https://download.osgeo.org/libtiff/tiff-4.7.1.tar.gz
    URL_HASH SHA256=f698d94f3103da8ca7438d84e0344e453fe0ba3b7486e04c5bf7a9a3fabe9b69

    ${ANDROID_PATCH_COMMAND}
    ${TIFF_STATIC_PATCH_COMMAND}
    
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTPREFIX} -DCMAKE_BUILD_TYPE=${GLOBAL_BUILD_TYPE} ${GLOBAL_PROFILE} ${TIFF_EXTRA_ARGS}

    UPDATE_COMMAND ""
)

krita_add_to_ci_targets(ext_tiff)
