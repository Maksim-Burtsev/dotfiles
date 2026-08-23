# Visual Teacher decision rubric

The trigger is **not** “technical topic”. The trigger is “would a visual mental model make this explanation materially easier to understand or remember?”

## Quick score

Add points:

| Signal | Points |
|---|---:|
| User explicitly asks for diagram, схема, visual, interactive, HTML, map, table, timeline, or notes | +4 |
| User asks to explain/teach/how/why/compare/justify a non-trivial thing | +2 |
| Multiple actors, parts, services, players, variables, stages, or options | +2 |
| Order, timing, waiting, concurrency, feedback, or causality matters | +2 |
| State changes, lifecycle, transitions, retries, thresholds, or phases | +2 |
| Formulas, probabilities, scoring, transformations, or data/model logic | +2 |
| Hidden invariant, safety property, failure mode, or edge case | +2 |
| The answer spans multiple code locations, documents, systems, or assumptions | +1 |
| The user appears to be studying or wants to transfer the answer to paper | +1 |

Subtract points:

| Signal | Points |
|---|---:|
| User asks for quick/urgent/meeting/incident answer | -4 |
| User says “briefly”, “one sentence”, “just answer”, “no diagrams”, or “only text” | -4 |
| Topic is local naming, formatting, syntax, small style choice, or one-line rationale | -4 |
| Simple factual lookup with no mechanism to teach | -3 |

Decision:

- `0–1`: plain concise answer.
- `2–3`: maybe one tiny table/ASCII sketch if it clearly helps.
- `4–6`: one primary visual plus short explanation.
- `7+`: teaching-note format with visual, walkthrough, invariant, caveats, paper notes.

## The whiteboard test

Use visuals when a good teacher would draw one because the idea has structure:

- timeline: “what happens first/next?”
- topology: “what connects to what?”
- contention: “who waits for whom?”
- lifecycle: “how does status change?”
- decision: “which path/option should I choose?”
- formula: “which inputs affect the result?”
- causality: “why does this lead to that?”

Do not use visuals when the teacher would simply answer in one sentence.

## Urgency override

For production incidents, meetings, or fast decisions:

1. Put the decision/fix first.
2. State the immediate action.
3. Add at most one tiny sketch only if it prevents misunderstanding.
4. Avoid full teaching-note mode unless the user asks afterward.

Example:

```text
Use the transaction-scoped lock around the check-and-write section. Re-check state after acquiring it.

Tiny model:
A: lock → re-check → write → commit releases
B: waits ───────────┘ re-check → skip/update
```

## False-positive guardrails

Avoid these over-trigger patterns:

- User asks “why did you name this variable X?” → answer in text.
- User asks “what does this command do?” and it is a simple command → answer in text.
- User asks for a fast incident decision → decision first, no full diagram.
- User asks for formatting/refactoring style → maybe a tiny before/after table, not a teaching note.
- User asks a simple factual question → answer directly unless they ask to learn the concept.

## Domain-agnostic examples of valid triggers

- Code: “Explain how this avoids the race condition.”
- Data/modeling: “Explain how the scoring model converts features into confidence.”
- Math: “Explain Bayes’ theorem visually so I can write notes.”
- Games: “Explain a Dota draft advantage as a diagram.”
- Product/process: “Explain the onboarding flow and where users drop off.”
- Health/finance/legal: Visualize only if allowed by the host policy; keep caution and uncertainty.
