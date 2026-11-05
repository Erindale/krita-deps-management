#!/bin/bash
#
# Build Krita's dependencies for iPadOS into one static prefix, without the
# KDE CI tooling (krita-ci-utilities has no iOS flavour). Each recipe is
# configured the way the CI does it: a standalone CMake project with
# tools/ios-toolchain.cmake, built through its ext_install target.
#
# Usage:
#   tools/ios-build-deps.sh <iphoneos|iphonesimulator> [recipe ...]
#
# Without recipes, builds the whole iOS set below in dependency order and
# stops at the first failure. Environment:
#   IOS_DEPS_ROOT   work area (default: ../krita-ios next to this repository)
#                   prefix:  $IOS_DEPS_ROOT/deps-<sdk>
#                   builds:  $IOS_DEPS_ROOT/build/deps-<sdk>/<recipe>
#                   logs:    $IOS_DEPS_ROOT/logs/deps-<sdk>/<recipe>.log
#                   tarballs: $IOS_DEPS_ROOT/downloads
#   IOS_HOST_TOOLS  directories with host meson, pkg-config and gettext
#                   (msgfmt), prepended to PATH
#   JOBS            parallel jobs (default 4)
#   KEEP=1          reuse a recipe's build tree (finished steps are skipped)
#
# Host requirements: Xcode with the iOS SDKs, CMake >= 3.29, Ninja, meson,
# pkg-config (pkgconf) and GNU gettext's msgfmt/msgmerge for ki18n.

set -uo pipefail

SDK=${1:?usage: $0 iphoneos|iphonesimulator [recipe ...]}
shift
case "$SDK" in iphoneos|iphonesimulator) ;; *) echo "bad SDK: $SDK"; exit 2;; esac

REPO=$(cd "$(dirname "$0")/.." && pwd)
ROOT=${IOS_DEPS_ROOT:-$(cd "$REPO/.." && pwd)/krita-ios}
JOBS=${JOBS:-4}
PREFIX=$ROOT/deps-$SDK
LOGS=$ROOT/logs/deps-$SDK
mkdir -p "$PREFIX" "$LOGS" "$ROOT/downloads"

# zlib and expat come from the SDK (their recipes only install .pc files);
# Qt needs the image and text libraries before it, the KDE frameworks and
# quazip need Qt.
ALL="zlib expat png extra_cmake_modules jpeg lcms2 eigen3 xsimd immer zug lager
brotli unibreak imath json_c giflib gsl fftw3 freetype fribidi fontconfig exiv2
boost libintl-lite webp tiff openexr mypaint ffmpeg qt quazip kconfig kcoreaddons
kwidgetsaddons kcodecs kcompletion kguiaddons ki18n kitemviews kcolorscheme"

RECIPES=${*:-$ALL}

[ -n "${IOS_HOST_TOOLS:-}" ] && export PATH="$IOS_HOST_TOOLS:$PATH"
export KDECI_IOS_SDK=$SDK
# Passed as a CMake variable instead: in the environment it makes every
# clang call target iOS, including the ones meant for the Mac.
unset IPHONEOS_DEPLOYMENT_TARGET CMAKE_TOOLCHAIN_FILE
export CMAKE_PREFIX_PATH=$PREFIX
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH

for r in $RECIPES; do
    B=$ROOT/build/deps-$SDK/$r
    [ "${KEEP:-0}" = 1 ] || rm -rf "$B"
    mkdir -p "$B"
    T0=$(date +%s)
    if ( cd "$B" &&
         cmake -G Ninja "$REPO/ext_$r" -Wno-dev \
             -DCMAKE_TOOLCHAIN_FILE="$REPO/tools/ios-toolchain.cmake" \
             -DKDECI_IOS_SDK=$SDK -DIPHONEOS_DEPLOYMENT_TARGET=17.0 \
             -DCMAKE_INSTALL_PREFIX="$PREFIX" \
             -DEXTERNALS_DOWNLOAD_DIR="$ROOT/downloads" \
             -DSUBMAKE_JOBS=$JOBS &&
         cmake --build . --target ext_install ) > "$LOGS/$r.log" 2>&1
    then
        echo "OK   $r $(( $(date +%s) - T0 ))s"
    else
        echo "FAIL $r (log: $LOGS/$r.log)"
        exit 1
    fi
    # Everything must be static: an iOS app cannot load these from the prefix
    shared=$(find "$PREFIX/lib" -maxdepth 1 \( -name "*.dylib" -o -name "*.framework" \) ! -name "Qt*" 2>/dev/null)
    if [ -n "$shared" ]; then
        echo "FAIL $r left shared libraries in the prefix:"; echo "$shared"
        exit 1
    fi
done
echo "ALL DONE ($SDK, prefix $PREFIX)"
