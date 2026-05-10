---
name: tldr
description: Use when the user wants to summarize a URL, PDF, YouTube video, or other source into a scannable need-to-know summary with hierarchical structure, bulleted lists, and organized tables. Output includes metadata footer with provider, model, and timestamp — triggered by /tldr or when asked to summarize/digest external content
---

# TL;DR — Summarize Any Source

Analyze one or more sources and produce a scannable, need-to-know summary.

## Usage

`/tldr <source1> [source2 ...] [--synthesize] [--deep] [--strict] [--bluf] [--save [path]]`

### Arguments

- **Sources** (required): One or more URLs, local file paths (including PDFs), or YouTube links.
- `--synthesize`: Produce a single combined summary that connects themes across all sources. Without this flag, each source gets its own independent summary.
- `--deep`: For YouTube videos only. Pull extended metadata (tags, chapters, categories, engagement data) alongside the transcript for richer context. Warn the user this is slower and more token-intensive.
- `--strict`: Pure attribution mode. Every point must trace directly to the source. No inferences, no added context, no external knowledge.
- `--bluf`: Quick-read mode. Output only the BLUF section (with the source title and published date for context), then ask the user if they want the full TL;DR summary. All content fetching and analysis still happens normally — only the output is abbreviated.
- `--save [path]`: Write the summary to a file.
  - If a path is provided, write to that exact path.
  - If no path is provided, generate a filename: `tldr-<concise-descriptive-lc-name>.md` based on the source content (e.g., `tldr-react-server-components-overview.md`).
  - **Never overwrite an existing file.** Before writing, check if the file exists using Glob. If it does, append a numeric suffix (e.g., `tldr-react-server-components-overview-2.md`). Keep incrementing until you find a name that doesn't exist.

## Process

Follow these steps in order:

### Step 1: Parse Arguments

Extract sources and flags from the arguments string. Detect each source type:

- **YouTube**: URL contains `youtube.com/watch` or `youtu.be/`.
- **PDF**: Path ends in `.pdf` (local or remote URL).
- **Local file**: A path that does not start with `http` — treat as a local filesystem path.
- **Web page**: Everything else that looks like a URL starting with `http`.

If no sources are provided, tell the user: "Please provide at least one source (URL, file path, or YouTube link)."

If `--deep` is provided but no YouTube sources are detected, tell the user: "Note: --deep applies to YouTube sources only and will be ignored."

If `--bluf` is provided, note it — the full analysis still runs, but output is abbreviated (see Step 4.5).

### Step 1.5: Ambiguity Check

Before fetching content, assess whether the request is clear enough to proceed:

- If the user provided a URL or file path, proceed — the content itself provides context.
- If the user described a topic but the terminology is ambiguous or the scope is too broad, stop and ask for clarification before proceeding.

### Step 2: Fetch Content

**Multiple sources:** When given 2+ sources, issue all fetches as concurrent tool calls in a single response — multiple WebFetch calls and Bash commands can run in parallel, so don't wait for one to finish before starting the next.

**Very large sources:** If a source is unusually long (e.g., a 3+ hour video transcript or a multi-chapter document), note this upfront. Focus on the most substantive sections and tell the user which portions were covered or skipped.

For each source, fetch the content:

**Web pages:**
- Use the WebFetch tool to retrieve the page.
- Focus on the main content. Mentally strip navigation, sidebars, footers, ads, cookie banners, and boilerplate before summarizing.
- **Paywalled or gated pages:** If the page returns a login wall, subscription prompt, or access-denied message (look for phrases like "Subscribe to continue", "Sign in to read", "Create a free account"), stop and tell the user: "This page appears to be paywalled or requires a login. Try providing a local copy or an alternative source."

**Local files (non-PDF):**
- Use the Read tool to read the file directly (supports `.md`, `.txt`, and other text formats).

**Local PDFs:**
- Use the Read tool, which natively renders PDF content.

**Remote PDFs (URL ending in .pdf):**
- Try WebFetch first to retrieve the PDF content.
- If WebFetch does not return usable content (e.g., binary garbled output or an error), fall back to downloading with Bash: `TMPFILE=$(mktemp /tmp/tldr-XXXXXX.pdf) && curl -sL -o "$TMPFILE" "<URL>" && echo "$TMPFILE"` — then use the Read tool on the echoed path.

**YouTube — default (transcript mode):**
- Run the helper script via Bash: `~/.claude/skills/tldr/scripts/fetch-transcript.sh "<URL>"`
- The script uses `yt-dlp` to extract the video title, channel, description, and transcript as plain text.
- Use the transcript as the primary content for summarization. The title, channel, and description provide context.
- If the script fails (non-zero exit), tell the user: "No transcript available for this video. You can try `--deep` for richer analysis using video metadata."

**YouTube — deep mode (`--deep` flag):**
- Tell the user: "Using deep analysis mode — pulling extended metadata alongside the transcript."
- Run the helper script via Bash to get the transcript: `~/.claude/skills/tldr/scripts/fetch-transcript.sh "<URL>"`
- Additionally, run `yt-dlp --dump-json --no-warnings "<URL>"` via Bash to get the full JSON metadata (tags, categories, chapters, like count, view count, upload date).
- Use both the transcript and the extended metadata to produce a richer, more contextualized summary.
- If the transcript is unavailable but metadata is available, summarize from metadata alone and note that no transcript was available.

### Step 2.5: Determine Published Date

Extract the publication date for each source to populate the `Published:` field in the output header:

- **YouTube:** Use the `upload_date` field from the `yt-dlp --dump-json` output (format: YYYYMMDD → convert to e.g. `May 1, 2025`). For default mode, get this from the DESCRIPTION output of the helper script or run a quick `yt-dlp --print upload_date --no-warnings "<URL>"` via Bash.
- **Web pages:** Look for a publication date in the page content (byline, article metadata, `<time>` elements, or "Published on" text). If not found, use `[date unavailable]`.
- **PDFs:** Look for a date on the title page, header, or document metadata. If not found, use `[date unavailable]`.
- **Local files:** Use the file's modification date via Bash: `date -r "<path>" "+%B %-d, %Y"`. If unavailable, use `[date unavailable]`.

### Step 3: Filter Non-Substantive Content

Before summarizing, mentally filter out:
- Sponsor segments and ad reads
- Self-promotional content (subscribe reminders, like/bell reminders, channel plugs, merch mentions)
- Navigation elements, headers/footers, cookie notices
- Boilerplate disclaimers
- Repetitive intros/outros

Summarize only the substantive content.

### Step 3.5: Get Current Timestamp

Before generating any output, get the current UTC time for the metadata footer using this priority order:

1. **Bash (preferred):** Run `date -u +"%b-%d-%Y %H:%M GMT"` — fast and reliable.
2. **Web search (fallback):** If Bash fails, search for "current UTC time" and extract the result.
3. **Last resort:** If both fail, use `[timestamp unavailable]`.

Store this value and use it in every footer you produce.

### Step 4: Generate Summary

#### Tone

Write in an approachable, conversational tone — like a knowledgeable colleague briefing you over coffee. Be direct and human, never cold or robotic. Use clear, jargon-free language at an 8th-grade reading level. Strictly avoid corporate speak and technical buzzwords. If you must use a technical term, explain it in plain language.

#### Content Fidelity

**Default mode:** Stay faithful to the source. You may add brief clarifying context from your own knowledge when it genuinely helps the reader understand (e.g., defining a term, providing a date). Always mark added context clearly: "For context: ..." or parenthetical notes. Never present your own knowledge as if it came from the source.

**`--strict` mode:** Pure attribution. Every single point must be directly traceable to the source content. No inferences, no external knowledge, no added context of any kind. If something is unclear in the source, say so — don't fill the gap.

**Gaps and ambiguity (both modes):** When the source is incomplete or ambiguous, flag it rather than guessing. Use phrases like "The source doesn't clarify..." or "This point is unclear from the source."

#### Format Selection & Structure

All summaries use a consistent hierarchical structure with clear headings, bulleted lists, and tables for organized data presentation. Scale the depth to the source:

**Horizontal rule usage:** Use `---` exactly once — immediately before the metadata footer at the end of the document. Never place horizontal rules between sections, subsections, or content blocks.

**Universal Output Template:**

```
## TL;DR Brief: [TITLE]

Published: [PUBLISHED DATE]
Subject: [CONCISE DESCRIPTIVE SENTENCE OF THE SUBJECT MATTER]

------------------------------

## BLUF
2–4 sentences. Bottom line first: the single most important thing to know, the action to take, or the core insight that changes how you think about the topic. Written for someone who will read nothing else. No hedging, no throat-clearing.

## Key Points
- Bulleted list of core ideas
- Each point specific and standalone
- 5–10 points typically

## Details
### [Theme 1]
Supporting context for theme 1, organized with bullets where applicable.

### [Theme 2]
Supporting context for theme 2.

(Add subsections as needed per themes in the source)

## Data Organization (when applicable)
Use markdown tables to present:
- Comparisons (feature X vs feature Y)
- Timelines or sequences
- Research findings
- Metrics or statistics

| Item | Description | Key Detail |
|------|-------------|-----------|
| Row 1 | ... | ... |

## Takeaways
- Actionable conclusions
- "So what?" — what should the reader do with this?
- Specific next steps when applicable

---

Claude Code | Claude [Model Name] | [Timestamp UTC]
```

**For short content** (under 500 words): compress TL;DR, Key Points, and Takeaways; skip Details and tables if not needed.

**For long content** (articles, papers, long talks): fully flesh out all sections with rich subsection hierarchy and tables.

#### Multi-Source Handling

**Independent mode (default):** Output a separate summary for each source. Use a heading with the source name/title to separate them.

**Synthesized mode (`--synthesize`):** Read all sources first, then produce a single combined summary using this header:

```
## TL;DR Brief: [THEMATIC TITLE derived from combined content]
Sources: [Title 1](URL1) · [Title 2](URL2) · ...
Subject: [UNIFIED THESIS ACROSS ALL SOURCES]
------------------------------
```

- **BLUF** — 2–4 sentences. The bottom line across all sources: what to know, what to do, or what changed.
- **TL;DR** — unified thesis across all sources.
- **Common Themes** — what the sources agree on or reinforce.
- **Divergences** — where sources differ, contradict, or present different perspectives.
- **Key Points by Source** — brief per-source highlights so the reader knows what came from where.
- **Takeaways** — synthesized conclusions drawing on all sources.

### Step 4.5: BLUF-Only Output (if `--bluf`)

If `--bluf` was provided, **do not output the full summary**. Instead:

1. Output a slim header plus the BLUF:

```
## [TITLE]

Published: [PUBLISHED DATE]

**BLUF:** [2–4 sentence BLUF, same quality and tone as the full-summary version]
```

2. Immediately follow with this prompt to the user (plain text, no heading):

"Want the full TL;DR summary?"

3. **Stop.** Do not output Key Points, Details, Takeaways, or the metadata footer. Do not save to file even if `--save` was also provided — wait until the user confirms they want the full summary, then produce it (with `--save` honored at that point).

If `--bluf` was **not** provided, skip this step entirely and continue to Step 5.

### Step 5: Save to File (if `--save`)

If the `--save` flag is present:

1. **Determine the file path:**
   - If a path was given after `--save`, use it.
   - If no path was given, generate a descriptive filename: `tldr-<concise-descriptive-lc-name>.md`. The name should reflect the content (e.g., `tldr-react-19-upgrade-guide.md`, `tldr-python-type-hints-talk.md`). Use lowercase, hyphens for spaces, keep it under 60 characters.

2. **Check for existing files:**
   - Use Glob to check if the target filename already exists.
   - If it does, append `-2`, `-3`, etc. until you find an unused name.

3. **Write the file:**
   - Before writing, announce: "Saving to `<path>`..."
   - Use the Write tool.
   - Include a source line at the top of the file:
     - Single source: `Source: [Source Title](URL/path)`
     - With `--synthesize`: a bulleted list labeled `Sources:` with one entry per source, each as `[Source Title](URL/path)`.
   - Write the full summary using the hierarchical format described above.
   - End with a horizontal separator (`---`) followed by the metadata footer:
     ```
     Claude Code | Claude [current model name] | [Current UTC timestamp, e.g., Nov-15-2025 14:32 GMT]
     ```

4. **Confirm to the user:** "Summary saved to `<path>`."
