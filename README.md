# need-to-know

Two Claude Code skills for fast comprehension of any content — articles, blog posts, research papers, tutorials, and YouTube videos.

- **tldr** — scannable summaries that cut straight to what matters
- **fathom** — deep learning guides that help you actually understand the material

Both work with the same source types: URLs, PDFs, YouTube videos, and local files.

---

## Skills

### tldr

Produces a structured, scannable brief from any source. Designed for fast need-to-know comprehension — you get the bottom line, the key points, and the takeaways without reading the whole thing.

#### Usage

```
/tldr <source1> [source2 ...] [--synthesize] [--deep] [--strict] [--bluf] [--save [path]]
```

#### Flags

| Flag | What it does |
|------|-------------|
| `--synthesize` | Combine multiple sources into one unified summary instead of separate summaries per source |
| `--deep` | YouTube only. Pull extended metadata (tags, chapters, categories, view counts) alongside the transcript for richer context. Slower and more token-intensive. |
| `--strict` | Pure attribution mode. Every point must trace directly to the source. No inferences, no added context. |
| `--bluf` | Output only the BLUF to chat, then ask if you want the full summary. Full analysis still runs — only the output is abbreviated. |
| `--save [path]` | Write the summary to a file. Without this flag, output goes to the chat. If no path given, auto-generates a filename like `tldr-react-server-components.md`. Never overwrites existing files. |

#### Examples

```
/tldr https://example.com/article

/tldr https://youtu.be/abc123

/tldr paper.pdf --strict

/tldr https://example.com/article --bluf

/tldr https://youtu.be/abc123 --deep --save

/tldr https://site1.com https://site2.com --synthesize --save notes/combined.md
```

#### Output structure

Each summary includes:

- **BLUF** — the single most important thing to know, written for someone who reads nothing else
- **Key Points** — bulleted core ideas
- **Details** — organized by theme with subsections
- **Data tables** — comparisons, timelines, metrics (when applicable)
- **Takeaways** — actionable conclusions and next steps

---

### fathom

Produces a comprehensive learning guide from any source. Unlike a summary, fathom is designed for understanding — defined terms, explained concepts, concrete examples, and connections between ideas. Output works as source material for NotebookLM to generate study guides, flashcards, and quizzes.

#### Usage

```
/fathom <source1> [source2 ...] [--batch] [--deep] [--strict] [--save [path]]
```

#### Flags

| Flag | What it does |
|------|-------------|
| `--batch` | Generate a separate learning guide per source instead of one synthesized guide across all sources |
| `--deep` | YouTube only. Pull extended metadata alongside the transcript for richer context. Slower and more token-intensive. |
| `--strict` | Pure attribution mode. Every point must trace directly to the source. No inferences, no external knowledge. |
| `--save [path]` | Write the guide to a file. Without this flag, output goes to the chat. If no path given, auto-generates a filename like `fathom-kubernetes-networking.md`. Never overwrites existing files. |

#### Examples

```
/fathom https://example.com/tutorial

/fathom https://youtu.be/abc123

/fathom research-paper.pdf --strict --save

/fathom https://youtu.be/abc123 --deep

/fathom https://site1.com https://site2.com

/fathom https://site1.com https://site2.com --batch --save guides/
```

#### Output structure

Each learning guide includes:

- **Overview** — what this covers and why it matters
- **Core Concepts** — each concept explained in plain language with examples
- **Key Facts & Insights** — specific, standalone points worth remembering
- **How It Works** — step-by-step for multi-step processes or systems
- **Practical Applications** — real-world uses drawn from the source
- **Key Terms & Definitions** — a reference table
- **Connections & Relationships** — how the concepts relate to each other
- **Common Misconceptions** — when the source addresses them explicitly
- **Open Questions** — gaps and unresolved points flagged honestly

---

## tldr vs. fathom

| | tldr | fathom |
|--|------|--------|
| Goal | Fast need-to-know brief | Deep understanding |
| Length | Compact | Comprehensive |
| Good for | Deciding if something is worth your time, quick reference | Studying, teaching yourself, building on the material |
| Multi-source default | Independent summaries | Synthesized into one guide (use `--batch` for separate guides) |
| NotebookLM ready | No | Yes |

---

## Requirements

Both skills require [yt-dlp](https://github.com/yt-dlp/yt-dlp) for YouTube transcript extraction.

```
brew install yt-dlp
```

---

## Installation

```bash
# All skills, user scope — available in all sessions (recommended)
npx skills add tima/need-to-know -g

# All skills, project scope — this project only
npx skills add tima/need-to-know

# Specific skills only
npx skills add tima/need-to-know --skill tldr -g
npx skills add tima/need-to-know --skill fathom -g
```

Local development install:
```bash
git clone https://github.com/tima/need-to-know.git ~/projects/need-to-know
ln -sf ~/projects/need-to-know/skills/tldr ~/.claude/skills/tldr
ln -sf ~/projects/need-to-know/skills/fathom ~/.claude/skills/fathom
```

### Uninstall

```bash
npx skills remove tldr           # project scope
npx skills remove tldr --global  # user scope
npx skills remove fathom           # project scope
npx skills remove fathom --global  # user scope
```

## License

MIT — see [LICENSE](LICENSE).
