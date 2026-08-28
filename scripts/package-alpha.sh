#!/usr/bin/env bash

set -euo pipefail

pilp_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pilp_repo_dir="$(cd "$pilp_script_dir/.." && pwd)"
pilp_version="${1:-}"
pilp_build_number="${2:-}"
pilp_dist_dir="$pilp_repo_dir/dist"
pilp_release_dir="$pilp_dist_dir/releases"
pilp_archive_name="Pilp-$pilp_version-alpha.$pilp_build_number.zip"
pilp_archive="$pilp_release_dir/$pilp_archive_name"
pilp_checksum="$pilp_archive.sha256"
pilp_app="$pilp_dist_dir/Pilp.app"

if [[ ! "$pilp_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Usage: $0 <version, e.g. 0.1.0> <positive build number>" >&2
    exit 1
fi

if [[ ! "$pilp_build_number" =~ ^[1-9][0-9]*$ ]]; then
    echo "Build number must be a positive integer." >&2
    exit 1
fi

mkdir -p "$pilp_release_dir"

PILP_VERSION="$pilp_version" \
PILP_BUILD_NUMBER="$pilp_build_number" \
PILP_CODESIGN_IDENTITY="-" \
    "$pilp_script_dir/build-app.sh"

codesign --verify --deep --strict "$pilp_app"

pilp_built_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$pilp_app/Contents/Info.plist")"
pilp_built_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$pilp_app/Contents/Info.plist")"

if [[ "$pilp_built_version" != "$pilp_version" || "$pilp_built_number" != "$pilp_build_number" ]]; then
    echo "Built app version does not match the requested Alpha version." >&2
    exit 1
fi

if [[ -e "$pilp_archive" ]]; then
    rm "$pilp_archive"
fi

if [[ -e "$pilp_checksum" ]]; then
    rm "$pilp_checksum"
fi

ditto \
    -c \
    -k \
    --sequesterRsrc \
    --keepParent \
    "$pilp_app" \
    "$pilp_archive"

(
    cd "$pilp_release_dir"
    shasum -a 256 "$pilp_archive_name" > "$pilp_archive_name.sha256"
)

echo "Unsigned Alpha archive: $pilp_archive"
echo "SHA-256 checksum: $pilp_checksum"
echo "Suggested GitHub prerelease tag: v$pilp_version-alpha.$pilp_build_number"
echo "This Alpha is ad-hoc signed, is not notarized, and does not update appcast.xml."
