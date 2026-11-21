#!/usr/bin/env bash
# 在 macOS + Xcode 环境中启动 iPad 模拟器，安装 Debug 版 .app，
# 通过启动参数逐个渲染界面并输出真实 PNG 截图。
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <path-to-AtlasNotes.app> <output-dir>" >&2
  exit 64
fi

APP_PATH="$1"
OUT_DIR="$2"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app bundle not found: $APP_PATH" >&2
  exit 66
fi

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist")
mkdir -p "$OUT_DIR"

# 优先复用 Runner 上已有的 iPad 模拟器；必要时按当前可用 runtime 创建。
DEVICE_UDID=$(xcrun simctl list devices available \
  | grep -i "ipad" \
  | grep -oE '[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}' \
  | head -n 1 || true)

if [[ -z "${DEVICE_UDID}" ]]; then
  RUNTIME_ID=$(xcrun simctl list runtimes available \
    | grep -oE 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]+' \
    | tail -n 1)

  if [[ -z "${RUNTIME_ID}" ]]; then
    echo "error: no iOS simulator runtime installed" >&2
    exit 69
  fi

  DEVICE_TYPE=""
  for candidate in \
    "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M4" \
    "com.apple.CoreSimulator.SimDeviceType.iPad-Air-11-inch-M2" \
    "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4"; do
    if xcrun simctl list devicetypes | grep -q "$candidate"; then
      DEVICE_TYPE="$candidate"
      break
    fi
  done

  if [[ -z "${DEVICE_TYPE}" ]]; then
    DEVICE_TYPE=$(xcrun simctl list devicetypes \
      | grep -i "ipad" \
      | tail -n 1 \
      | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.[A-Za-z0-9._-]+')
  fi

  if [[ -z "${DEVICE_TYPE}" ]]; then
    echo "error: no iPad simulator device type available" >&2
    exit 69
  fi

  DEVICE_UDID=$(xcrun simctl create "AtlasNotes iPad" "$DEVICE_TYPE" "$RUNTIME_ID")
fi

echo "==> Simulator UDID: $DEVICE_UDID"
xcrun simctl boot "$DEVICE_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_UDID" -b
xcrun simctl ui "$DEVICE_UDID" appearance light || true
xcrun simctl status_bar "$DEVICE_UDID" override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4 || true

echo "==> Installing $APP_PATH"
xcrun simctl install "$DEVICE_UDID" "$APP_PATH"

for screen in library insights settings; do
  echo "==> Rendering screen: $screen"
  xcrun simctl terminate "$DEVICE_UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$DEVICE_UDID" "$BUNDLE_ID" -previewScreen "$screen" >/dev/null
  sleep 8
  xcrun simctl io "$DEVICE_UDID" screenshot "$OUT_DIR/${screen}.png"
  test -s "$OUT_DIR/${screen}.png"
  /usr/bin/sips -g pixelWidth -g pixelHeight "$OUT_DIR/${screen}.png"
done

echo "==> Screenshots written to $OUT_DIR"
ls -lh "$OUT_DIR"
