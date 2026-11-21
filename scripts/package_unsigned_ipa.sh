#!/usr/bin/env bash
# 将未签名的 .xcarchive 打包为标准 Payload/ 结构的 IPA。
# 不执行任何签名、重签名或证书注入。
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <path-to-AtlasNotes.xcarchive> <output-dir>" >&2
  exit 64
fi

ARCHIVE_PATH="$1"
OUT_DIR="$2"
APP_PATH="$ARCHIVE_PATH/Products/Applications/AtlasNotes.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app not found at $APP_PATH" >&2
  find "$ARCHIVE_PATH/Products" -maxdepth 3 -type d -name "*.app" >&2 || true
  exit 66
fi

mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
IPA_PATH="$OUT_DIR/AtlasNotes-unsigned.ipa"
STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT

mkdir -p "$STAGING_DIR/Payload"
/usr/bin/ditto "$APP_PATH" "$STAGING_DIR/Payload/AtlasNotes.app"
rm -f "$IPA_PATH"
(cd "$STAGING_DIR" && /usr/bin/zip -qry "$IPA_PATH" Payload)

echo "==> IPA metadata"
/usr/bin/unzip -l "$IPA_PATH"
/usr/bin/unzip -l "$IPA_PATH" | grep -q "Payload/AtlasNotes.app/Info.plist"
/usr/bin/du -h "$IPA_PATH"

echo "==> SHA256"
/usr/bin/shasum -a 256 "$IPA_PATH"

echo "==> Signature check (unsigned build is expected)"
if /usr/bin/codesign -dv "$APP_PATH" >/dev/null 2>&1; then
  echo "warning: archive unexpectedly contains a code signature"
  /usr/bin/codesign -dv "$APP_PATH" 2>&1 || true
else
  echo "verified: archive is unsigned (codesign returned non-zero)"
fi
