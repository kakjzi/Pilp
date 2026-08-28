#!/usr/bin/env bash

set -euo pipefail

pilp_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pilp_repo_dir="$(cd "$pilp_script_dir/.." && pwd)"
pilp_swift_bin="${PILP_SWIFT_BIN:-$(xcrun --find swift)}"
pilp_sdk_root="${PILP_SDK_ROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
pilp_module_cache="$pilp_repo_dir/.build/ModuleCache"
pilp_dist_dir="$pilp_repo_dir/dist"
pilp_app_dir="$pilp_dist_dir/Pilp.app"
pilp_version="${PILP_VERSION:-}"
pilp_build_number="${PILP_BUILD_NUMBER:-}"
pilp_codesign_identity="${PILP_CODESIGN_IDENTITY:--}"
pilp_swiftpm_flags=(--disable-keychain)

if [[ "${PILP_SWIFTPM_DISABLE_SANDBOX:-0}" == "1" ]]; then
    pilp_swiftpm_flags+=(--disable-sandbox)
fi

mkdir -p "$pilp_module_cache" "$pilp_dist_dir"

env \
    CLANG_MODULE_CACHE_PATH="$pilp_module_cache" \
    SWIFTPM_MODULECACHE_OVERRIDE="$pilp_module_cache" \
    SDKROOT="$pilp_sdk_root" \
    "$pilp_swift_bin" build "${pilp_swiftpm_flags[@]}" -c release --product Pilp

pilp_bin_dir="$(
    env \
        CLANG_MODULE_CACHE_PATH="$pilp_module_cache" \
        SWIFTPM_MODULECACHE_OVERRIDE="$pilp_module_cache" \
        SDKROOT="$pilp_sdk_root" \
        "$pilp_swift_bin" build "${pilp_swiftpm_flags[@]}" -c release --show-bin-path
)"

if [[ "$pilp_app_dir" != "$pilp_repo_dir/dist/Pilp.app" ]]; then
    echo "Refusing to replace an unexpected app path: $pilp_app_dir" >&2
    exit 1
fi

pilp_sparkle_framework="$pilp_bin_dir/Sparkle.framework"
if [[ ! -d "$pilp_sparkle_framework" ]]; then
    echo "Sparkle.framework was not produced by SwiftPM: $pilp_sparkle_framework" >&2
    exit 1
fi

rm -rf "$pilp_app_dir"
mkdir -p \
    "$pilp_app_dir/Contents/MacOS" \
    "$pilp_app_dir/Contents/Resources" \
    "$pilp_app_dir/Contents/Frameworks"

install -m 755 "$pilp_bin_dir/Pilp" "$pilp_app_dir/Contents/MacOS/Pilp"
install -m 644 "$pilp_repo_dir/Support/Info.plist" "$pilp_app_dir/Contents/Info.plist"
ditto "$pilp_sparkle_framework" "$pilp_app_dir/Contents/Frameworks/Sparkle.framework"

if [[ -n "$pilp_version" ]]; then
    /usr/libexec/PlistBuddy \
        -c "Set :CFBundleShortVersionString $pilp_version" \
        "$pilp_app_dir/Contents/Info.plist"
fi

if [[ -n "$pilp_build_number" ]]; then
    /usr/libexec/PlistBuddy \
        -c "Set :CFBundleVersion $pilp_build_number" \
        "$pilp_app_dir/Contents/Info.plist"
fi

if [[ "$pilp_codesign_identity" != "-" ]]; then
    pilp_sparkle_version="$pilp_app_dir/Contents/Frameworks/Sparkle.framework/Versions/B"
    pilp_distribution_signing=(
        --force
        --sign "$pilp_codesign_identity"
        --options runtime
        --timestamp
    )

    codesign "${pilp_distribution_signing[@]}" \
        "$pilp_sparkle_version/XPCServices/Installer.xpc"
    codesign "${pilp_distribution_signing[@]}" \
        --preserve-metadata=entitlements \
        "$pilp_sparkle_version/XPCServices/Downloader.xpc"
    codesign "${pilp_distribution_signing[@]}" \
        "$pilp_sparkle_version/Autoupdate"
    codesign "${pilp_distribution_signing[@]}" \
        "$pilp_sparkle_version/Updater.app"
    codesign "${pilp_distribution_signing[@]}" \
        "$pilp_app_dir/Contents/Frameworks/Sparkle.framework"
    codesign "${pilp_distribution_signing[@]}" "$pilp_app_dir"
else
    codesign --force --sign - "$pilp_app_dir"
fi

codesign --verify --deep --strict "$pilp_app_dir"

echo "$pilp_app_dir"
