---
name: mh-review-developer-experience
description: Review branch changes for readability, API clarity, maintainability, testability, diagnostics, and developer experience. Use directly or as a specialist reviewer launched by mh-review-code.
---

# Developer Experience Review

Read `../review-principles/PRINCIPLES.md` before the review. Use its priority order and its full Developer Experience section as the review baseline. Also use relevant Safety and Performance principles because clear code must make correctness and cost easier to verify.

Adapt TigerStyle-derived principles to the repository's language, runtime, workload, and documented standards. Preserve the purpose of a principle instead of applying a Zig-specific rule literally. Treat the 70-line function limit and zero-dependency policy as prompts unless the repository adopts them as rules.

Review the changes between `HEAD` and a fixed point supplied by the user or orchestrator.

## Scope

1. Confirm the fixed point resolves with `git rev-parse <fixed-point>`.
2. Review `git diff <fixed-point>...HEAD`.
3. Use `git log <fixed-point>..HEAD --oneline` to understand the change intent.
4. Inspect surrounding code when necessary, but report only problems introduced or exposed by the diff.

Focus on:

- precise domain nouns and verbs without ambiguous abbreviations
- units and qualifiers that distinguish indexes, counts, sizes, and durations
- functions and modules that fit one mental model
- visible control flow and centralized state transitions
- small interfaces with unambiguous parameters and return types
- state, validation, ownership, and cleanup close to their use
- API usability and consistency
- maintainability and testability
- useful errors and diagnostics
- comments and documentation that explain why and how
- dependency and tooling costs in the context of the project
- unnecessary complexity and surprising behavior
- consistency with repository conventions and automated formatting

Report cross-domain findings when they materially affect developer experience. Do not suppress a finding because another reviewer might also report it.

## Finding threshold

Report actionable problems with concrete maintenance or usability impact. Avoid subjective style preferences unless they conflict with repository conventions or obscure behavior. Put uncertain assumptions under **Open Questions**, not **Findings**. Do not include generic praise.

Use these severities:

- `critical`: the change is effectively unsafe to maintain or review
- `high`: major API, diagnostic, or maintainability problem
- `medium`: meaningful clarity, testability, or usability problem
- `low`: small but concrete friction or inconsistency

## Output

Keep the report concise. Assign stable IDs in discovery order: `DX-1`, `DX-2`, and so on.

```markdown
## Findings

### DX-1 — <severity>: <summary>
- Location: `path:line-line`
- Evidence: <specific evidence from the diff>
- Impact: <concrete developer or maintenance cost>
- Recommendation: <specific change>
- Confidence: high | medium | low

## Open Questions
- <question, assumption, and why it matters>
```

If there are no findings or questions, say so explicitly.
