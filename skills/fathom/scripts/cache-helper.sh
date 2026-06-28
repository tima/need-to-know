#!/usr/bin/env bash
# Cache fetched content to avoid re-downloading (1hr TTL)
# Usage: cache-helper.sh get|set <url-hash> [content]

set -euo pipefail

CACHE_DIR="/tmp/need-to-know-cache"
TTL=3600  # 1 hour

case "$1" in
  get)
    FILE="$CACHE_DIR/$2"
    if [ -f "$FILE" ]; then
      # macOS uses stat -f %m, Linux uses stat -c %Y
      AGE=$(($(date +%s) - $(stat -f %m "$FILE" 2>/dev/null || stat -c %Y "$FILE")))
      if [ $AGE -lt $TTL ]; then
        cat "$FILE"
        exit 0
      fi
      rm "$FILE"
    fi
    exit 1
    ;;
  set)
    mkdir -p "$CACHE_DIR"
    cat > "$CACHE_DIR/$2"
    ;;
  *)
    echo "Usage: cache-helper.sh get|set <url-hash> [content]" >&2
    exit 1
    ;;
esac
