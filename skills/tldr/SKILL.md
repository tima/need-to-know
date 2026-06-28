---
name: tldr
description: Use when the user wants to summarize a URL, PDF, YouTube video, or other source into a scannable need-to-know summary with hierarchical structure, bulleted lists, and organized tables — triggered by /tldr or when asked to summarize/digest external content
---

# TL;DR — Summarize Any Source

Analyze sources and produce scannable, need-to-know summaries.

## Usage

`/tldr <source1> [source2 ...] [--synthesize] [--deep] [--strict] [--bluf] [--save [path]]`

### Flags

- `--synthesize`: Single combined summary connecting themes across sources (default: independent summary per source)
- `--deep`: YouTube only — pull extended metadata alongside transcript (slower, token-intensive)
- `--strict`: Pure attribution mode — every point traces to source, no inferences/external knowledge
- `--bluf`: Output only BLUF + source context, ask if user wants full summary (analysis still runs, output abbreviated)
- `--save [path]`: Write to file (default: chat output). No path: auto-generate `tldr-<descriptive>.md`

## Process

1. **Parse args**: Extract sources and flags
   - YouTube: `youtube.com/watch` or `youtu.be/`
   - PDF: ends in `.pdf`
   - Local: no `http` prefix
   - Web: starts with `http`

2. **Fetch content** — REQUIRED: when given 2 or more sources, issue ALL fetches as simultaneous tool calls in a single response. Never fetch sources one at a time. A user with 3 sources should wait only as long as the slowest fetch, not the sum of all fetches.
   - Web: WebFetch (reject if paywalled - "Subscribe to continue", "Sign in to read")
   - Local/PDF: Read tool
   - Remote PDF garbled: `curl -sL URL > /tmp/tldr-$$.pdf` then Read
   - YouTube: `FETCH=$(find "$PWD/.agents/skills/tldr" ~/.agents/skills/tldr ~/.claude/skills/tldr -name "fetch-transcript.sh" 2>/dev/null | head -1); bash "$FETCH" URL`
   - YouTube --deep: Add `yt-dlp --dump-json URL` for metadata

**Caching**:
- Resolve once before any fetch: `CACHE=$(find "$PWD/.agents/skills/tldr" ~/.agents/skills/tldr ~/.claude/skills/tldr -name "cache-helper.sh" 2>/dev/null | head -1)`
- If `CACHE` is empty, skip caching for this run and proceed with all fetches normally
- For each source, before fetching:
  - `URL_HASH=$(echo -n "$URL" | md5 2>/dev/null || echo -n "$URL" | md5sum | cut -d' ' -f1)`
  - `bash "$CACHE" get $URL_HASH 2>/dev/null` — if exit 0, use output as content and skip the fetch
- After each successful fetch: `echo "$CONTENT" | bash "$CACHE" set $URL_HASH 2>/dev/null` (failure is non-fatal, continue)
- Cache TTL: 1 hour

3. **Published date** — one check per source type, then move on immediately:
   - YouTube: `upload_date` field from yt-dlp JSON output — if absent, `[date unavailable]`
   - Web: look for a date in the byline or article header only — if not visible in fetched content, `[date unavailable]`
   - PDF: check title page or first paragraph only — if not there, `[date unavailable]`
   - Local file: `date -r "<path>" "+%B %-d, %Y"` — if that fails, `[date unavailable]`
   - Never search further than the single location above for each type.

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

### Generate Summary

#### Output Structure

```
# TL;DR Brief: [TITLE]
**Source:** [Title](URL) | Published: [DATE]

## BLUF
2-4 sentences, bottom line first

## Key Points
- 5-10 specific bullets

[If content >500 words:]
## Details
### [Theme subsections as needed]

[If data present:]
## Data
| Comparison tables, metrics, timelines |

## Takeaways
- Actionable conclusions

[Footer for --save only:]
---
tldr | [Model] | [date]
```

**Adaptation rules:**
- Under 500 words: BLUF + Key Points + Takeaways only
- 500-2000 words: Add Details subsections
- Data/metrics in source: Add Data section with tables
- Over 2000 words: Full structure with multiple Detail themes

#### Multi-Source

- Default: Separate summaries per source
- `--synthesize`: Unified with combined BLUF, Common Themes, Divergences, Key Points by Source

### Verify Before Output

Before presenting any summary to the user, run a silent self-review pass against the fetched source content. This step is silent — no output to the user. Only corrected content reaches the output.

**Standard content** (under 2000 words / under 3 hours / under 50 pages) — full verification:
1. **Traceability**: Every claim in Key Points and Takeaways must trace directly to something stated in the source. Remove or rewrite any that can't.
2. **Accuracy**: Check all specific details — statistics, dates, names, quotes — against the source. Correct any that drifted.
3. **Scope**: Remove any conclusions that go beyond what the source explicitly says. Do not fill gaps with inference or external knowledge (unless in non-strict mode and clearly marked "Note:").

**Large content** (over 2000 words / 3+ hours / 50+ pages) — spot-check verification:
1. **Traceability**: Verify Key Points and Takeaways only — check each bullet traces to the source. Skip Details subsections.
2. **Accuracy**: Check only named specifics — statistics, dates, names, direct quotes. Correct any that drifted.
3. **Scope**: Same as standard — remove any out-of-scope conclusions.

### --bluf Mode

1. Fetch and analyze full content (same as non-bluf)
2. Output only header + BLUF
3. Ask: "Want the full TL;DR summary?"
4. If yes: Output remaining sections (Key Points, Details, Takeaways)
5. If no: Stop

### Save to File (if `--save`)

**Single source or `--synthesize`**: write one file.
- Path provided: use it
- No path: auto-generate `tldr-<descriptive>.md` (lowercase, hyphens, <60 chars)

**Multiple sources without `--synthesize`**: write one file per source — never combine into a single file.
- Path provided: treat it as a directory. Write each summary as `<path>/tldr-<descriptive>.md`
- No path: auto-generate a separate filename per source based on that source's content

Collision check (all cases): Glob for existing file, append `-2`, `-3` until unused

Footer (--save only): Use `date +"%B %-d, %Y"` for current date → `tldr | {current-model} | {date}`

Confirm each file: "Summary saved to `<path>`"
