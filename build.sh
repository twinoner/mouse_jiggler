#!/bin/bash
# Builds MouseJiggler.app in the project root.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="MouseJiggler.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/MouseJiggler" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"

echo "Built $APP — copy it to /Applications and open it."
