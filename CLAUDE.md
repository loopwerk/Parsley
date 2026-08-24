# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Parsley is a Swift library that parses GitHub Flavored Markdown into HTML. It wraps the C-based `swift-cmark-gfm` library and adds support for YAML front matter, document title extraction, and code fence titles with `data-title` attributes.

## Build & Test Commands

```bash
swift build           # Build the library
swift test            # Run all tests
swift test --filter ParsleyTests.ParsleyTests.testBare   # Run a single test
```

CI runs on both macOS (latest Xcode) and Linux (Ubuntu).

## Architecture

All source code is in `Sources/Parsley/` (4 files):

- **Parsley.swift** — Public API via static methods on a `Parsley` struct (no instances). Two entry points: `Parsley.html()` for plain HTML conversion, `Parsley.parse()` for full parsing that returns a `Document` with metadata and title. Contains the C FFI calls to cmark-gfm and regex-based pre/post-processing for code fence titles.
- **Document.swift** — Immutable struct holding parsed output: `title`, `body` (HTML), `rawBody` (markdown), and `metadata` (dictionary from YAML front matter).
- **MarkdownOptions.swift** — `OptionSet` for rendering flags (`.safe` is the default; `.unsafe` allows raw HTML; `.smartQuotes`, `.hardBreaks`, etc.).
- **SyntaxExtension.swift** — Enum wrapping GFM syntax extensions (autolink, strikethrough, table, tagfilter, tasklist). Handles C pointer management for cmark extension registration.

### Key Implementation Details

- Document parsing uses `Scanner` to split input into YAML front matter (between `---` delimiters), first `# ` heading (title), and body.
- Code fence titles are processed in two passes: a regex preprocessor converts `title="..."` attributes into HTML comments before cmark parsing, then a postprocessor converts those comments into `data-title` attributes on `<pre>` tags.
- All C resources (`cmark_parser_free`, `cmark_node_free`, `cmark_release_plugins`) are explicitly freed after use.

## Conventions

- Commit messages follow conventional commits format (`feat:`, `fix:`, `chore:`, `doc:`).
- The codebase uses 2-space indentation.

## Communication style — be direct and honest

When writing something intended for human consumption (a comment, commit message, reply to prompt), use as few words as possible. Pick every word meticulously to reduce the volume to a strict minimum. Be down to the point. Less is more. Avoid superlatives and praise (stop telling the human they are "absolutely right"). Be direct and honest, like a Dutch person would, rather than wrapping everything in layers of politeness.

## Accuracy — never guess or assume

**Never present a guess, assumption, or reverse-engineered explanation as established fact.** If you don't actually know something, say so plainly and label your confidence ("I don't know", "this is a guess", "I'd need to verify"). Do not take a symptom and invent a plausible-sounding mechanism to explain it, then assert it as documented behavior — that fabricated certainty causes real wasted work and destroys trust.

- **Use Google.** Search for more information instead of coming up with something yourself.
- **Get evidence before asserting.** Inspect the real environment, read the source, or test it — don't theorize.
- **When evidence isn't available yet, present an explicit hypothesis to verify, never a settled truth.**

## Don't do more than asked for

When asked for a code review, just review the code without running anything. When asked to work on a feature, don't touch unrelated code. Always do the least amount of work to fulfill the request, and note possible follow-ups.

## Code comments

Keep comments short and about the code _as it is now_. A comment must explain what the current code does or why, for someone reading it fresh.

- **If the code is obvious, don't comment it.** A comment that just restates what the code plainly says is noise. Only add one when it earns its place.
- **Plain language a junior can follow.** Describe the situation in everyday terms; avoid framework-internals jargon. Comments are read by the whole team.
- **Never narrate history.** Don't describe what the code used to do, what a previous attempt was, what changed, or why the old approach was abandoned. Git already records this. Such notes are stale the moment they're written and add noise.
- **No changelogs, dates, names, or PR/review references in code.** That context belongs in the commit message or PR description.
- **Prefer one or two plain sentences** over multi-line paragraphs. If a comment needs a paragraph to justify the code, the code usually needs rework, not the essay.
- Comment the non-obvious _why_ (a workaround for a specific client bug, an ordering constraint), not the obvious _what_.

## Testing

**Write the failing test first, then fix.** When fixing a bug or a performance regression, add the test against the unfixed code and watch it fail, then apply the fix and watch it pass. Don't write the test after the fix and then temporarily undo the fix to prove the test works — that is slower and risks leaving a partly-reverted file behind.

## Self-review before committing

**Read your own diff against the rules in this file before every commit.** Not the code you remember writing — the actual `git diff --cached`. Comments in particular get written mid-fix, while the reasoning is still fresh and the old code is still in mind, and they read very differently once that context is gone. Reviewing at commit time is the only point where you see them the way the next person will.

Fix what you find.
