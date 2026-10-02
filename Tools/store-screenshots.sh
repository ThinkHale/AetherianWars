#!/bin/sh
# App Store screenshots: builds the app, boots an iPhone 6.9" and an iPad 13"
# simulator, opens each screen through the AETHERIA_START launch route, and
# saves landscape PNGs to docs/marketing/screenshots/<device>/.
#   ./Tools/store-screenshots.sh
set -eu
cd "$(dirname "$0")/.."

RUNTIME=$(xcrun simctl list runtimes | awk '/iOS/ {id=$NF} END {print id}')
OUT=docs/marketing/screenshots
APP=build/Screens/Build/Products/Debug-iphonesimulator/AetheriaClash.app
BUNDLE=com.thinkhale.aetheria.clash

device() { # name type -> udid (created once, reused)
  udid=$(xcrun simctl list devices | grep "$1 (" | grep -oE '[0-9A-F-]{36}' | head -1 || true)
  [ -n "$udid" ] || udid=$(xcrun simctl create "$1" "$2" "$RUNTIME")
  echo "$udid"
}

IPHONE=$(device "Clash Shots iPhone" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max)
IPAD=$(device "Clash iPad Pro 13" com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB)

xcodebuild -project AetheriaClash.xcodeproj -scheme AetheriaClash -destination "id=$IPHONE" -derivedDataPath build/Screens build -quiet

# name|route|seconds to wait
SHOTS="01-fight|fight:livia:bardiya:forum:demo|9
02-select|select|4
03-versus|versus:bardiya:atossa|2
04-fight-nile|fight:nefru:khepri:nile:demo|11
05-hall|hall|4
06-echo|fight:wei_jian:wei_jian:crossing:demo:boss|10
07-ladder|ladder:tahmina:5|4
08-fight-wall|fight:zhao_lin:mei_lin:greatWall:demo|12
09-hero|hero:meritamun|4"

for pair in "iphone-6.9:$IPHONE" "ipad-13:$IPAD"; do
  name=${pair%%:*}; udid=${pair#*:}
  mkdir -p "$OUT/$name"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 2>/dev/null || true
  xcrun simctl install "$udid" "$APP"
  echo "$SHOTS" | while IFS='|' read -r shot route wait; do
    xcrun simctl terminate "$udid" $BUNDLE 2>/dev/null || true
    SIMCTL_CHILD_AETHERIA_START="$route" xcrun simctl launch "$udid" $BUNDLE >/dev/null
    sleep "$wait"
    file="$OUT/$name/$shot.png"
    xcrun simctl io "$udid" screenshot "$file" >/dev/null 2>&1
    # Simulators that capture in portrait are turned to landscape.
    w=$(sips -g pixelWidth "$file" | awk '/pixelWidth/{print $2}')
    h=$(sips -g pixelHeight "$file" | awk '/pixelHeight/{print $2}')
    [ "$w" -gt "$h" ] || sips -r 270 "$file" >/dev/null
    echo "  $name/$shot"
  done
done
echo "Screenshots in $OUT"
