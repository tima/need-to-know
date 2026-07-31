# need-to-know

Two Claude Code skills for fast comprehension of any content — articles, blog posts, research papers, tutorials, and YouTube videos.

Both skills accept URLs, PDFs, YouTube videos, and local files as sources.

---

## Skills

**[tldr](skills/tldr/SKILL.md)** — Produces a structured, scannable brief from any source. Designed for fast need-to-know comprehension — you get the bottom line, key points, and takeaways without reading the whole thing. See [SKILL.md](skills/tldr/SKILL.md) for all flags and usage.

**[fathom](skills/fathom/SKILL.md)** — Produces a comprehensive learning guide that helps you understand a topic, not just summarize it. Defines terms, explains concepts, shows connections. Works as NotebookLM source material. See [SKILL.md](skills/fathom/SKILL.md) for all flags and usage.

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

### Permissions

Both skills run shell commands that require allowlist entries in `~/.claude/settings.json` to avoid approval prompts. Add these to `permissions.allow`:

```json
"Bash(yt-dlp --no-download *)",
"Bash(python3 -m youtube_transcript_api *)",
"Bash(date *)"
```

- `yt-dlp` and `youtube_transcript_api` — YouTube metadata and transcript fetch (both skills)
- `date` — footer timestamp when using `--save` (both skills)

### Uninstall

```bash
npx skills remove tldr           # project scope
npx skills remove tldr --global  # user scope
npx skills remove fathom           # project scope
npx skills remove fathom --global  # user scope
```

## License

MIT — see [LICENSE](LICENSE).
