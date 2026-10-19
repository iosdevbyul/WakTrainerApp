#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
archive="${1:-$HOME/Downloads/WakTrainerBrandAssets.zip}"

if [[ ! -f "$archive" ]]; then
  echo "Missing icon asset archive: $archive" >&2
  exit 1
fi

unzip -o "$archive" \
  'WakTrainer/Assets.xcassets/AppIcon.appiconset/*' \
  'WakTrainer/Assets.xcassets/TrisSplashLogo.imageset/*' \
  -d "$repo_root"

test -s "$repo_root/WakTrainer/Assets.xcassets/AppIcon.appiconset/TrisAppIcon.png"
test -s "$repo_root/WakTrainer/Assets.xcassets/TrisSplashLogo.imageset/TrisSplashLogo.png"

echo "Original T logo installed as app icon and centered splash image."
git -C "$repo_root" status --short -- WakTrainer/Assets.xcassets
