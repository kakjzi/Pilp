#!/usr/bin/env bash

set -euo pipefail

pilp_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pilp_repo_dir="$(cd "$pilp_script_dir/.." && pwd)"
pilp_version="${1:-}"
pilp_build_number="${2:-}"
pilp_codesign_identity="${PILP_CODESIGN_IDENTITY:-}"
pilp_notary_profile="${PILP_NOTARY_PROFILE:-}"
pilp_dist_dir="$pilp_repo_dir/dist"
pilp_release_dir="$pilp_dist_dir/releases"
pilp_archive="$pilp_release_dir/Pilp-$pilp_version.zip"
pilp_notary_archive="$pilp_release_dir/Pilp-$pilp_version-notary.zip"
pilp_appcast="$pilp_repo_dir/appcast.xml"
pilp_appcast_staging="$pilp_release_dir/appcast.xml"
pilp_generate_appcast="$pilp_repo_dir/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"

if [[ ! "$pilp_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Usage: $0 <version, e.g. 0.2.0> <positive build number>" >&2
    exit 1
fi

if [[ ! "$pilp_build_number" =~ ^[1-9][0-9]*$ ]]; then
    echo "Build number must be a positive integer." >&2
    exit 1
fi

if [[ -z "$pilp_codesign_identity" ]]; then
    echo "PILP_CODESIGN_IDENTITY must name a Developer ID Application certificate." >&2
    exit 1
fi

if [[ -z "$pilp_notary_profile" ]]; then
    echo "PILP_NOTARY_PROFILE must name a notarytool Keychain profile." >&2
    exit 1
fi

if ! security find-identity -v -p codesigning \
    | grep -F "\"$pilp_codesign_identity\"" >/dev/null; then
    echo "Code signing identity not found: $pilp_codesign_identity" >&2
    exit 1
fi

if [[ ! -x "$pilp_generate_appcast" ]]; then
    echo "Sparkle release tools are missing. Resolve the Swift package first." >&2
    exit 1
fi

mkdir -p "$pilp_release_dir"

PILP_VERSION="$pilp_version" \
PILP_BUILD_NUMBER="$pilp_build_number" \
PILP_CODESIGN_IDENTITY="$pilp_codesign_identity" \
    "$pilp_script_dir/build-app.sh"

if [[ -e "$pilp_notary_archive" ]]; then
    rm "$pilp_notary_archive"
fi

ditto \
    -c \
    -k \
    --sequesterRsrc \
    --keepParent \
    "$pilp_dist_dir/Pilp.app" \
    "$pilp_notary_archive"

xcrun notarytool submit \
    "$pilp_notary_archive" \
    --keychain-profile "$pilp_notary_profile" \
    --wait
xcrun stapler staple -v "$pilp_dist_dir/Pilp.app"
xcrun stapler validate -v "$pilp_dist_dir/Pilp.app"
rm "$pilp_notary_archive"

if [[ -e "$pilp_archive" ]]; then
    rm "$pilp_archive"
fi

ditto \
    -c \
    -k \
    --sequesterRsrc \
    --keepParent \
    "$pilp_dist_dir/Pilp.app" \
    "$pilp_archive"

install -m 644 "$pilp_appcast" "$pilp_appcast_staging"

"$pilp_generate_appcast" \
    --account com.kakjzi.Pilp \
    --download-url-prefix "https://github.com/kakjzi/Pilp/releases/download/v$pilp_version/" \
    --link "https://github.com/kakjzi/Pilp" \
    --maximum-deltas 0 \
    "$pilp_release_dir"

install -m 644 "$pilp_appcast_staging" "$pilp_appcast"

echo "Release archive: $pilp_archive"
echo "Updated appcast: $pilp_appcast"
