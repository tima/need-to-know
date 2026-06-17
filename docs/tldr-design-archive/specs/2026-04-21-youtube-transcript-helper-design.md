# YouTube Transcript Helper — Design Spec

A shell script that uses `yt-dlp` to reliably extract YouTube video transcripts and metadata, replacing the broken WebFetch-based approach in the `/tldr` skill.

## Problem

The `/tldr` skill's YouTube transcript mode uses WebFetch to fetch the YouTube page and parse caption track URLs. This doesn't work — YouTube's page structure doesn't expose caption data in a way WebFetch can extract.

## Solution

A helper shell script (`fetch-transcript.sh`) that uses `yt-dlp` (already installed on the system) to download subtitles and metadata. The skill prompt calls this script via the Bash tool.

## Script

**Path:** `skills/tldr/scripts/fetch-transcript.sh`

**Invocation:** `~/.claude/skills/tldr/scripts/fetch-transcript.sh "<YouTube URL>"`

**Argument:** A single YouTube URL (any format — `youtube.com/watch?v=`, `youtu.be/`, etc.).

### Behavior

1. Extract metadata (title, channel name, description) via `yt-dlp --dump-json`.
2. Download subtitles — prefer manually uploaded English captions, fall back to auto-generated English captions. Use `yt-dlp --write-sub --write-auto-sub --sub-langs "en.*" --sub-format vtt --skip-download` to get the subtitle file, then strip VTT timestamps, formatting tags, and duplicate lines to produce clean text.
3. Output to stdout in this format:

```
TITLE: <video title>
CHANNEL: <channel name>
DESCRIPTION:
<description text>

TRANSCRIPT:
<transcript text>
```

4. Exit code 0 on success, non-zero on failure with an error message to stderr.

### Error Cases

- Video not found or private → exit 1, stderr: "Error: Video not found or is private."
- No subtitles available in any language → exit 1, stderr: "Error: No subtitles available for this video."
- `yt-dlp` not installed → exit 1, stderr: "Error: yt-dlp is not installed. Install it with: brew install yt-dlp"

## Skill Prompt Changes

### YouTube Default (Transcript Mode)

Replace the current WebFetch-based approach (SKILL.md lines 54-60) with:

- Run the helper script via Bash: `~/.claude/skills/tldr/scripts/fetch-transcript.sh "<URL>"`
- The script outputs title, channel, description, and transcript as plain text.
- If the script fails (non-zero exit), tell the user: "No transcript available for this video. You can try `--deep` for richer analysis using video metadata."

### YouTube Deep Mode (`--deep`)

Replace the current deep mode section (SKILL.md lines 62-66) with:

- Tell the user: "Using deep analysis mode — pulling extended metadata alongside the transcript."
- Run the helper script to get the transcript (same as default mode).
- Additionally, run `yt-dlp --dump-json "<URL>"` via Bash to get the full JSON metadata (tags, categories, chapters, like count, view count, upload date).
- Use both the transcript and the extended metadata to produce a richer, more contextualized summary.
- If the transcript is unavailable but metadata is available, summarize from metadata alone and note that no transcript was available.

## Dependencies

- `yt-dlp` (already installed at `/opt/homebrew/bin/yt-dlp`, version 2026.03.17)

## File Structure

```
skills/
  tldr/
    SKILL.md                          # Updated YouTube sections
    scripts/
      fetch-transcript.sh             # New helper script
```
