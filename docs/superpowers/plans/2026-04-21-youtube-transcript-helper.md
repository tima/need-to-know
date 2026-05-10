# YouTube Transcript Helper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `yt-dlp`-based helper script to the `/tldr` skill so YouTube transcript extraction actually works.

**Architecture:** A shell script (`fetch-transcript.sh`) uses `yt-dlp` to download subtitles and metadata, outputting plain text to stdout. The SKILL.md prompt is updated to call this script via the Bash tool instead of the broken WebFetch approach.

**Tech Stack:** Bash, `yt-dlp` (already installed), `python3` (for JSON parsing), `sed` (for VTT cleanup)

---

## File Structure

```
skills/tldr/
  SKILL.md                          # Modify: YouTube transcript and deep mode sections
  scripts/
    fetch-transcript.sh             # Create: helper script
```

---

### Task 1: Create the fetch-transcript.sh script

**Files:**
- Create: `skills/tldr/scripts/fetch-transcript.sh`

- [ ] **Step 1: Write a test to verify yt-dlp is callable**

Run this command to confirm `yt-dlp` is available and working:

```bash
which yt-dlp && yt-dlp --version
```

Expected: prints path and version number (e.g., `2026.03.17`).

- [ ] **Step 2: Create the script**

Create `skills/tldr/scripts/fetch-transcript.sh` with this content:

```bash
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
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

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
  -o "${TMPDIR}/subs" \
  "$URL" 2>/dev/null

# Find the subtitle file (yt-dlp names it subs.en.vtt or similar)
SUB_FILE="$(find "$TMPDIR" -name "*.vtt" -type f | head -1)"

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
  "$SUB_FILE" | awk '!seen[$0]++' | sed -e 's/^[[:space:]]*//' -e '/^$/d')"

# Output in the expected format
echo "TITLE: ${TITLE}"
echo "CHANNEL: ${CHANNEL}"
echo "DESCRIPTION:"
echo "${DESCRIPTION}"
echo ""
echo "TRANSCRIPT:"
echo "${TRANSCRIPT}"
```

- [ ] **Step 3: Make the script executable**

```bash
chmod +x skills/tldr/scripts/fetch-transcript.sh
```

- [ ] **Step 4: Test with a known video**

```bash
skills/tldr/scripts/fetch-transcript.sh "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

**Verify:**
- Exit code is 0
- Output starts with `TITLE: Rick Astley - Never Gonna Give You Up`
- `CHANNEL: Rick Astley` is present
- `DESCRIPTION:` section has the video description
- `TRANSCRIPT:` section has clean lyrics text (no VTT timestamps, no `♪` symbols, no HTML tags, no duplicate lines)

- [ ] **Step 5: Test error case — invalid URL**

```bash
skills/tldr/scripts/fetch-transcript.sh "https://www.youtube.com/watch?v=INVALID_VIDEO_ID_99999" 2>&1; echo "exit: $?"
```

**Verify:**
- Exit code is 1
- stderr contains "Error: Video not found or is private."

- [ ] **Step 6: Test error case — no argument**

```bash
skills/tldr/scripts/fetch-transcript.sh 2>&1; echo "exit: $?"
```

**Verify:**
- Exit code is 1
- stderr contains "Error: No URL provided."

- [ ] **Step 7: Commit**

```bash
git add skills/tldr/scripts/fetch-transcript.sh
git commit -m "feat: add yt-dlp helper script for YouTube transcript extraction"
```

---

### Task 2: Update SKILL.md YouTube transcript mode

**Files:**
- Modify: `skills/tldr/SKILL.md:54-60`

- [ ] **Step 1: Read the current SKILL.md**

Read `skills/tldr/SKILL.md` to confirm the exact lines to replace.

- [ ] **Step 2: Replace the YouTube default transcript section**

Replace the current YouTube default section (from `**YouTube — default (transcript mode):**` through the fallback message about `--deep`) with:

```markdown
**YouTube — default (transcript mode):**
- Run the helper script via Bash: `~/.claude/skills/tldr/scripts/fetch-transcript.sh "<URL>"`
- The script uses `yt-dlp` to extract the video title, channel, description, and transcript as plain text.
- Use the transcript as the primary content for summarization. The title, channel, and description provide context.
- If the script fails (non-zero exit), tell the user: "No transcript available for this video. You can try `--deep` for richer analysis using video metadata."
```

- [ ] **Step 3: Verify the edit**

Read `skills/tldr/SKILL.md` and confirm:
- The old WebFetch-based approach is gone
- The new section references `~/.claude/skills/tldr/scripts/fetch-transcript.sh`
- The fallback message is present

- [ ] **Step 4: Commit**

```bash
git add skills/tldr/SKILL.md
git commit -m "fix: replace WebFetch YouTube approach with yt-dlp helper script"
```

---

### Task 3: Update SKILL.md YouTube deep mode

**Files:**
- Modify: `skills/tldr/SKILL.md` (the `**YouTube — deep mode**` section)

- [ ] **Step 1: Read the current SKILL.md**

Read `skills/tldr/SKILL.md` to find the deep mode section.

- [ ] **Step 2: Replace the YouTube deep mode section**

Replace the current deep mode section (from `**YouTube — deep mode (`--deep` flag):**` through its last bullet) with:

```markdown
**YouTube — deep mode (`--deep` flag):**
- Tell the user: "Using deep analysis mode — pulling extended metadata alongside the transcript."
- Run the helper script via Bash to get the transcript: `~/.claude/skills/tldr/scripts/fetch-transcript.sh "<URL>"`
- Additionally, run `yt-dlp --dump-json --no-warnings "<URL>"` via Bash to get the full JSON metadata (tags, categories, chapters, like count, view count, upload date).
- Use both the transcript and the extended metadata to produce a richer, more contextualized summary.
- If the transcript is unavailable but metadata is available, summarize from metadata alone and note that no transcript was available.
```

- [ ] **Step 3: Verify the edit**

Read `skills/tldr/SKILL.md` and confirm:
- Deep mode now references both the helper script and `yt-dlp --dump-json`
- The fallback for transcript-unavailable-but-metadata-available is present

- [ ] **Step 4: Commit**

```bash
git add skills/tldr/SKILL.md
git commit -m "feat: enhance YouTube deep mode with yt-dlp extended metadata"
```

---

### Task 4: Integration test

- [ ] **Step 1: Test transcript mode with a real video**

In a Claude Code session, run:
```
/tldr https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

**Verify:**
- The helper script is called via Bash
- Transcript is extracted successfully
- Summary is generated from the transcript content
- Tone is conversational, non-substantive content (music notes, etc.) is filtered

- [ ] **Step 2: Test deep mode**

```
/tldr https://www.youtube.com/watch?v=dQw4w9WgXcQ --deep
```

**Verify:**
- User is told "Using deep analysis mode..."
- Both transcript and extended metadata are used
- Summary includes richer context (e.g., view count, upload date)

- [ ] **Step 3: Test with a longer educational video**

Pick a conference talk or educational video with spoken content (not music). Run:
```
/tldr https://www.youtube.com/watch?v=<VIDEO_ID>
```

**Verify:**
- Transcript is clean spoken text (no timestamps, no VTT artifacts)
- Summary uses the long/complex format (TL;DR, Key Points, Details, Takeaways)
- Sponsor/promo content is filtered from the summary

- [ ] **Step 4: Commit any fixes**

If any issues were found and fixed:
```bash
git add -A
git commit -m "fix: refine YouTube transcript handling based on testing"
```
