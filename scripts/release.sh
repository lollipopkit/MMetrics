#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  MMetrics — local release
#  Builds a Developer ID–signed, notarised DMG and publishes it as a GitHub Release.
#
#  Usage: ./scripts/release.sh <version>        e.g. ./scripts/release.sh 2.1.0
#
#  Requirements (one-time):
#    • "Developer ID Application" certificate in the login keychain
#    • notarytool credentials stored in the keychain:
#        xcrun notarytool store-credentials mmetrics-notary \
#            --apple-id <apple-id> --team-id <team-id>
#      (prompts for an app-specific password; nothing is written to disk in the repo)
#    • gh authenticated for the repo
#
#  Env overrides:
#    MMETRICS_SIGN_ID      codesign identity (default: first Developer ID Application)
#    MMETRICS_NOTARY_PROFILE  notarytool keychain profile (default: mmetrics-notary)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

cd "$(dirname "$0")/.."

PBXPROJ="MMetrics.xcodeproj/project.pbxproj"
CASK="Casks/mmetrics.rb"
NOTARY_PROFILE="${MMETRICS_NOTARY_PROFILE:-mmetrics-notary}"

G='\033[0;32m' B='\033[0;34m' R='\033[0;31m' D='\033[2m' NC='\033[0m' BOLD='\033[1m'
step() { printf "  ${B}→${NC}  %s\n" "$1"; }
ok()   { printf "  ${G}✓${NC}  %s\n" "$1"; }
fail() { printf "  ${R}✗${NC}  %s\n" "$1"; exit 1; }

# ── Arguments ────────────────────────────────────────────────────────────────
VERSION="${1:-}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Usage: $0 <major.minor.patch>"
TAG="v$VERSION"

echo ""
echo -e "${BOLD}  MMetrics release $TAG${NC}"
echo ""

# ── Preflight ────────────────────────────────────────────────────────────────
step "Checking repository state..."
[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || fail "Release from main"
[ -z "$(git status --porcelain)" ] || fail "Working tree is not clean"
git fetch --quiet origin main --tags
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || fail "main is not in sync with origin/main"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && fail "Tag $TAG already exists"
ok "Clean main, $TAG is new"

step "Checking signing identity..."
if [ -z "${MMETRICS_SIGN_ID:-}" ]; then
    MMETRICS_SIGN_ID=$(security find-identity -v -p codesigning \
        | sed -n 's/^ *[0-9]*) \([0-9A-F]\{40\}\) "Developer ID Application: .*"$/\1/p' | head -1)
fi
[ -n "$MMETRICS_SIGN_ID" ] || fail "No Developer ID Application identity in the keychain"
SIGN_NAME=$(security find-identity -v -p codesigning | grep "$MMETRICS_SIGN_ID" | sed 's/.*"\(.*\)"/\1/' | head -1)
[ -n "$SIGN_NAME" ] || fail "Identity $MMETRICS_SIGN_ID not found"
export MMETRICS_SIGN_ID
ok "$SIGN_NAME"

step "Checking notarytool profile '$NOTARY_PROFILE'..."
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 \
    || fail "notarytool profile '$NOTARY_PROFILE' missing — see the header of this script"
ok "Notary credentials available"

gh auth status >/dev/null 2>&1 || fail "gh is not authenticated"

# From here on the working tree is modified; on failure before the commit, say how to undo.
MODIFIED=0 COMMITTED=0
cleanup() {
    local rc=$?
    if [ $rc -ne 0 ] && [ $MODIFIED = 1 ] && [ $COMMITTED = 0 ]; then
        printf "\n  ${R}Release aborted.${NC} Undo local edits with:\n    git checkout -- %s %s\n\n" \
            "$PBXPROJ" "$CASK"
    fi
}
trap cleanup EXIT

# ── Version bump ─────────────────────────────────────────────────────────────
BUILD=$(( $(sed -n 's/.*CURRENT_PROJECT_VERSION = \([0-9]*\);/\1/p' "$PBXPROJ" | head -1) + 1 ))
step "Setting version $VERSION (build $BUILD)..."
MODIFIED=1
sed -i '' -e "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $VERSION;/" \
          -e "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $BUILD;/" "$PBXPROJ"
ok "Version bumped"

# ── Build + sign ─────────────────────────────────────────────────────────────
step "Building signed DMG..."
MMETRICS_VERSION="$VERSION" ./scripts/build-dmg.sh
DMG="dist/MMetrics-$VERSION.dmg"
APP="dist/dmg-staging/MMetrics.app"
[ -f "$DMG" ] || fail "DMG not produced: $DMG"

codesign --verify --deep --strict "$APP"
# Capture first: `codesign | grep -q` trips pipefail when grep exits early (SIGPIPE).
SIG_INFO=$(codesign -dvv "$APP" 2>&1)
grep -q "flags=.*runtime" <<< "$SIG_INFO" || fail "Hardened runtime not enabled"
grep -q "^Authority=Developer ID Application" <<< "$SIG_INFO" || fail "App not signed with Developer ID"
[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")" = "$VERSION" ] \
    || fail "App version does not match $VERSION"
ok "Signed with Developer ID, hardened runtime on"

# ── Notarise + staple ────────────────────────────────────────────────────────
step "Notarising (usually a few minutes)..."
RESULT=$(xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" \
    --wait --output-format json)
STATUS=$(plutil -extract status raw - <<< "$RESULT")
if [ "$STATUS" != "Accepted" ]; then
    ID=$(plutil -extract id raw - <<< "$RESULT" 2>/dev/null || true)
    [ -n "$ID" ] && xcrun notarytool log "$ID" --keychain-profile "$NOTARY_PROFILE" || true
    fail "Notarisation status: $STATUS"
fi
xcrun stapler staple "$DMG" >/dev/null
xcrun stapler validate "$DMG" >/dev/null
spctl --assess --type open --context context:primary-signature "$DMG" \
    || fail "Gatekeeper rejected the DMG"
ok "Notarised and stapled"

# ── Cask ─────────────────────────────────────────────────────────────────────
SHA=$(shasum -a 256 "$DMG" | awk '{print $1}')
sed -i '' -e "s/^  version \".*\"/  version \"$VERSION\"/" \
          -e "s/^  sha256 \".*\"/  sha256 \"$SHA\"/" "$CASK"
ok "Cask → $VERSION ($SHA)"

# ── Commit, tag, push ────────────────────────────────────────────────────────
step "Committing and tagging..."
git add "$PBXPROJ" "$CASK"
git commit --quiet -m "chore: release $TAG (build $BUILD)"
COMMITTED=1
git tag -a "$TAG" -m "MMetrics $TAG"
git push --quiet origin main
git push --quiet origin "$TAG"
ok "Pushed main and $TAG"

# ── GitHub Release ───────────────────────────────────────────────────────────
step "Publishing GitHub Release..."
gh release create "$TAG" "$DMG" --title "MMetrics $TAG" --generate-notes --verify-tag \
    || fail "Upload failed — retry: gh release create $TAG $DMG --title 'MMetrics $TAG' --generate-notes --verify-tag"
ok "$(gh release view "$TAG" --json url -q .url)"

echo ""
echo -e "  ${G}${BOLD}Released MMetrics $TAG${NC}"
echo ""
