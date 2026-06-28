# TODO

## Skill Quality

### Sync source SKILL.md with installed version content

The globally installed versions of tldr and fathom (installed June 7, before recent
optimizations) contain content that was lost when the source was condensed. Neither
version is currently a superset of the other. The source has all recent fixes and
performance improvements; the installed versions have better instructional detail.

Content in installed versions worth pulling back into source:

- **Ambiguity check** — before fetching, assess if the request is clear enough to
  proceed; stop and ask if terminology is ambiguous or scope too broad
- **YouTube transcript failure handling** — explicit user message when script fails
  ("No transcript available. Try --deep for metadata-based analysis.")
- **Zero-hallucination policy** (fathom) — never bridge gaps with inference; flag
  missing information rather than filling it
- **Contradiction flagging** — when sources conflict, present both sides as
  **Conflicting Evidence** rather than reconciling
- **Uncertainty labeling** (fathom) — prefix unverified claims with
  "The source claims (unverified):"
- **UTC timestamp step** — fetch current time before generating output for use in
  the metadata footer; Bash preferred, web search fallback
- **Horizontal rule guidance** — use `---` exactly once, immediately before the
  footer; never between content sections
- **Richer output templates** — more explicit structure in the output block,
  clearer BLUF guidance ("bottom line first, written for someone who reads nothing else")
- **Synthesize output structure** (tldr) — explicit sections: Common Themes,
  Divergences, Key Points by Source
- **Per-source date handling** (fathom multi-source) — when dates vary
  significantly across sources, list them per-source rather than using earliest

### Fix --save path ambiguity in multi-source mode

When multiple sources are given and a path argument is provided to --save, the
skill treats it as a directory prefix. Two gaps:

- No instruction to create the directory if it doesn't exist
- No handling for when the path argument looks like a filename (e.g. `output.md`)
  rather than a directory — skill should detect this and warn or adapt
