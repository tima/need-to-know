# tldr

Produces a structured, scannable brief from any source. Designed for fast need-to-know comprehension — you get the bottom line, key points, and takeaways without reading the whole thing. Works with URLs, PDFs, YouTube videos, and local files.

## Invocation

```
/tldr <source1> [source2 ...] [--synthesize] [--deep] [--strict] [--bluf] [--save [path]]
```

## Flags

| Flag | What it does |
|------|-------------|
| `--synthesize` | Combine multiple sources into one unified summary instead of separate summaries per source |
| `--deep` | YouTube only. Pull extended metadata (tags, chapters, categories, view counts) alongside the transcript. Slower and more token-intensive. |
| `--strict` | Pure attribution mode. Every point must trace directly to the source. No inferences, no added context. |
| `--bluf` | Output only the BLUF to chat, then ask if you want the full summary. Full analysis still runs. |
| `--save [path]` | Write the summary to a file. Auto-generates a filename like `tldr-react-server-components.md` if no path given. Never overwrites existing files. |

## Output Structure

- BLUF — the single most important thing to know
- Key Points — bulleted core ideas
- Details — organized by theme with subsections
- Data — comparison tables, timelines, metrics (when applicable)
- Takeaways — actionable conclusions and next steps

## Requirements

YouTube transcript extraction requires [yt-dlp](https://github.com/yt-dlp/yt-dlp):

```bash
brew install yt-dlp
```
