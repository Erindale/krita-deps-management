cmake_minimum_required(VERSION 3.29)

project(ext_lcms2)
include(${CMAKE_SOURCE_DIR}/../cmake/base-dep-options.cmake)

set(LCMS2_EXTRA_ARGS)
if (IOS)
    # lcms2 2.19 renamed its switches to LCMS2_*
    set(LCMS2_EXTRA_ARGS -DLCMS2_BUILD_SHARED=OFF -DLCMS2_BUILD_STATIC=ON
        -DLCMS2_BUILD_TOOLS=OFF -DLCMS2_BUILD_TESTS=OFF)
endif()

ExternalProject_Add( ext_lcms2
    DOWNLOAD_DIR ${EXTERNALS_DOWNLOAD_DIR}
    URL https://github.com/mm2/Little-CMS/archive/refs/tags/lcms2.19.tar.gz
    URL_HASH SHA256=6acc3eb5fac194acc85331194133ad1d4a60419dad16b3bc225a7d27380a5b3a

    PATCH_COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0003-Revert-Fix-LUT-based-optimization-on-8-bits.patch

    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTPREFIX} -DCMAKE_BUILD_TYPE=${GLOBAL_BUILD_TYPE} ${GLOBAL_PROFILE} -DBUILD_TESTS=FALSE -DBUILD_UTILS=FALSE -DBUILD_STATIC=FALSE -DBUILD_PLUGINS=TRUE ${LCMS2_EXTRA_ARGS}

    UPDATE_COMMAND ""
)

krita_add_to_ci_targets(ext_lcms2)
