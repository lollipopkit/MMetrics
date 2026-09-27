#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  MMetrics — DMG Builder
#  Creates a drag-to-Applications DMG for distribution
#  Usage: ./scripts/build-dmg.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT="MMetrics.xcodeproj"
SCHEME="MMetrics"
APP_NAME="MMetrics"
# Version: MMETRICS_VERSION if set, else MARKETING_VERSION from the project.
VERSION="${MMETRICS_VERSION:-$(sed -n 's/.*MARKETING_VERSION = \(.*\);/\1/p' "$PROJECT/project.pbxproj" | head -1)}"
[ -n "$VERSION" ] || { echo "Could not determine version"; exit 1; }
DIST="dist"
ARCHIVE="$DIST/$APP_NAME.xcarchive"
EXPORT="$DIST/export"
STAGING="$DIST/dmg-staging"
DMG_TEMP="$DIST/temp.dmg"
DMG_FINAL="$DIST/MMetrics-$VERSION.dmg"
VOL_NAME="MMetrics $VERSION"

G='\033[0;32m' B='\033[0;34m' Y='\033[1;33m' R='\033[0;31m'
W='\033[1;37m' D='\033[2m' NC='\033[0m' BOLD='\033[1m'

step() { printf "  ${B}→${NC}  %s\n" "$1"; }
ok()   { printf "  ${G}✓${NC}  %s\n" "$1"; }
fail() { printf "  ${R}✗${NC}  %s\n" "$1"; exit 1; }

echo ""
echo -e "${BOLD}${W}  MMetrics DMG Builder  v${VERSION}${NC}"
echo -e "${D}  ────────────────────────────────────${NC}"
echo ""

# ── Clean ─────────────────────────────────────────────────────────────────────
step "Cleaning previous build..."
rm -rf "$DIST"
mkdir -p "$DIST" "$STAGING"
ok "Clean"

# ── Archive ───────────────────────────────────────────────────────────────────
step "Building Release archive (this takes ~1 min)..."

# In CI show full output so failures are visible; locally filter to keep it tidy
XCODE_OUTPUT_CMD="grep -E '^(error:|warning:|Archive|BUILD)' || true"
[ -n "${CI:-}" ] && XCODE_OUTPUT_CMD="cat"

xcodebuild archive \
    -project "$PROJECT" \
    -scheme  "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    DEVELOPMENT_TEAM="" \
    2>&1 | eval "$XCODE_OUTPUT_CMD"

[ -d "$ARCHIVE" ] || fail "Archive failed — check the xcodebuild output above"
ok "Archive complete"

# ── Export .app ───────────────────────────────────────────────────────────────
step "Exporting .app..."

cat > "$DIST/ExportOptions.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath  "$EXPORT" \
    -exportOptionsPlist "$DIST/ExportOptions.plist" \
    2>&1 | grep -E "^(error:|Export|BUILD)" || true

# Find the .app (try export path first, fall back to archive Products)
APP_PATH=$(find "$EXPORT"   -name "*.app" -maxdepth 2 | head -1)
[ -z "$APP_PATH" ] && APP_PATH=$(find "$ARCHIVE/Products" -name "*.app" | head -1)
[ -z "$APP_PATH" ] && fail "Could not find exported .app"
ok "Exported: $(basename "$APP_PATH")"

# ── Build privileged helper and embed it in the app bundle ───────────────────
# The Homebrew Cask postflight copies this binary out of Contents/MacOS/ into
# /Users/Shared/MMetrics and grants it passwordless sudo for SMC + IOReport
# reads. If it's missing, brew install --cask mmetrics fails with
#   cp: ...MMetrics.app/Contents/MacOS/mmetrics-helper: No such file
# (see issue #4). Compile from helper/ and drop the binary in alongside the app.
step "Building mmetrics-helper..."
HELPER_OUT="$APP_PATH/Contents/MacOS/mmetrics-helper"
clang -fobjc-arc \
    -framework Foundation -framework IOKit \
    -F/System/Library/PrivateFrameworks -lIOReport \
    -I MMetrics \
    helper/mmetrics-helper.m \
    MMetrics/IOReportWrapper.m \
    MMetrics/SMC.c \
    -o "$HELPER_OUT"
chmod +x "$HELPER_OUT"
[ -x "$HELPER_OUT" ] || fail "Helper compile failed — see clang output above"
ok "Helper embedded: $(basename "$HELPER_OUT")"

# ── Re-sign the bundle ────────────────────────────────────────────────────────
# Dropping the helper in after -exportArchive invalidates the bundle seal, which
# left shipped builds reporting "code object is not signed at all". That was
# survivable while the app was a single executable, but macOS refuses to load an
# app extension inside an invalidly signed host — the widget silently never
# appears in the gallery.
#
# Sign inside-out: nested code first, then the outer bundle.
# MMETRICS_SIGN_ID unset → ad-hoc (`-`) for local builds. A Developer ID identity
# (scripts/release.sh) also enables the hardened runtime and a secure timestamp,
# both required for notarisation.
step "Signing bundle (inside-out)..."
SIGN_ID="${MMETRICS_SIGN_ID:--}"
if [ "$SIGN_ID" = "-" ]; then
    SIGN_FLAGS=(--force --sign - --timestamp=none)
else
    SIGN_FLAGS=(--force --sign "$SIGN_ID" --timestamp --options runtime)
fi

codesign "${SIGN_FLAGS[@]}" "$HELPER_OUT" || fail "Failed to sign mmetrics-helper"

APPEX="$APP_PATH/Contents/PlugIns/MMetricsWidget.appex"
[ -d "$APPEX" ] || fail "Widget extension missing: $APPEX"
codesign "${SIGN_FLAGS[@]}" \
    --entitlements "$(dirname "$0")/../MMetricsWidget/MMetricsWidget.entitlements" \
    "$APPEX" || fail "Failed to sign widget extension"
ok "Signed: MMetricsWidget.appex"

codesign "${SIGN_FLAGS[@]}" \
    --entitlements "$(dirname "$0")/../MMetrics/MMetrics.entitlements" \
    "$APP_PATH" || fail "Failed to sign app bundle"

codesign --verify --deep --strict "$APP_PATH" \
    || fail "Signature verification failed after re-signing"
ok "Signature valid (deep, strict)"

# ── Remove quarantine ─────────────────────────────────────────────────────────
step "Removing quarantine flag..."
xattr -rd com.apple.quarantine "$APP_PATH" 2>/dev/null || true
ok "Quarantine cleared"

# ── Stage DMG contents ────────────────────────────────────────────────────────
step "Staging DMG contents..."
cp -R "$APP_PATH" "$STAGING/"

# Applications symlink — gives users the drag-and-drop target
ln -s /Applications "$STAGING/Applications"
ok "Staged"

# ── Create DMG ────────────────────────────────────────────────────────────────
step "Creating DMG..."

if [ -n "${CI:-}" ]; then
    # ── CI: create compressed DMG directly (no Finder/AppleScript on headless runner)
    hdiutil create \
        -volname   "$VOL_NAME" \
        -srcfolder "$STAGING" \
        -ov \
        -format    UDZO \
        -imagekey  zlib-level=9 \
        -fs        HFS+ \
        "$DMG_FINAL" > /dev/null
else
    # ── Local: create writable DMG, set pretty Finder window layout, then compress
    hdiutil create \
        -volname   "$VOL_NAME" \
        -srcfolder "$STAGING" \
        -ov \
        -format    UDRW \
        -fs        HFS+ \
        "$DMG_TEMP" > /dev/null

    # Mount — use tab-field split so volume names with spaces work correctly
    MOUNT=$(hdiutil attach "$DMG_TEMP" -readwrite -nobrowse | awk -F'\t' '/\/Volumes\//{gsub(/^[[:space:]]+/,"",$NF); print $NF}')

    osascript <<APPLESCRIPT > /dev/null 2>&1 || true
tell application "Finder"
  tell disk "$VOL_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {400, 100, 900, 400}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 100
    set position of item "$(basename "$APP_PATH")" of container window to {130, 145}
    set position of item "Applications" of container window to {370, 145}
    close
    open
    update without registering applications
    delay 2
    close
  end tell
end tell
APPLESCRIPT

    hdiutil detach "$MOUNT" -quiet

    hdiutil convert "$DMG_TEMP" \
        -format UDZO \
        -imagekey zlib-level=9 \
        -o "$DMG_FINAL" > /dev/null
    rm -f "$DMG_TEMP"
fi
ok "Compressed"

if [ "$SIGN_ID" != "-" ]; then
    codesign --force --sign "$SIGN_ID" --timestamp "$DMG_FINAL" || fail "Failed to sign DMG"
    ok "Signed: $(basename "$DMG_FINAL")"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
SIZE=$(du -sh "$DMG_FINAL" | awk '{print $1}')
echo ""
echo -e "  ${G}${BOLD}Done!${NC}"
echo ""
echo -e "  ${W}Output:${NC}   $DMG_FINAL  (${SIZE})"
echo ""
echo -e "  ${D}To sign, notarise and publish: ./scripts/release.sh <version>${NC}"
echo ""
