#!/bin/bash
# Adapted from https://github.com/DimaRU/FastDDSPrebuild/blob/master/script/fastrtps_build_xctframework.sh
set -e

if [[ $# > 0 ]]; then
TAG=$1
else
echo "Usage: build.sh TAG commit"
echo "where TAG is CycloneDDS version tag eg. 0.10.2"
exit -1
fi

#make tag
CycloneDDS_repo="-b $TAG https://github.com/eclipse-cyclonedds/cyclonedds.git"
ReleaseNote="CycloneDDS $TAG: iOS, iOS Simulator, macOS"
echo $TAG

ZIPNAME=cyclonedds-$TAG.xcframework.zip
GIT_REMOTE_URL_UNFINISHED=`git config --get remote.origin.url|sed "s=^ssh://==; s=^https://==; s=:=/=; s/git@//; s/.git$//;"`
DOWNLOAD_URL=https://$GIT_REMOTE_URL_UNFINISHED/releases/download/$TAG/$ZIPNAME

#clone
export ROOT_PATH=$(cd "$(dirname "$0")/.."; pwd -P)
pushd $ROOT_PATH > /dev/null

BUILD=$ROOT_PATH/build
export PROJECT_TEMP_DIR=$BUILD/temp
export SOURCE_DIR=$BUILD/src

if [ ! -d $SOURCE_DIR/cyclonedds ]; then
git clone --quiet --recurse-submodules --depth 1 $CycloneDDS_repo $SOURCE_DIR/cyclonedds
fi

pushd $SOURCE_DIR/cyclonedds > /dev/null
DATE=$(git tag -l --format="%(creatordate:iso)" $1)
popd > /dev/null

# path
patch --directory=build/src/cyclonedds -p1 <script/ios_patch.patch

BUILD=$ROOT_PATH/build
# Build library

# MACOS
BUILT_PRODUCTS_DIR=$BUILD/mac
cmake -B $BUILT_PRODUCTS_DIR/build -S $SOURCE_DIR/cyclonedds \
    -G Xcode \
    -D ENABLE_SECURITY=0 \
    -D ENABLE_LTO=NO \
    -D ENABLE_TOPIC_DISCOVERY=ON \
    -D BUILD_SHARED_LIBS=NO \
    -D CMAKE_CONFIGURATION_TYPES=Release \
    -D CMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -D CMAKE_INSTALL_PREFIX=$BUILT_PRODUCTS_DIR/install

cmake --build $BUILT_PRODUCTS_DIR/build --config Release --target install

# IOS
BUILT_PRODUCTS_DIR=$BUILD/iphoneos
cmake -B $BUILT_PRODUCTS_DIR/build -S $SOURCE_DIR/cyclonedds \
    -G Xcode \
    -D ENABLE_SECURITY=0 \
    -D CMAKE_SYSTEM_NAME=iOS \
    -D ENABLE_LTO=NO \
    -D ENABLE_TOPIC_DISCOVERY=ON \
    -D BUILD_SHARED_LIBS=NO \
    -D CMAKE_CONFIGURATION_TYPES=Release \
    -D CMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -D CMAKE_INSTALL_PREFIX=$BUILT_PRODUCTS_DIR/install

cmake --build $BUILT_PRODUCTS_DIR/build --config Release --target install

# SIMULATOR
BUILT_PRODUCTS_DIR=$BUILD/sim
cmake -B $BUILT_PRODUCTS_DIR/build -S $SOURCE_DIR/cyclonedds \
    -G Xcode \
    -D ENABLE_SECURITY=0 \
    -D CMAKE_SYSTEM_NAME=iOS \
    -D ENABLE_LTO=NO \
    -D ENABLE_TOPIC_DISCOVERY=ON \
    -D BUILD_SHARED_LIBS=NO \
    -D CMAKE_CONFIGURATION_TYPES=Release \
    -D CMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -D CMAKE_INSTALL_PREFIX=$BUILT_PRODUCTS_DIR/install
cmake --build $BUILT_PRODUCTS_DIR/build --config Release --target install -- -sdk iphonesimulator

xcodebuild -create-xcframework \
-library $BUILD/mac/install/lib/libddsc.a \
-headers $BUILD/mac/install/include \
-library $BUILD/iphoneos/install/lib/libddsc.a \
-headers $BUILD/iphoneos/install/include \
-library $BUILD/sim/install/lib/libddsc.a \
-headers $BUILD/sim/install/include \
-output cyclonedds.xcframework

XCODE_VER="Archive date:$DATE"
XCODE_VER+=$'\n'
XCODE_VER+=$(xcodebuild -version 2>&1| tail -n 2)
echo $XCODE_VER
xczip cyclonedds.xcframework --iso-date "$DATE" -o $ZIPNAME -c "$XCODE_VER"
rm -rf cyclonedds.xcframework

CHECKSUM=`shasum -a 256 -b $ZIPNAME | awk '{print $1}'`

cat >Package.swift << EOL
// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CycloneDDS",
    products: [
        .library(name: "CycloneDDS", targets: ["CycloneDDS"])
    ],
    targets: [
        .binaryTarget(name: "CycloneDDS",
                      url: "$DOWNLOAD_URL",
                      checksum: "$CHECKSUM")
    ]
)
EOL

if [[ $2 == "commit" ]]; then

git add Package.swift
git commit -m "Build $TAG"
git tag $TAG
git push
git push --tags
gh release create "$TAG" $ZIPNAME --title "$TAG" --notes "$ReleaseNote"
#
# Cleanup
#
rm -rf build
git clean -x -d -f
fi
popd > /dev/null
