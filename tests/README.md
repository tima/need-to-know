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

# fathom batch - should create separate guides
/fathom tests/sources/short-article.md tests/sources/academic-paper-excerpt.md --batch
```

## Quality Checks

Compare outputs to expected baselines in `expected-outputs/*/`. Look for:

### Template Adaptation
- Short content (< 500 words): BLUF + Key Points + Takeaways only, no Details
- Medium content (500-2000 words): Add Details subsections
- Long content (> 2000 words): Full structure with multiple themed Details sections
- Data-rich content: Data section with comparison tables

### Fidelity Policy
- Added context (if any) marked with "*Note:*" in italics
- No fabricated information
- Gaps flagged honestly ("The source doesn't clarify...")
- Conflicts presented as **Conflicting Evidence** without reconciliation

### Date Extraction
- Published dates extracted when obvious
- Graceful fallback to `[date unavailable]` without hanging
- No excessive time spent searching for dates

### Multi-Source Handling
- tldr --synthesize: Actually synthesizes (not just concatenates), unified BLUF, identifies common themes and divergences
- fathom default: Weaves insights across sources, notes sources for clarity, uses **Conflicting Evidence** callouts
- fathom --batch: Separate complete guides per source

### Output Quality
- BLUF captures core insight in 2-4 sentences
- Key Points are specific, standalone bullets (not vague)
- Details organized by clear themes
- Tables used appropriately for comparisons/metrics
- Takeaways are actionable

## Expected Outputs

Baseline outputs in `expected-outputs/` demonstrate:
- Correct structure adaptation per content length
- Proper fidelity (faithful to source, added context marked)
- Appropriate section skipping (fathom)
- Clean synthesis (tldr --synthesize)

Note: These are baselines, not exact targets. Output will vary by model but should follow same principles.

## Edge Cases to Test

1. Paywalled content - skill should reject with clear message
2. Missing YouTube transcript - should suggest --deep flag
3. Very long content (3+ hours, 50+ pages) - should note chunking or coverage limits
4. --strict mode - verify zero added context, pure attribution
5. --save collision - verify numeric suffix appending (-2, -3, etc.)
6. --bluf mode (tldr only) - verify BLUF-only output, prompt for full summary
