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

2. **Fetch content** — REQUIRED: when given 2 or more sources, issue ALL fetches as simultaneous tool calls in a single response. Never fetch sources one at a time. A user with 3 sources should wait only as long as the slowest fetch, not the sum of all fetches. If a fetch fails, tell the user immediately ("Could not fetch [URL] — skipping.") and continue with the remaining sources. Only stop entirely if all sources fail.
   - Web: WebFetch (reject if paywalled - "Subscribe to continue", "Sign in to read")
   - Local/PDF: Read tool
   - Remote PDF garbled: `curl -sL URL > /tmp/tldr-$$.pdf` then Read
   - YouTube: Extract the video ID from the URL yourself — no bash call needed (`v=ID` in watch URLs, path in `youtu.be/ID`). Issue these two commands per URL (can run simultaneously):
     1. `yt-dlp --no-download --print "%(title)s\t%(channel)s\t%(upload_date)s" "URL" 2>/dev/null`
     2. `python3 -m youtube_transcript_api VIDEO_ID --format text --languages en 2>/dev/null`
     If command 2 fails (no English captions), retry without `--languages en`. If still fails, skip and tell the user.
   - YouTube --deep: Same; expand command 1: `yt-dlp --no-download --print "%(title)s\t%(channel)s\t%(upload_date)s\t%(view_count)s\t%(duration_string)s" "URL" 2>/dev/null`
   - Zero permission prompts for YouTube (any project): add to `~/.claude/settings.json` → `permissions.allow`: `"Bash(yt-dlp --no-download *)"` and `"Bash(python3 -m youtube_transcript_api *)"`

3. **Published date** — one check per source type, then move on immediately:
   - YouTube: `upload_date` from the `yt-dlp --no-download --print` output above (YYYYMMDD — format as "Month D, YYYY") — if blank, `[date unavailable]`
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

**Before writing any bullet containing a statistic, percentage, or named entity:** Mentally hold the exact source sentence in mind. If you cannot reconstruct it, mark the claim UNVERIFIED and omit it. Do not approximate or infer. Never construct a numeric range from a single data point — if the source gives one bound, report that bound only; ranges require two distinct source values. When the source uses a vague quantifier ("high 90s %", "roughly", "nearly", "slightly over"), reproduce that phrasing exactly — do not convert it to a specific figure. When a source refers to someone by role or description without naming them ("the creator", "a researcher", "one developer"), reproduce that description exactly — never substitute a name inferred from context or background knowledge. When a source provides an explicit list of named entities (people, tools, examples), reproduce all of them — do not abstract, generalize, or drop items from the list. For YouTube transcripts: if a named entity (model, tool, framework, organization) appears in a form that doesn't match known terminology, use surrounding context to resolve it. If resolvable with confidence, write the correct name with a parenthetical note: `Mistral 3B [transcript: "Mini Stroll 3B"]`. If not resolvable with confidence, mark `[transcript unclear]` and omit the claim.

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
- Conclusions and recommendations the source explicitly states

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
1. **Traceability**: Every claim in Key Points and Takeaways must trace directly to something stated in the source. Remove or rewrite any that can't. "Source" means the URLs and files explicitly passed to this skill invocation — other files, KB documents, or cross-references encountered during synthesis are not sources; claims from them must be removed or explicitly marked `[external context, not from source material]`.
2. **Accuracy**: Check all specific details — statistics, dates, names, quotes — against the source. Correct any that drifted.
3. **Scope** — remove conclusions beyond what source explicitly states. Zero-tolerance cases:
   - Any causal or temporal sequence not explicit in source ("then", "shortly after", "which led to", "following")
   - Any characterization of intent, capability, or behavior not directly stated (e.g. "designed to", "fewer guardrails", "intentionally")
   - Any statistic presented as universal that source scopes to a specific organization, dataset, or context — preserve the original scope qualifier

4. **High-risk patterns** — check each explicitly before output:
   - Direction inversions: re-read the source sentence for any claim using can/cannot, over/under, majority/minority, more/less — these flip easily
   - Named entity type: verify model names are called models, benchmarks called benchmarks, organizations called organizations — do not conflate
   - Fabricated sequence: remove any "then", "shortly after", "followed by", or causal language not verbatim present in source
   - Scope preservation: if source attributes a stat to one organization's internal data, summary must carry that caveat — do not generalize to universal advice
   - Speaker attribution: in multi-speaker sources (interviews, videos where a host discusses others' work, panels), verify which speaker made each claim before attributing it. A host paraphrasing someone else's words is not that person speaking.
   - Entity relationships: when two named entities appear independently in the source, do not imply a relationship between them unless the source explicitly states one.

5. **Internal consistency**: Scan across all sections for claims that contradict each other. A stat stated correctly in Key Points must not be inverted in Details. Resolve any contradiction before output — the source is the tiebreaker.

6. **Takeaways traceability gate**: For each Takeaway bullet, identify the exact source sentence or paragraph it traces to. Any bullet where you are drawing on background domain knowledge rather than the source must be removed — regardless of how plausible or relevant it seems.

**Large content** (over 2000 words / 3+ hours / 50+ pages) — spot-check verification:
1. **Traceability**: Verify Key Points and Takeaways only — check each bullet traces to the source. Skip Details subsections.
2. **Accuracy**: Check only named specifics — statistics, dates, names, direct quotes. Correct any that drifted.
3. **Scope**: Same as standard — remove out-of-scope conclusions; apply zero-tolerance cases and high-risk pattern checks to Key Points and Takeaways only.

### --bluf Mode

1. Fetch and analyze full content (same as non-bluf)
2. Generate the complete summary internally
3. Run the full verification pass against the complete summary — do not skip because output will be abbreviated
4. Output only header + BLUF from the verified summary
5. Ask: "Want the full TL;DR summary?"
6. If yes: Output remaining sections (Key Points, Details, Takeaways) — already verified, no second pass needed
7. If no: Stop

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
