---
name: fathom
description: Create comprehensive learning guides from YouTube videos, web articles, PDFs, and other sources. Use when the user wants to deeply understand a topic, create study material, build a learning guide, or prepare content for NotebookLLM. Trigger when the user mentions learning guides, study material, deep understanding, fathom, or wants to turn videos/articles into educational content for studying, flashcards, or quizzes — even if they don't explicitly say "learning guide."
---

# Fathom — Learning Guides from Any Source

Analyze one or more sources and produce a comprehensive learning guide. The output is a standalone document for deep understanding that also works as source material for tools like NotebookLLM to generate study guides, flashcards, and quizzes.

Unlike a summary (which tells you what was said), a learning guide helps you actually *understand* the material — with defined terms, explained concepts, and connections between ideas.

## Usage

`/fathom <source1> [source2 ...] [--independent] [--deep] [--strict] [--save [path]]`

### Arguments

- **Sources** (required): One or more YouTube URLs, web page URLs, local file paths, or PDF paths.
- `--independent`: Generate a separate learning guide for each source instead of synthesizing into one cohesive guide. Without this flag, multiple sources are combined into a single guide that weaves themes together.
- `--deep`: For YouTube videos only. Pull extended metadata (tags, chapters, categories, engagement data) alongside the transcript for richer context. Warn the user this is slower and more token-intensive.
- `--strict`: Pure attribution mode. Every point must trace directly to the source. No inferences, no added context, no external knowledge.
- `--save [path]`: Write the guide to a file.
  - If a path is provided, write to that exact path.
  - If no path is provided, generate a filename: `fathom-<concise-descriptive-lc-name>.md` based on the content (e.g., `fathom-kubernetes-networking-fundamentals.md`).
  - **Never overwrite an existing file.** Before writing, check if the file exists using Glob. If it does, append a numeric suffix (e.g., `fathom-kubernetes-networking-fundamentals-2.md`). Keep incrementing until you find a name that doesn't exist.

## Process

Follow these steps in order:

### Step 1: Parse Arguments

Extract sources and flags from the arguments string. Detect each source type:

- **YouTube**: URL contains `youtube.com/watch` or `youtu.be/`.
- **PDF**: Path ends in `.pdf` or URL ends in `.pdf`.
- **Local file**: Path to a file on the local filesystem.
- **Web page**: Everything else that looks like a URL.

If no sources are provided, tell the user: "Please provide at least one source (URL, file path, or YouTube link)."

If `--deep` is provided but no YouTube sources are detected, tell the user: "Note: --deep applies to YouTube sources only and will be ignored."

### Step 2: Ambiguity Check

Before fetching content, assess whether the request is clear enough to proceed:

- If the user provided a URL or file path, proceed — the content itself provides the context.
- If the user described a topic but the terminology is ambiguous or the scope is too broad, stop and ask for clarification before generating the full guide.

### Step 3: Fetch Content

**Multiple sources:** When given 2+ sources, issue all fetches as concurrent tool calls in a single response — multiple WebFetch calls and Bash commands can run in parallel, so don't wait for one to finish before starting the next.

**Very large sources:** If a source is unusually long (e.g., a 3+ hour video transcript or a multi-chapter document), note this upfront. Focus on the most substantive sections and tell the user which portions were covered or skipped.

For each source, fetch the content:

**Web pages:**
- Use the WebFetch tool to retrieve the page.
- Focus on the main content. Mentally strip navigation, sidebars, footers, ads, cookie banners, and boilerplate before analyzing.
- **Paywalled or gated pages:** If the page returns a login wall, subscription prompt, or access-denied message (look for phrases like "Subscribe to continue", "Sign in to read", "Create a free account"), stop and tell the user: "This page appears to be paywalled or requires a login. Try providing a local copy or an alternative source."

**Local files (including PDFs):**
- Use the Read tool, which natively renders PDF content and reads other file types.

**Remote PDFs (URL ending in .pdf):**
- Try WebFetch first to retrieve the PDF content.
- If WebFetch does not return usable content (e.g., binary garbled output or an error), fall back to downloading with Bash: `TMPFILE=$(mktemp /tmp/fathom-XXXXXX.pdf) && curl -sL -o "$TMPFILE" "<URL>" && echo "$TMPFILE"` — then use the Read tool on the echoed path.

**YouTube — default (transcript mode):**
- Run the helper script via Bash: `~/.claude/skills/fathom/scripts/fetch-transcript.sh "<URL>"`
- The script uses `yt-dlp` to extract the video title, channel, description, and transcript.
- Use the transcript as the primary content. The title, channel, and description provide context.
- If the script fails (non-zero exit), tell the user: "No transcript available for this video. You can try `--deep` for analysis using video metadata."

**YouTube — deep mode (`--deep` flag):**
- Tell the user: "Using deep analysis — pulling extended metadata alongside the transcript."
- Run the helper script to get the transcript: `~/.claude/skills/fathom/scripts/fetch-transcript.sh "<URL>"`
- Additionally, run `yt-dlp --dump-json --no-warnings "<URL>"` via Bash to get the full JSON metadata (tags, categories, chapters, like count, view count, upload date).
- Use both the transcript and extended metadata for richer context.
- If the transcript is unavailable but metadata is available, work from metadata alone and note that no transcript was available.

### Step 3.5: Determine Published Date

Extract the publication date for each source to populate the `Published:` field in the output header:

- **YouTube:** Use the `upload_date` field from the `yt-dlp --dump-json` output (format: YYYYMMDD → convert to e.g. `May 1, 2025`). For default mode, get this from the DESCRIPTION output of the helper script or run a quick `yt-dlp --print upload_date --no-warnings "<URL>"` via Bash.
- **Web pages:** Look for a publication date in the page content (byline, article metadata, `<time>` elements, or "Published on" text). If not found, use `[date unavailable]`.
- **PDFs:** Look for a date on the title page, header, or document metadata. If not found, use `[date unavailable]`.
- **Local files:** Use the file's modification date via Bash: `date -r "<path>" "+%B %-d, %Y"`. If unavailable, use `[date unavailable]`.

**Multiple sources:** Use the earliest published date among all sources, and note it as `Published: [DATE] (earliest source)`. If dates vary significantly, list them per-source in the header instead.

### Step 4: Filter Non-Substantive Content

Before analyzing, mentally filter out:
- Sponsor segments and ad reads
- Self-promotional content (subscribe reminders, channel plugs, merch mentions)
- Navigation elements, headers/footers, cookie notices
- Boilerplate disclaimers
- Repetitive intros/outros

Analyze only the substantive content.

### Step 4.5: Get Current Timestamp

Before generating any output, get the current UTC time for the metadata footer using this priority order:

1. **Bash (preferred):** Run `date -u +"%b-%d-%Y %H:%M GMT"` — fast and reliable.
2. **Web search (fallback):** If Bash fails, search for "current UTC time" and extract the result.
3. **Last resort:** If both fail, use `[timestamp unavailable]`.

Store this value and use it in every footer you produce.

### Step 5: Generate Learning Guide

#### Tone

Write in an approachable, conversational tone — like a knowledgeable friend explaining something over coffee. Be direct and human, never cold or robotic. Use clear, jargon-free language at an 8th-grade reading level. Strictly avoid corporate speak and technical buzzwords. When you must use a technical term, explain it in plain language right away.

#### Depth

This is a learning guide, not a summary. Go deep. The goal is that someone reading this guide walks away actually understanding the material — not just knowing it exists. Include specific details, concrete examples, and enough context that each point stands on its own. A reader should be able to study from this document and answer questions about the topic.

#### Content Fidelity

These rules apply in all modes:

**Zero-hallucination policy:** Never bridge gaps with logical inferences or "likely" scenarios. If information is unavailable, missing, or outside the source content, flag it as uncertain or omit it — don't fabricate. When to write "Information not found" vs. skip a section entirely is governed by the Output Structure rules.

**Contradiction flagging:** If you find conflicting data points across sources (or within a single source), do not reconcile them. Present both sides and label them as **Conflicting Evidence**. Let the reader decide.

**Critical assessment:** When a concept, tool, or approach has notable trade-offs, limitations, or caveats mentioned in the source, include them within the relevant Core Concepts subsection — not as a separate section. Be skeptical rather than optimistic.

**Uncertainty labeling:** If the source presents a claim based on opinion, anecdote, or an unverified statistic rather than established fact, prefix it with "The source claims (unverified):"

**Default mode:** Stay faithful to the source. You may add brief clarifying context from your own knowledge when it genuinely helps understanding (e.g., defining an acronym, providing a date). Always mark added context clearly with "For context: ..." or parenthetical notes. Never present your own knowledge as if it came from the source.

**`--strict` mode:** Pure attribution. Every point must be directly traceable to the source. No inferences, no external knowledge, no added context of any kind. If something is unclear, say so — don't fill the gap.

#### Output Structure

Use this structure for every learning guide. **Skip** a section if the source mentions nothing about that topic. Write the section with "Information not found" only if the source raises the topic but leaves it incomplete or unclear. When in doubt between the two, skip rather than pad.

Every section should contain enough specific detail that a reader could generate quiz questions or flashcards from it. Vague generalizations defeat the purpose.

**Horizontal rule usage:** Use `---` exactly once — immediately before the metadata footer at the end of the document. Never place horizontal rules between sections, subsections, or content blocks.

```
# [Descriptive Title]

**Source:** [Title](URL or path)   ← single source
**Sources:**                        ← multiple sources
- [Title 1](URL1)
- [Title 2](URL2)
Published: [PUBLISHED DATE]

## Overview

2-3 sentences: What this covers, why it matters, and what you'll understand after reading. Set the stage.

## Core Concepts

### [Concept Name]

Explain the concept in plain language. Cover:
- What it is
- Why it matters
- How it works (briefly)
- An example if the source provides one

(Repeat for each major concept from the source)

## Key Facts & Insights

Bulleted list of the most important factual points. Each should be specific and standalone — not vague generalizations. These are the points worth remembering.

## How It Works

(Include only when the source describes a multi-step process, system, or end-to-end mechanism that spans the entire subject — not for explaining how an individual concept works internally. Per-concept mechanics belong in the Core Concepts subsection above.)

Step-by-step or narrative explanation. Use numbered steps for sequential processes, bullets for parallel aspects.

## Practical Applications

Real-world uses, examples, or scenarios drawn from the source. What can someone actually do with this knowledge?

## Key Terms & Definitions

| Term | Definition |
|------|-----------|
| Term 1 | Plain-language definition based on source context |
| Term 2 | ... |

## Connections & Relationships

How the concepts in this guide relate to each other. What depends on what? What builds on what? Draw the map between ideas so the reader sees the bigger picture.

## Common Misconceptions

(Include only if the source explicitly addresses misconceptions or if contradictions surface)

## Open Questions

Things the source left unclear, didn't fully address, or that remain unresolved. Flag gaps honestly.

---

Claude Code | Claude [Model Name] | [Timestamp UTC]
```

#### Multi-Source Handling

**Synthesized mode (default):** When given multiple sources, read all of them first, then produce a single cohesive learning guide:

- Weave insights from all sources together under unified concept headings.
- In the Key Facts section, note which source a point comes from when it's not obvious: "(Source: [title or short reference])".
- If sources contradict each other, use a **Conflicting Evidence** callout rather than picking a side.
- The Connections section should draw relationships both within and across sources — this is where synthesis really shines.

**Independent mode (`--independent`):** Generate a separate learning guide for each source, each with its own heading and full structure.

### Step 6: Save to File (if `--save`)

If the `--save` flag is present:

1. **Determine the file path:**
   - If a path was given after `--save`, use it.
   - If no path was given, generate a descriptive filename: `fathom-<concise-descriptive-lc-name>.md`. The name should reflect the content (e.g., `fathom-react-server-components-deep-dive.md`). Use lowercase, hyphens for spaces, keep it under 60 characters.

2. **Check for existing files:**
   - Use Glob to check if the target filename already exists.
   - If it does, append `-2`, `-3`, etc. until you find an unused name.

3. **Write the file:**
   - Before writing, announce: "Saving to `<path>`..."
   - Use the Write tool.
   - Include sources at the top using the same format as the template: `**Source:** [Title](URL/path)` for a single source, or `**Sources:**` followed by a per-line bulleted list for multiple sources.
   - Write the full learning guide using all applicable sections from the template.
   - End with a horizontal separator (`---`) followed by the metadata footer:
     ```
     Claude Code | Claude [current model name] | [Current UTC timestamp, e.g., Apr-25-2026 18:42 GMT]
     ```

4. **Confirm to the user:** "Learning guide saved to `<path>`."
