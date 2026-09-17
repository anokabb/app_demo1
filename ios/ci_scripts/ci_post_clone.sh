#!/bin/sh

# Xcode Cloud has no Flutter toolchain by default — this installs it,
# resolves Dart deps, and runs CocoaPods before xcodebuild ever runs.
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

git clone https://github.com/flutter/flutter.git -b 3.29.3 --depth 1 "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter doctor
flutter precache --ios
flutter pub get

cd ios
pod install
