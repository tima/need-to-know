# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Two Claude Code skills for fast comprehension of external content:

- **tldr** — scannable summaries for fast need-to-know comprehension
- **fathom** — comprehensive learning guides for deep understanding

Both work with URLs, PDFs, YouTube videos, and local files.

## Architecture

### Skill Structure

Self-contained skills with minimal shared scripts:

```
skills/
  shared/
    scripts/
      fetch-transcript.sh       # YouTube transcript extraction via yt-dlp
      cache-helper.sh           # Content caching (1hr TTL)
  tldr/
    SKILL.md                    # 98 lines, all logic inlined
  fathom/
    SKILL.md                    # 106 lines, all logic inlined
```

Skills are discovered by Claude Code via symlinks in `~/.claude/skills/`:

```bash
ln -s ~/projects/need-to-know/skills/tldr ~/.claude/skills/tldr
ln -s ~/projects/need-to-know/skills/fathom ~/.claude/skills/fathom
```

### Key Components

**SKILL.md files**: Self-contained skill specifications:
- Frontmatter with name, description, and triggers
- Usage instructions with flags
- Inlined processing steps (argument parsing, content fetching, filtering)
- Inlined output guidelines (tone, fidelity, formatting)
- Output structure templates
- File saving logic with collision avoidance

**Shared scripts**:
- `fetch-transcript.sh`: YouTube transcript extraction via `yt-dlp` (metadata, subtitles, VTT stripping)
- `cache-helper.sh`: Content caching with 1hr TTL to avoid re-downloading same URLs

### Content Fetching Strategy

Both skills handle multiple source types:

- **Web pages**: WebFetch tool, mentally strip navigation/ads/boilerplate
- **Local files**: Read tool (supports text files and PDFs natively)
- **Remote PDFs**: WebFetch first, fallback to curl + Read if binary garbled
- **YouTube default**: Helper script for transcript extraction
- **YouTube --deep**: Helper script + `yt-dlp --dump-json` for extended metadata

Paywalled content detection: Check for login walls, subscription prompts, and reject with user message.

### Multi-Source Handling

**tldr**:
- Default: Independent summaries per source
- `--synthesize`: Single unified summary across all sources

**fathom**:
- Default: Synthesized single learning guide across all sources
- `--batch`: Separate guide per source

### Output Architecture

**Common patterns**:
- Hierarchical structure with clear headings
- Bulleted lists for scannability
- Markdown tables for organized data
- Single horizontal rule (`---`) before metadata footer only
- Metadata footer: `Claude Code | Claude [Model] | [UTC timestamp]`

**tldr structure**:
- BLUF (bottom line up front)
- Key Points (5-10 bullets)
- Details (themed subsections)
- Data tables (when applicable)
- Takeaways (actionable conclusions)

**fathom structure**:
- Overview (what/why/outcomes)
- Core Concepts (per-concept deep explanations)
- Key Facts & Insights (specific memorizable points)
- How It Works (multi-step processes only)
- Practical Applications
- Key Terms & Definitions (markdown table)
- Connections & Relationships
- Common Misconceptions (when source addresses them)
- Open Questions (gaps flagged honestly)

### Content Fidelity Rules

**Default mode**: Stay faithful to source, allow brief clarifying context from own knowledge when helpful, always mark added context clearly.

**--strict mode**: Pure attribution — every point must trace directly to source, no inferences, no external knowledge, no added context.

**Zero-hallucination policy** (fathom): Never bridge gaps with inferences or "likely" scenarios. Flag missing information or skip sections rather than fabricate.

**Contradiction flagging**: Present conflicting data from sources as "Conflicting Evidence" — do not reconcile, let reader decide.

## Development Commands

### Testing Skills Locally

Test skill invocation:
```bash
# From Claude Code CLI
/tldr <source> [flags]
/fathom <source> [flags]
```

Test YouTube transcript extraction:
```bash
skills/shared/scripts/fetch-transcript.sh "https://youtu.be/VIDEO_ID"
```

Test content caching:
```bash
# Store content
echo "test content" | skills/shared/scripts/cache-helper.sh set abc123

# Retrieve within 1hr
skills/shared/scripts/cache-helper.sh get abc123
```

Verify yt-dlp installation:
```bash
yt-dlp --version
```

### File Operations

Check for file conflicts before writing (both skills use this pattern):
```bash
# Skills use Glob to check existence, then append -2, -3, etc.
# Never overwrite existing files
```

Get UTC timestamp for metadata footer:
```bash
date -u +"%b-%d-%Y %H:%M GMT"
```

Get publication date from local file:
```bash
date -r "<path>" "+%B %-d, %Y"
```

### Common Workflows

**Adding a flag to a skill**:
1. Update SKILL.md frontmatter description if flag affects triggers
2. Add flag to Flags section
3. Add processing logic in Process section
4. Update README.md
5. Test with real sources

**Modifying output format**:
1. Update Output Structure template in SKILL.md
2. Test multi-source scenarios if applicable

**Changing tone/fidelity rules**:
1. Update inline guidelines in Process section of both SKILL.md files
2. Test with both skills

**Modifying content fetching logic**:
1. Update step 2 in Process section of both SKILL.md files
2. Test with all source types (web, PDF, YouTube, local)

**Changing transcript extraction**:
1. Modify `shared/scripts/fetch-transcript.sh`
2. Test with various YouTube URL formats
3. Verify error handling (private videos, no subtitles)
4. Test with both skills

## Important Patterns

### Concurrent Fetching

When processing 2+ sources, issue all WebFetch and Bash calls concurrently in a single response — don't wait for one to finish before starting the next.

### File Naming Strategy

Auto-generated filenames follow pattern: `{skill}-{concise-descriptive-lc-name}.md`
- Lowercase, hyphens for spaces
- Under 60 characters
- Reflects actual content, not just source title

### Tone Requirements

Both skills use approachable, conversational tone:
- Like a knowledgeable colleague/friend explaining over coffee
- Direct and human, never cold or robotic
- 8th-grade reading level
- Avoid corporate speak and technical buzzwords
- Define technical terms in plain language immediately

### Error Handling

Skills detect and report:
- Missing sources in arguments
- Paywalled/gated content
- Failed YouTube transcript extraction (with --deep suggestion)
- Missing yt-dlp installation
- Flags used with wrong source types (e.g., --deep on non-YouTube)

## Dependencies

Required:
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) for YouTube transcript extraction

Installation:
```bash
brew install yt-dlp
```

## Documentation

- `README.md` — User-facing documentation, usage examples, installation
- `skills/*/SKILL.md` — Complete skill specifications read by Claude Code
- `docs/tldr-design-archive/` — Historical design specs and plans for tldr
- `docs/superpowers/` — Design docs (appears to be duplicate of archive)
