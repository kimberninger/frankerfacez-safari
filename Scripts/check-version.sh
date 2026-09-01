#!/bin/bash
#
# Checks that a release tag agrees with the version the project declares.
#
#   Scripts/check-version.sh v1.1
#
# The tag is only a label; the built app reports whatever manifest.json and
# MARKETING_VERSION say. If they disagree, a release ships claiming the wrong
# version, so this refuses the build instead.

set -euo pipefail

cd "$(dirname "$0")/.."

TAG="${1:?usage: check-version.sh <tag>}"
WANT="${TAG#v}"

MANIFEST=$(python3 -c \
	'import json;print(json.load(open("Shared (Extension)/Resources/manifest.json"))["version"])')

# Every build configuration must agree, otherwise Debug and Release could
# report different versions.
MARKETING=$(grep -oE 'MARKETING_VERSION = [^;]+;' FrankerFaceZ.xcodeproj/project.pbxproj \
	| sed 's/MARKETING_VERSION = //;s/;//' | sort -u)

echo "tag:               $TAG (expects version $WANT)"
echo "manifest.json:     $MANIFEST"
echo "MARKETING_VERSION: $(echo "$MARKETING" | tr '\n' ' ')"

status=0

if [ "$(echo "$MARKETING" | wc -l)" -ne 1 ]; then
	echo "error: build configurations declare different MARKETING_VERSION values." >&2
	status=1
elif [ "$MARKETING" != "$WANT" ]; then
	echo "error: MARKETING_VERSION is $MARKETING, tag expects $WANT." >&2
	status=1
fi

if [ "$MANIFEST" != "$WANT" ]; then
	echo "error: manifest.json version is $MANIFEST, tag expects $WANT." >&2
	status=1
fi

if [ "$status" -ne 0 ]; then
	echo >&2
	echo "Bump both to $WANT, commit, then move the tag." >&2
	exit 1
fi

echo "ok: everything agrees on $WANT"
