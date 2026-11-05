cmake_minimum_required(VERSION 3.29)

project(ext_openexr)
include(${CMAKE_SOURCE_DIR}/../cmake/base-dep-options.cmake)

set(OPENEXR_URL https://github.com/AcademySoftwareFoundation/openexr/releases/download/v3.4.10/openexr-3.4.10.tar.gz)
set(OPENEXR_SHA256 2e054a8f5030c25d1585cbfa537feaaf86d69388b75c00d96c3a91f676e88cbe)

set(OPENEXR_DEPENDS)
if (IOS)
    # A static OpenEXR built with its vendored OpenJPH exports a reference
    # to an "openjph" target that it never installs. Build that vendored
    # OpenJPH from the same tarball as a package of its own first; OpenEXR
    # then finds it and its config imports it with find_dependency().
    ExternalProject_Add( ext_openjph
        DOWNLOAD_DIR ${EXTERNALS_DOWNLOAD_DIR}
        URL ${OPENEXR_URL}
        URL_HASH SHA256=${OPENEXR_SHA256}
        SOURCE_SUBDIR external/OpenJPH

        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTPREFIX} -DCMAKE_BUILD_TYPE=${GLOBAL_BUILD_TYPE} ${GLOBAL_PROFILE}
            -DOJPH_BUILD_EXECUTABLES=OFF -DOJPH_ENABLE_TIFF_SUPPORT=OFF -DOJPH_BUILD_TESTS=OFF

        UPDATE_COMMAND ""
    )
    set(OPENEXR_DEPENDS DEPENDS ext_openjph)
endif()

ExternalProject_Add( ext_openexr
    DOWNLOAD_DIR ${EXTERNALS_DOWNLOAD_DIR}
    URL ${OPENEXR_URL}
    URL_HASH SHA256=${OPENEXR_SHA256}

    INSTALL_DIR ${EXTPREFIX}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTPREFIX} -DCMAKE_BUILD_TYPE=${GLOBAL_BUILD_TYPE} ${GLOBAL_PROFILE} -DNAMESPACE_VERSIONING=OFF -DOPENEXR_FORCE_INTERNAL_DEFLATE=ON

    UPDATE_COMMAND ""
    ${OPENEXR_DEPENDS}
)

krita_add_to_ci_targets(ext_openexr)
