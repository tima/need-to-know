# Skill Testing

Manual validation suite for tldr and fathom skills.

## Test Sources

- `sources/short-article.md` - 200-word article on Pomodoro Technique (tests minimal structure adaptation)
- `sources/long-article.md` - 3000-word comprehensive guide on container orchestration (tests full structure with Details/Data sections)
- `sources/sample-transcript.txt` - Mock YouTube transcript on git rebase (tests transcript processing)
- `sources/academic-paper-excerpt.md` - Byzantine Fault Tolerance paper excerpt (tests technical concept handling, terminology)

## Running Tests

### tldr Tests

```bash
# Short article - should use minimal structure (BLUF + Key Points + Takeaways only)
/tldr tests/sources/short-article.md

# Long article - should include Details and Data sections
/tldr tests/sources/long-article.md

# YouTube transcript
/tldr tests/sources/sample-transcript.txt
```

### fathom Tests

```bash
# Academic paper - should include Core Concepts, Key Terms, Connections
/fathom tests/sources/academic-paper-excerpt.md

# Short article - should skip sections not relevant (e.g., How It Works, Key Terms)
/fathom tests/sources/short-article.md
```

### Multi-Source Tests

```bash
# tldr synthesis - should create unified BLUF, Common Themes, Divergences
/tldr tests/sources/short-article.md tests/sources/sample-transcript.txt --synthesize

# tldr independent - should produce two separate files
/tldr tests/sources/short-article.md tests/sources/long-article.md --save

# fathom batch - should create separate guides, one file per source
/fathom tests/sources/short-article.md tests/sources/academic-paper-excerpt.md --batch --save
```

## Quality Checks

### Template Adaptation
- Short content (< 500 words): BLUF + Key Points + Takeaways only, no Details
- Medium content (500-2000 words): Add Details subsections
- Long content (> 2000 words): Full structure with multiple themed Details sections
- Data-rich content: Data section with comparison tables

### Verification Pass
- All Key Points and Takeaways trace directly to source content
- No statistics, dates, names, or quotes that aren't in the source
- No conclusions that go beyond what the source says
- For long content (long-article.md): spot-check only — Key Points verified, Details subsections not

### Fidelity Policy
- Added context (if any) marked with "*Note:*" in italics
- No fabricated information
- Gaps flagged honestly ("The source doesn't clarify...")
- Conflicts presented as **Conflicting Evidence** without reconciliation

### Date Extraction
- Published date extracted from a single obvious location only
- Immediate fallback to `[date unavailable]` if not found — no searching

### Caching
- Run the same source twice in a session — second run should be noticeably faster
- No error if cache-helper.sh is missing — skill proceeds normally

### Multi-Source Handling
- tldr --synthesize: unified BLUF, Common Themes, Divergences — not a concatenation
- tldr without --synthesize + --save: one file per source, never combined
- fathom default: weaves insights across sources, uses **Conflicting Evidence** for contradictions
- fathom --batch + --save: one file per source, never combined

### Output Quality
- BLUF captures core insight in 2-4 sentences
- Key Points are specific, standalone bullets (not vague)
- Details organized by clear themes
- Tables used appropriately for comparisons/metrics
- Takeaways are actionable
- Footer format: `tldr | [model] | [date]` or `fathom | [model] | [date]`

## Edge Cases to Test

1. Paywalled content - skill should reject with clear message
2. Missing YouTube transcript - should suggest --deep flag
3. Very long content (3+ hours, 50+ pages) - should note coverage limits upfront
4. --strict mode - verify zero added context, pure attribution
5. --save collision - verify numeric suffix appending (-2, -3, etc.)
6. --save with path argument + multiple sources - path treated as directory, not filename
7. --bluf mode (tldr only) - BLUF output only, verification already run, full summary on request
8. --deep without YouTube source - skill should warn flag will be ignored
9. Fetch failure in multi-source run - skip failed source, notify user, continue with rest
