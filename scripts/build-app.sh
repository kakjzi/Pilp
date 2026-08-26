#!/usr/bin/env bash

set -euo pipefail

pilp_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pilp_repo_dir="$(cd "$pilp_script_dir/.." && pwd)"
pilp_swift_bin="${PILP_SWIFT_BIN:-$(xcrun --find swift)}"
pilp_sdk_root="${PILP_SDK_ROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
pilp_module_cache="$pilp_repo_dir/.build/ModuleCache"
pilp_dist_dir="$pilp_repo_dir/dist"
pilp_app_dir="$pilp_dist_dir/Pilp.app"

mkdir -p "$pilp_module_cache" "$pilp_dist_dir"

env \
    CLANG_MODULE_CACHE_PATH="$pilp_module_cache" \
    SWIFTPM_MODULECACHE_OVERRIDE="$pilp_module_cache" \
    SDKROOT="$pilp_sdk_root" \
    "$pilp_swift_bin" build -c release --product Pilp

pilp_bin_dir="$(
    env \
        CLANG_MODULE_CACHE_PATH="$pilp_module_cache" \
        SWIFTPM_MODULECACHE_OVERRIDE="$pilp_module_cache" \
        SDKROOT="$pilp_sdk_root" \
        "$pilp_swift_bin" build -c release --show-bin-path
)"

if [[ "$pilp_app_dir" != "$pilp_repo_dir/dist/Pilp.app" ]]; then
    echo "Refusing to replace an unexpected app path: $pilp_app_dir" >&2
    exit 1
fi

rm -rf "$pilp_app_dir"
mkdir -p "$pilp_app_dir/Contents/MacOS" "$pilp_app_dir/Contents/Resources"

install -m 755 "$pilp_bin_dir/Pilp" "$pilp_app_dir/Contents/MacOS/Pilp"
install -m 644 "$pilp_repo_dir/Support/Info.plist" "$pilp_app_dir/Contents/Info.plist"

codesign --force --sign - "$pilp_app_dir"

echo "$pilp_app_dir"
