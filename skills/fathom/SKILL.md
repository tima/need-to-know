---
name: fathom
description: Create comprehensive learning guides from YouTube videos, web articles, PDFs, and other sources. Use when the user wants to deeply understand a topic, create study material, build a learning guide, or prepare content for NotebookLLM. Trigger when the user mentions learning guides, study material, deep understanding, fathom, or wants to turn videos/articles into educational content for studying, flashcards, or quizzes — even if they don't explicitly say "learning guide."
---

# Fathom — Learning Guides from Any Source

Analyze sources and produce comprehensive learning guides for deep understanding. Works as NotebookLLM source material.

Unlike summary (what was said), learning guide helps you *understand* — defined terms, explained concepts, connections.

## Usage

`/fathom <source1> [source2 ...] [--batch] [--deep] [--strict] [--save [path]]`

### Flags

- `--batch`: Separate guide per source (default: synthesized single guide across sources)
- `--deep`: YouTube only — pull extended metadata alongside transcript (slower, token-intensive)
- `--strict`: Pure attribution mode — every point traces to source, no inferences/external knowledge
- `--save [path]`: Write to file (default: chat output). No path: auto-generate `fathom-<descriptive>.md`

## Process

1. **Parse args**: Extract sources and flags
   - YouTube: `youtube.com/watch` or `youtu.be/`
   - PDF: ends in `.pdf`
   - Local: no `http` prefix
   - Web: starts with `http`

2. **Fetch content** (multiple sources = parallel tool calls):
   - Web: WebFetch (reject if paywalled - "Subscribe to continue", "Sign in to read")
   - Local/PDF: Read tool
   - Remote PDF garbled: `curl -sL URL > /tmp/fathom-$$.pdf` then Read
   - YouTube: `FETCH=$(find "$PWD/.agents/skills/fathom" ~/.agents/skills/fathom ~/.claude/skills/fathom -name "fetch-transcript.sh" 2>/dev/null | head -1); bash "$FETCH" URL`
   - YouTube --deep: Add `yt-dlp --dump-json URL` for metadata

**Caching** (optional, reduces redundant fetches):
- Before fetch: `URL_HASH=$(echo -n "$URL" | md5 || echo -n "$URL" | md5sum | cut -d' ' -f1)`
- Check cache: `CACHE=$(find "$PWD/.agents/skills/fathom" ~/.agents/skills/fathom ~/.claude/skills/fathom -name "cache-helper.sh" 2>/dev/null | head -1); bash "$CACHE" get $URL_HASH`
- If exit 0 (cache hit): use cached content, skip fetch
- After fetch: `CACHE=$(find "$PWD/.agents/skills/fathom" ~/.agents/skills/fathom ~/.claude/skills/fathom -name "cache-helper.sh" 2>/dev/null | head -1); echo "$CONTENT" | bash "$CACHE" set $URL_HASH`
- Cache TTL: 1 hour

3. **Published date** (best-effort, 10-second limit):
   - Check obvious locations: YouTube upload_date, web article headers/metadata, PDF title page, file mtime
   - Use `[date unavailable]` if not found quickly - don't spend time searching

4. **Filter non-substantive content**:
   - YouTube: Sponsor reads ("this video is sponsored by", "use code"), self-promotion (subscribe/like reminders, merch mentions, channel plugs)
   - Web: Navigation menus, sidebars, footers, cookie notices, comment sections, "related articles" widgets
   - All sources: Repetitive intros/outros, boilerplate disclaimers
   - Focus on substantive content only - what the source is actually teaching/explaining/arguing

5. **Large content** (>2000 words / 3+ hours / 50+ pages):
   - Note limits upfront: "This is a [X]-hour video/[Y]-page document. Covering [main sections/first N hours/chapters 1-5]."
   - For YouTube >3 hrs: Focus on first 2 hours or most substantive chapters (if available)
   - For articles >5000 words: Summarize by major section, note if later sections skipped
   - For PDFs >50 pages: Focus on abstract, introduction, key sections, conclusion
   - Always tell user what was covered vs skipped

**Tone**: Conversational, 8th-grade level, no jargon
**Fidelity**: 
- Default: Faithful to source. Add context only when essential for clarity - mark with "Note:" in italics
- --strict: Pure attribution only. Every point traces to source. Flag gaps, never fill
- Always flag conflicts/gaps honestly. Never fabricate missing information

### Generate Learning Guide

Go deep. Goal: reader understands material, not just knows it exists. Specific details, concrete examples, context. Reader should answer questions about topic.

#### Output Structure

Every section: enough detail for quiz questions/flashcards. **Skip sections** the source doesn't address.

```
# [Descriptive Title]
**Source(s):** [Title](URL) | Published: [DATE]

## Overview
2-3 sentences: what covered, why matters, outcomes

[Required if source explains concepts:]
## Core Concepts
### [Concept] - what it is, why matters, how works, examples

## Key Facts & Insights
- Specific memorizable points

[Only for multi-step processes/systems:]
## How It Works
Step-by-step or bullets

[If source provides use cases:]
## Practical Applications

[If technical terms defined:]
## Key Terms
| Term | Definition |

[Always include:]
## Connections & Relationships
How concepts relate

[Only if source addresses:]
## Common Misconceptions

[If gaps exist:]
## Open Questions

[Footer for --save only:]
---
fathom | [Model] | [date]
```

**Adaptation rules:**
- Core Concepts: Required if source explains 2+ concepts; skip for purely factual content
- How It Works: Only for processes/systems spanning full topic, not per-concept mechanics
- Practical Applications: Skip if source is theoretical only
- Common Misconceptions: Skip unless source explicitly addresses them
- Skip = omit section entirely; don't write "Information not found"

#### Multi-Source

- Default: Synthesized guide - weave insights, note sources, use **Conflicting Evidence** for contradictions
- `--batch`: Separate guide per source with full structure

### Verify Before Output

Before presenting the learning guide to the user, run a silent self-review pass against the fetched source content:

1. **Traceability**: Every claim in Key Facts & Insights and Core Concepts must trace directly to something stated in the source. Remove or rewrite any that can't.
2. **Accuracy**: Check all specific details — statistics, dates, names, quotes — against the source. Correct any that drifted.
3. **Scope**: Flag and remove any conclusions that go beyond what the source explicitly says. Do not fill gaps with inference or external knowledge (unless in non-strict mode and clearly marked "For context:").

This step is silent — no output to the user. Only corrected content reaches the output.

### Save to File (if `--save`)

`--save` without path: auto-generate `fathom-<descriptive>.md` (lowercase, hyphens, <60 chars)

Collision check: Glob for existing file, append `-2`, `-3` until unused

Footer (--save only): Use `date +"%B %-d, %Y"` for current date → `fathom | {current-model} | {date}`

Confirm: "Learning guide saved to `<path>`"
