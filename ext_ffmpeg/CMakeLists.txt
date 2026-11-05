cmake_minimum_required(VERSION 3.29)

project(ext_ffmpeg)
include(${CMAKE_SOURCE_DIR}/../cmake/base-dep-options.cmake)
include(${CMAKE_SOURCE_DIR}/../cmake/krita_initialize_python.cmake)
include(${CMAKE_SOURCE_DIR}/../cmake/krita_initialize_meson.cmake)

if (ANDROID AND ${CMAKE_SYSTEM_PROCESSOR} STREQUAL "i686")
    set(DISABLE_ASM_ON_ANDROID_x86_32 "-Dasm=disabled" "-Dinline_asm=disabled")
endif()
# IMPORTANT:
# OpenSUSE's list of whitelisted encoders: https://build.opensuse.org/package/view_file/openSUSE:Factory/ffmpeg-5/enable_encoders
# OpenSUSE's list of whitelisted decoders: https://build.opensuse.org/package/view_file/openSUSE:Factory/ffmpeg-5/enable_decoders
# Above are the lists of codecs that have been approved for use by OpenSUSE's legal department.
# Anything not enabled (missing or commented out) in these lists is considered unsafe and should NOT be used!
# While unlikely, it's possible that these lists could change, so it's worth occasionally cross-referencing.

if (NOT MSVC)
    set(_stack_guard_flag "-Denable-ssp=enabled")
endif() 

set(FFMPEG_GIT_SHA1 1834eb471506fe3f6296aa844825ac317e51bd5b)

if (IOS)
    # iPadOS (personal build): a static library for Krita's in-process
    # encoder, without the command-line programs and, for now, without the
    # external codec libraries (aom, vpx, openh264, theora, lame, opus,
    # vorbis, sdl2), which are not built for iOS yet. FFmpeg's own encoders
    # (PNG/APNG, GIF, FLAC, AAC) and libwebp remain.
    set(FFMPEG_LINKAGE_OPTIONS -Ddefault_library=static -Dprograms=disabled
        -Dffmpeg=disabled -Dffprobe=disabled)
    set(FFMPEG_EXTERNAL_LIBS -Dsdl2=disabled -Dlibaom=disabled
        -Dlibaom_av1_encoder=disabled -Dlibvpl=disabled
        -Dlibvpx=disabled -Dlibvpx_vp9_encoder=disabled -Dlibvpx_vp8_encoder=disabled
        -Dlibopenh264=disabled -Dlibtheora=disabled
        -Dlibmp3lame=disabled -Dlibopus=disabled -Dlibvorbis=disabled)
else()
    set(FFMPEG_LINKAGE_OPTIONS -Ddefault_library=shared -Dprograms=enabled
        -Dffmpeg=enabled -Dffprobe=enabled)
    set(FFMPEG_EXTERNAL_LIBS -Dsdl2=enabled -Dlibaom=enabled
        -Dlibaom_av1_encoder=enabled -Dlibvpl=auto
        -Dlibvpx=enabled -Dlibvpx_vp9_encoder=enabled -Dlibvpx_vp8_encoder=enabled
        -Dlibopenh264=enabled -Dlibtheora=enabled
        -Dlibmp3lame=enabled -Dlibopus=enabled -Dlibvorbis=enabled)
endif()

kis_ExternalProject_Add_with_separate_builds_apple(
    ext_ffmpeg
    MESON
    DOWNLOAD_DIR ${EXTERNALS_DOWNLOAD_DIR}
    GIT_REPOSITORY https://gitlab.freedesktop.org/gstreamer/meson-ports/ffmpeg.git

    # we use this branch as a source:
    # https://gitlab.freedesktop.org/gstreamer/meson-ports/ffmpeg/-/tree/meson-8.0.1
    GIT_TAG ${FFMPEG_GIT_SHA1}

    PATCH_COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0001-Add-an-option-to-disable-UB-in-av_uninit.patch
          COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0002-Add-options-for-SSP-and-CFGuard.patch
          COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0007-Switch-deps-of-QSV-codecs-to-libvpl-instead-of-libmf.patch
          COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0009-Fix-VP9-hw-accelerated-encoder-with-libvpl.patch
          COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0010-Fix-version-file-generation-in-version.py.patch
          COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0011-Fix-build-with-Dvaapi-disabled.patch
          COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0012-Fix-makedef.py-to-generate-correct-files-on-Linux.patch
          COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0013-Fix-includes-for-the-optional-avcodec-sources.patch
          COMMAND ${PATCH_COMMAND} -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/0014-Do-not-require-gzip-binary-to-build-zlib-support.patch
          COMMAND ${CMAKE_COMMAND} -E echo "8.0.1-g${FFMPEG_GIT_SHA1}" > VERSION

    CONFIGURE_ARGS --prefix=${EXTPREFIX}
            -Dvaapi=disabled
            --libdir=lib
            -Dno_uninit_ub=true
            ${_stack_guard_flag}
            -Denable-cfguard=disabled # TODO: change to 'auto' when Krita enabled cfguard internally
            -Dbuildtype=$<IF:$<CONFIG:Debug>,debug,debugoptimized>
            ${DISABLE_ASM_ON_ANDROID_x86_32}
            -Dtests=disabled
            ${FFMPEG_LINKAGE_OPTIONS}
            ${FFMPEG_EXTERNAL_LIBS}
            -Dffplay=disabled
            -Davdevice=disabled
            -Davcodec=enabled
            -Davformat=enabled
            -Davutil=enabled
            -Dswresample=enabled
            -Dswscale=enabled
            -Dpostproc=disabled
            -Dzlib=enabled
            -Dimage2_demuxer=enabled
            -Dimage2_alias_pix_demuxer=enabled
            -Dimage2_brender_pix_demuxer=enabled
            # ===================== Container Formats
            -Dwebm_muxer=enabled
            -Dmatroska_muxer=enabled
            -Dogg_muxer=enabled
            -Dapng_muxer=enabled
            # ===================== Image Formats
            -Dlibwebp=enabled
            -Dpng_encoder=enabled
            -Dpng_decoder=enabled
            -Dapng_encoder=enabled
            -Dapng_decoder=enabled
            # ===================== Video Codecs
            # ===================== Audio Codecs
            -Dflac_encoder=enabled
            -Daac_encoder=enabled
            -Dvaapi=disabled

            ${EXTRA_MESON_FLAGS}

    UPDATE_COMMAND ""
)

krita_add_to_ci_targets(ext_ffmpeg)
