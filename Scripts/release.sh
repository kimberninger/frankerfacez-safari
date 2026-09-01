#!/bin/bash
#
# Builds a signed, notarised FrankerFaceZ.app that can be copied to any Mac
# and run without Xcode.
#
# Requires two things this script cannot create for you:
#
#   1. A "Developer ID Application" certificate in your keychain.
#      Xcode > Settings > Accounts > your team > Manage Certificates > + .
#
#   2. Notary credentials stored under a keychain profile, so no secret
#      lives in this repository:
#
#      xcrun notarytool store-credentials "$NOTARY_PROFILE" \
#          --apple-id "you@example.com" \
#          --team-id "$TEAM_ID" \
#          --password "<app-specific password from appleid.apple.com>"

set -euo pipefail

TEAM_ID="43PYD54WZT"
NOTARY_PROFILE="${NOTARY_PROFILE:-FrankerFaceZ}"

cd "$(dirname "$0")/.."
OUT="build/release"
ARCHIVE="$OUT/FrankerFaceZ.xcarchive"
APP="$OUT/FrankerFaceZ.app"
ZIP="$OUT/FrankerFaceZ.zip"

# Fail early with something readable, rather than deep inside xcodebuild.
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
	echo "error: no Developer ID Application certificate in the keychain." >&2
	echo "       Create one in Xcode > Settings > Accounts > Manage Certificates." >&2
	exit 1
fi

# A CI runner has no keychain profile to read, so credentials may also arrive
# through the environment. Whichever is used, nothing is written to the repo.
if [ -n "${NOTARY_APPLE_ID:-}" ]; then
	NOTARY_ARGS=(--apple-id "$NOTARY_APPLE_ID"
	             --password "$NOTARY_PASSWORD"
	             --team-id "${NOTARY_TEAM_ID:-$TEAM_ID}")
else
	NOTARY_ARGS=(--keychain-profile "$NOTARY_PROFILE")

	if ! xcrun notarytool history "${NOTARY_ARGS[@]}" >/dev/null 2>&1; then
		echo "error: no notary credentials stored under profile '$NOTARY_PROFILE'," >&2
		echo "       and NOTARY_APPLE_ID is not set. See the comment above." >&2
		exit 1
	fi
fi

rm -rf "$OUT"
mkdir -p "$OUT"

echo "==> Archiving"
xcodebuild -project FrankerFaceZ.xcodeproj \
	-scheme "FrankerFaceZ (macOS)" \
	-configuration Release \
	-destination "platform=macOS" \
	-archivePath "$ARCHIVE" \
	archive

echo "==> Exporting with Developer ID"
xcodebuild -exportArchive \
	-archivePath "$ARCHIVE" \
	-exportOptionsPlist Scripts/ExportOptions.plist \
	-exportPath "$OUT"

# The notary service takes an archive, not a bundle. ditto preserves the
# symlinks and extended attributes inside the app that zip would flatten.
echo "==> Submitting for notarisation (this waits for Apple to reply)"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" "${NOTARY_ARGS[@]}" --wait

# Stapling writes the notarisation ticket into the app itself, so the
# machine you install on does not have to ask Apple about it.
echo "==> Stapling the ticket"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

# Repackage now that the app carries its ticket; the earlier zip does not.
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo
echo "Done: $ZIP"
echo "Copy it to the other Mac, unzip, drag FrankerFaceZ.app to /Applications,"
echo "launch it once, then enable FrankerFaceZ in Safari Settings > Extensions."
