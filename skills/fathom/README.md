# fathom

Produces a comprehensive learning guide from any source. Unlike a summary, fathom is designed for understanding — defined terms, explained concepts, concrete examples, and connections between ideas. Works with URLs, PDFs, YouTube videos, and local files. Output is NotebookLM-ready for generating study guides, flashcards, and quizzes.

## Invocation

```
/fathom <source1> [source2 ...] [--batch] [--deep] [--strict] [--save [path]]
```

## Flags

| Flag | What it does |
|------|-------------|
| `--batch` | Generate a separate learning guide per source instead of one synthesized guide across all sources |
| `--deep` | YouTube only. Pull extended metadata alongside the transcript for richer context. Slower and more token-intensive. |
| `--strict` | Pure attribution mode. Every point must trace directly to the source. No inferences, no external knowledge. |
| `--save [path]` | Write the guide to a file. Auto-generates a filename like `fathom-kubernetes-networking.md` if no path given. Never overwrites existing files. |

## Output Structure

- Overview — what this covers and why it matters
- Core Concepts — each concept explained in plain language with examples
- Key Facts & Insights — specific, standalone points worth remembering
- How It Works — step-by-step for multi-step processes or systems
- Practical Applications — real-world uses drawn from the source
- Key Terms & Definitions — a reference table
- Connections & Relationships — how the concepts relate to each other
- Common Misconceptions — when the source addresses them explicitly
- Open Questions — gaps and unresolved points flagged honestly

## Requirements

YouTube transcript extraction requires [yt-dlp](https://github.com/yt-dlp/yt-dlp):

```bash
brew install yt-dlp
```
