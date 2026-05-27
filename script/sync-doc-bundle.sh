#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="$ROOT_DIR/web"
DIST_DIR="$WEB_DIR/dist"
BUNDLE_DIR="$ROOT_DIR/iOS/note/doc.bundle"

if [[ ! -f "$DIST_DIR/index.html" ]]; then
  echo "Missing web build output: $DIST_DIR/index.html" >&2
  echo "Run npm run build from $WEB_DIR first." >&2
  exit 1
fi

rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"
cp -R "$DIST_DIR"/. "$BUNDLE_DIR"/

echo "Synced web build to $BUNDLE_DIR"
