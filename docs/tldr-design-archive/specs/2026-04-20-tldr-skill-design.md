# TL;DR Skill — Design Spec

A Claude Code skill (`/tldr`) that analyzes sources (web pages, PDFs, YouTube videos) and produces scannable need-to-know summaries. Designed for research across multiple sources and deep-diving into individual long-form content.

## Invocation

```
/tldr <source1> [source2 ...] [--synthesize] [--deep] [--save [path]]
```

### Arguments

- **Sources**: One or more URLs, local file paths, or YouTube links.
- `--synthesize`: Produce a single combined summary connecting themes across all sources, instead of independent summaries.
- `--deep`: For YouTube videos, use multimodal video analysis instead of transcript extraction. Slower and more token-intensive.
- `--strict`: Pure attribution mode. Every point in the summary must be directly traceable to the source content. No inferences, no external knowledge added.
- `--save [path]`: Write output to a file.
  - If a path is given, write to that path.
  - If no path is given, generate a descriptive filename based on the source content: `tldr-<concise-descriptive-lc-name>.md` (e.g., `tldr-youtube-transcript-api-overview.md`).
  - **Never overwrite an existing file.** If the filename already exists, append a numeric suffix (e.g., `tldr-youtube-transcript-api-overview-2.md`).

### Source Type Detection

Auto-detected from the input:

- **YouTube**: URLs matching `youtube.com/watch` or `youtu.be/` patterns.
- **PDF**: `.pdf` file extension or local paths to PDF files.
- **Web page**: Everything else.

## Source Handling

### General Principle

All source types: strip non-substantive content (navigation, ads, promotions, boilerplate, sponsor reads, subscribe/like reminders, channel plugs) before summarizing. Summarize only the substantive content.

### Web Pages

Fetch using the WebFetch tool. Extract main content, ignoring navigation, ads, and boilerplate.

### PDFs

- **Local files**: Use the Read tool, which natively handles PDF rendering.
- **Remote URLs**: Fetch with WebFetch, then process.

### YouTube — Transcript Mode (Default)

Fetch the auto-generated or manual transcript via WebFetch against a public caption endpoint. Parse the raw transcript text. Filter out sponsor segments, ad reads, self-promotional content, and other non-substantive filler before summarizing.

### YouTube — Deep Mode (`--deep`)

Use multimodal video analysis instead of transcript. Same content filtering rules apply. Note to user that this mode is slower and more token-intensive.

## Output Format

Adaptive based on content complexity.

### Short/Simple Content

A flat bullet list of key takeaways, 3-8 bullets.

Applies to: brief blog posts, short videos, simple pages.

### Long/Complex Content

Structured sections:

- **TL;DR** — 1-2 sentence essence.
- **Key Points** — the core ideas, bulleted.
- **Details** — supporting context, organized by theme.
- **Takeaways** — actionable conclusions or "so what?"

Applies to: long articles, dense research papers, lengthy talks.

### Synthesized Mode (`--synthesize`)

When summarizing multiple sources together:

- **TL;DR** — unified thesis across sources.
- **Common Themes** — what the sources agree on.
- **Divergences** — where they differ or contradict.
- **Key Points by Source** — brief per-source highlights.
- **Takeaways** — synthesized conclusions.

## Tone

Approachable and conversational — like a knowledgeable colleague briefing you. Direct and human, never cold or robotic. Use clear, jargon-free language at an 8th-grade reading level. Strictly avoid corporate speak and technical buzzwords.

## Content Fidelity

### Gaps and Ambiguity

Summarize only what is explicitly stated in the source. When information is incomplete or ambiguous, flag it (e.g., "The source doesn't clarify...") rather than filling in gaps.

### Hallucination Policy

**Default mode:** Source-grounded with context. Stay faithful to the source content, but Claude may add brief clarifying context from its own knowledge when it aids comprehension (e.g., defining a jargon term). Any added context must be clearly marked (e.g., "For context: ...").

**`--strict` mode:** Pure attribution. Every point in the summary must be directly traceable to the source content. No inferences, no external knowledge, no added context.

## Architecture

**Approach: Single skill, inline tool orchestration.** All logic lives in the skill prompt file. No external scripts, dependencies, or MCP servers.

The skill prompt instructs Claude to:

1. Parse the arguments (sources, flags).
2. Detect each source type.
3. Fetch content using available tools (WebFetch, Read).
4. Filter non-substantive content.
5. Assess content complexity to determine output format.
6. Generate the summary.
7. If `--save`, write to file (with filename generation and no-overwrite logic).

### Multi-Source Flow

- **Default (independent)**: Process each source sequentially, output a separate summary for each.
- **`--synthesize`**: Process all sources first, then produce a single combined summary using the synthesized output format.

## Skill File Structure

A single skill definition file following the Claude Code superpowers skill format:

```
skills/
  tldr.md          # The skill prompt
```

Installed as a Claude Code skill, invocable via `/tldr`.
