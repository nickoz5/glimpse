#!/usr/bin/env bash
set -euo pipefail

SOURCE_ICON="${1:-src/icons/icon-large.png}"

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "Icon source not found: $SOURCE_ICON" >&2
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "sips is required to inspect PNG dimensions on macOS." >&2
  exit 1
fi

WIDTH="$(sips -g pixelWidth "$SOURCE_ICON" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
HEIGHT="$(sips -g pixelHeight "$SOURCE_ICON" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"

if [[ -z "$WIDTH" || -z "$HEIGHT" ]]; then
  echo "Unable to read PNG dimensions for: $SOURCE_ICON" >&2
  exit 1
fi

if [[ "$WIDTH" != "$HEIGHT" ]]; then
  echo "Warning: source icon is ${WIDTH}x${HEIGHT}; packaging icons should ideally be square." >&2
fi

if (( WIDTH < 1024 || HEIGHT < 1024 )); then
  echo "Warning: source icon is below 1024x1024; generated icons may look soft at large sizes." >&2
fi

npm exec -- tauri icon "$SOURCE_ICON"

echo "Regenerated Tauri icons from $SOURCE_ICON"

