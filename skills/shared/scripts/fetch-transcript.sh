#!/usr/bin/env bash
set -euo pipefail

# fetch-transcript.sh — Extract YouTube transcript and metadata using yt-dlp
# Usage: fetch-transcript.sh "<YouTube URL>"
# Output: TITLE, CHANNEL, DESCRIPTION, and TRANSCRIPT to stdout
# Exit 1 on failure with error message to stderr

URL="${1:-}"

if [ -z "$URL" ]; then
  echo "Error: No URL provided. Usage: fetch-transcript.sh \"<YouTube URL>\"" >&2
  exit 1
fi

if ! command -v yt-dlp &>/dev/null; then
  echo "Error: yt-dlp is not installed. Install it with: brew install yt-dlp" >&2
  exit 1
fi

# Create a temp directory for subtitle files
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Extract metadata (title, channel, description) via JSON
METADATA="$(yt-dlp --dump-json --no-warnings "$URL" 2>/dev/null)" || {
  echo "Error: Video not found or is private." >&2
  exit 1
}

TITLE="$(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('title',''))")"
CHANNEL="$(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('channel',''))")"
DESCRIPTION="$(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('description',''))")"

# Download subtitles — prefer manual English, fall back to auto-generated
yt-dlp \
  --write-subs --write-auto-subs \
  --sub-langs "en,-live_chat" \
  --sub-format vtt \
  --skip-download \
  --no-warnings \
  --quiet \
  -o "${WORK_DIR}/subs" \
  "$URL" 2>/dev/null

# Find the subtitle file (yt-dlp names it subs.en.vtt or similar)
SUB_FILE="$(find "$WORK_DIR" -name "*.vtt" -type f | head -1)"

if [ -z "$SUB_FILE" ]; then
  echo "Error: No subtitles available for this video." >&2
  exit 1
fi

# Strip VTT formatting: remove header, timestamps, tags, music notes, and deduplicate lines
TRANSCRIPT="$(sed -e '/^WEBVTT/d' \
  -e '/^Kind:/d' \
  -e '/^Language:/d' \
  -e '/^$/d' \
  -e '/^[0-9][0-9]:[0-9][0-9]/d' \
  -e 's/<[^>]*>//g' \
  -e 's/♪//g' \
  -e 's/\[[^]]*\]//g' \
  "$SUB_FILE" | awk '!seen[$0]++' | sed -e 's/^[[:space:]]*//' -e '/^$/d')"

# Output in the expected format
echo "TITLE: ${TITLE}"
echo "CHANNEL: ${CHANNEL}"
echo "DESCRIPTION:"
echo "${DESCRIPTION}"
echo ""
echo "TRANSCRIPT:"
echo "${TRANSCRIPT}"
