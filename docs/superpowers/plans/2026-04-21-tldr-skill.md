# TL;DR Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code skill (`/tldr`) that summarizes web pages, PDFs, and YouTube videos into scannable need-to-know summaries.

**Architecture:** Single skill file — all logic lives in the skill prompt. No external dependencies, scripts, or MCP servers. The skill instructs Claude to use WebFetch, Read, Write, Glob, and Bash tools to fetch, process, and optionally save summaries.

**Tech Stack:** Markdown skill file (Claude Code superpowers format)

---

## File Structure

```
skills/
  tldr.md          # The skill prompt — all logic here
```

One file. The skill prompt handles argument parsing, source detection, fetching, content filtering, format selection, and output.

---

### Task 1: Create the skill file with frontmatter and argument parsing

**Files:**
- Create: `skills/tldr.md`

- [ ] **Step 1: Create the skill file with frontmatter**

Create `skills/tldr.md` with the following content:

```markdown
---
name: tldr
description: Use when the user wants to summarize a URL, PDF, YouTube video, or other source into a scannable need-to-know summary — triggered by /tldr or when asked to summarize/digest external content
---

# TL;DR — Summarize Any Source

Analyze one or more sources and produce a scannable, need-to-know summary.

## Usage

`/tldr <source1> [source2 ...] [--synthesize] [--deep] [--strict] [--save [path]]`

### Arguments

- **Sources** (required): One or more URLs, local file paths (including PDFs), or YouTube links.
- `--synthesize`: Produce a single combined summary that connects themes across all sources. Without this flag, each source gets its own independent summary.
- `--deep`: For YouTube videos only. Use multimodal video analysis instead of transcript extraction. Warn the user this is slower and more token-intensive.
- `--strict`: Pure attribution mode. Every point must trace directly to the source. No inferences, no added context, no external knowledge.
- `--save [path]`: Write the summary to a file.
  - If a path is provided, write to that exact path.
  - If no path is provided, generate a filename: `tldr-<concise-descriptive-lc-name>.md` based on the source content (e.g., `tldr-react-server-components-overview.md`).
  - **Never overwrite an existing file.** Before writing, check if the file exists using Glob. If it does, append a numeric suffix (e.g., `tldr-react-server-components-overview-2.md`). Keep incrementing until you find a name that doesn't exist.

## Process

Follow these steps in order:

### Step 1: Parse Arguments

Extract sources and flags from the arguments string. Detect each source type:

- **YouTube**: URL contains `youtube.com/watch` or `youtu.be/`.
- **PDF**: Path ends in `.pdf` or is a local file path to a PDF.
- **Web page**: Everything else.

If no sources are provided, tell the user: "Please provide at least one source (URL, file path, or YouTube link)."

### Step 2: Fetch Content

For each source, fetch the content:

**Web pages:**
- Use the WebFetch tool to retrieve the page.
- Focus on the main content. Mentally strip navigation, sidebars, footers, ads, cookie banners, and boilerplate before summarizing.

**Local PDFs:**
- Use the Read tool, which natively renders PDF content.

**Remote PDFs (URL ending in .pdf):**
- Use WebFetch to retrieve the PDF content.

**YouTube — default (transcript mode):**
- Extract the video ID from the URL.
  - From `youtube.com/watch?v=VIDEO_ID` — parse the `v` parameter.
  - From `youtu.be/VIDEO_ID` — parse the path segment.
- Fetch the transcript. Try these approaches in order:
  1. Fetch the video page via WebFetch: `https://www.youtube.com/watch?v=VIDEO_ID`. Look for caption track URLs in the page source. Fetch the caption track URL to get the transcript XML. Parse the text content from the XML `<text>` elements.
  2. If no captions are found, tell the user: "No transcript available for this video. You can try `--deep` for multimodal video analysis instead."

**YouTube — deep mode (`--deep` flag):**
- Tell the user: "Using multimodal video analysis — this is slower and more token-intensive than transcript mode."
- Analyze the video content using multimodal capabilities instead of transcript extraction.

### Step 3: Filter Non-Substantive Content

Before summarizing, mentally filter out:
- Sponsor segments and ad reads
- Self-promotional content (subscribe reminders, like/bell reminders, channel plugs, merch mentions)
- Navigation elements, headers/footers, cookie notices
- Boilerplate disclaimers
- Repetitive intros/outros

Summarize only the substantive content.

### Step 4: Generate Summary

#### Tone

Write in an approachable, conversational tone — like a knowledgeable colleague briefing you over coffee. Be direct and human, never cold or robotic. Use clear, jargon-free language at an 8th-grade reading level. Strictly avoid corporate speak and technical buzzwords. If you must use a technical term, explain it in plain language.

#### Content Fidelity

**Default mode:** Stay faithful to the source. You may add brief clarifying context from your own knowledge when it genuinely helps the reader understand (e.g., defining a term, providing a date). Always mark added context clearly: "For context: ..." or parenthetical notes. Never present your own knowledge as if it came from the source.

**`--strict` mode:** Pure attribution. Every single point must be directly traceable to the source content. No inferences, no external knowledge, no added context of any kind. If something is unclear in the source, say so — don't fill the gap.

**Gaps and ambiguity (both modes):** When the source is incomplete or ambiguous, flag it rather than guessing. Use phrases like "The source doesn't clarify..." or "This point is unclear from the source."

#### Format Selection

Assess the content complexity and length, then choose the appropriate format:

**Short/simple content** (brief blog posts, short videos, simple pages):

Use a flat bullet list of 3-8 key takeaways. No section headers needed.

**Long/complex content** (long articles, dense papers, lengthy talks):

Use structured sections:

- **TL;DR** — 1-2 sentence essence of the whole thing.
- **Key Points** — the core ideas as a bulleted list.
- **Details** — supporting context, organized by theme (use subheadings if needed).
- **Takeaways** — actionable conclusions. What should the reader do with this information? What's the "so what?"

#### Multi-Source Handling

**Independent mode (default):** Output a separate summary for each source. Use a heading with the source name/title to separate them.

**Synthesized mode (`--synthesize`):** Read all sources first, then produce a single combined summary:

- **TL;DR** — unified thesis across all sources.
- **Common Themes** — what the sources agree on or reinforce.
- **Divergences** — where sources differ, contradict, or present different perspectives.
- **Key Points by Source** — brief per-source highlights so the reader knows what came from where.
- **Takeaways** — synthesized conclusions drawing on all sources.

### Step 5: Save to File (if `--save`)

If the `--save` flag is present:

1. **Determine the file path:**
   - If a path was given after `--save`, use it.
   - If no path was given, generate a descriptive filename: `tldr-<concise-descriptive-lc-name>.md`. The name should reflect the content (e.g., `tldr-react-19-upgrade-guide.md`, `tldr-python-type-hints-talk.md`). Use lowercase, hyphens for spaces, keep it under 60 characters.

2. **Check for existing files:**
   - Use Glob to check if the target filename already exists.
   - If it does, append `-2`, `-3`, etc. until you find an unused name.

3. **Write the file:**
   - Use the Write tool.
   - Include the source URL(s) or path(s) at the top of the file as a reference.
   - Write the full summary below.

4. **Confirm to the user:** "Summary saved to `<path>`."
```

- [ ] **Step 2: Verify the file was created correctly**

Run: `cat skills/tldr.md | head -5`
Expected output shows the frontmatter:
```
---
name: tldr
description: Use when the user wants to summarize a URL, PDF, YouTube video, or other source into a scannable need-to-know summary — triggered by /tldr or when asked to summarize/digest external content
---
```

- [ ] **Step 3: Commit**

```bash
git add skills/tldr.md
git commit -m "feat: add tldr skill for summarizing sources"
```

---

### Task 2: Test with a web page

- [ ] **Step 1: Test basic web page summarization**

Invoke the skill manually in Claude Code:
```
/tldr https://en.wikipedia.org/wiki/Rubber_duck_debugging
```

**Verify:**
- Source is detected as a web page
- WebFetch is used to retrieve the content
- Output is a scannable summary (likely short/simple format for a brief article)
- Tone is conversational and jargon-free
- No navigation, sidebar, or boilerplate content leaked into the summary

- [ ] **Step 2: Test `--save` with auto-generated filename**

```
/tldr https://en.wikipedia.org/wiki/Rubber_duck_debugging --save
```

**Verify:**
- A file like `tldr-rubber-duck-debugging.md` is created in the current directory
- File includes the source URL at the top
- File was not overwritten if it already existed (check for `-2` suffix)

- [ ] **Step 3: Test `--strict` mode**

```
/tldr https://en.wikipedia.org/wiki/Rubber_duck_debugging --strict
```

**Verify:**
- No "For context:" additions or external knowledge
- Every point traces to the page content

---

### Task 3: Test with a YouTube video

- [ ] **Step 1: Test YouTube transcript extraction**

```
/tldr https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

**Verify:**
- Video ID is correctly extracted
- Transcript fetching is attempted
- Sponsor/promotional content is filtered if present
- Output is a scannable summary

- [ ] **Step 2: Test with a longer, content-rich video**

Pick a longer educational video (e.g., a conference talk). Verify:
- The long/complex format is used (TL;DR, Key Points, Details, Takeaways)
- Substantive content is captured, filler is filtered

---

### Task 4: Test with a PDF

- [ ] **Step 1: Test with a local PDF**

Find or download a PDF file, then:
```
/tldr /path/to/local/file.pdf
```

**Verify:**
- Source is detected as PDF
- Read tool is used
- Summary is generated from the PDF content

- [ ] **Step 2: Test with a remote PDF URL**

```
/tldr https://example.com/some-document.pdf
```

**Verify:**
- Source is detected as PDF (URL ends in `.pdf`)
- WebFetch is used to retrieve it
- Summary is generated

---

### Task 5: Test multi-source and synthesize

- [ ] **Step 1: Test independent multi-source**

```
/tldr https://en.wikipedia.org/wiki/Rubber_duck_debugging https://en.wikipedia.org/wiki/Pair_programming
```

**Verify:**
- Two separate summaries are produced
- Each has a heading identifying the source

- [ ] **Step 2: Test `--synthesize`**

```
/tldr https://en.wikipedia.org/wiki/Rubber_duck_debugging https://en.wikipedia.org/wiki/Pair_programming --synthesize
```

**Verify:**
- A single combined summary is produced
- Uses the synthesized format: TL;DR, Common Themes, Divergences, Key Points by Source, Takeaways
- Themes are actually connected across sources, not just concatenated

- [ ] **Step 3: Commit any fixes**

If any issues were found during testing and the skill file was updated:
```bash
git add skills/tldr.md
git commit -m "fix: refine tldr skill based on testing"
```

---

### Task 6: Install the skill

- [ ] **Step 1: Determine the installation method**

The skill needs to be registered so Claude Code can discover it via `/tldr`. Check how the user's existing skills are installed — look at the Claude Code settings or plugin configuration to understand the registration mechanism.

- [ ] **Step 2: Install or register the skill**

Follow the discovered registration method. This typically involves adding the skill path to the Claude Code configuration.

- [ ] **Step 3: Verify installation**

Start a fresh Claude Code session and run:
```
/tldr https://en.wikipedia.org/wiki/Rubber_duck_debugging
```

Confirm the skill is discovered and invoked correctly.

- [ ] **Step 4: Commit any configuration changes**

```bash
git add -A
git commit -m "chore: register tldr skill with Claude Code"
```
