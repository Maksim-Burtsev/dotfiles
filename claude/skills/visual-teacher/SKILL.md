---
name: visual-teacher
description: "Visual-first, note-ready teaching for non-trivial explanation or learning requests across any domain. Use when the user asks to explain, teach, compare, justify a decision, show how/why something works, create a конспект, схема, diagram, mental model, flow, timeline, map, table, or interactive/HTML study artifact; or when a clear answer needs visual structure because it has multiple parts/actors, sequence/order, parallelism, state changes, causality, formulas/probabilities, data/model/scoring logic, trade-offs, failure paths, or hidden invariants. Do not use for trivial one- or two-sentence answers, simple naming/formatting/local syntax, quick factual lookups, urgent incident answers, or when the user asks for only text/no diagrams. Prefer the smallest useful visual, and create HTML only when explicitly requested."
---

# Visual Teacher

## Core behavior

Explain complex ideas like a good teacher at a whiteboard: compact, visual, grounded, and easy to copy into paper notes.

This skill is domain-agnostic. Decide by the shape of the explanation, not a fixed topic list:

- multiple parts, actors, inputs, states, phases, or options;
- time, order, waiting, feedback loops, or causality;
- formulas, probabilities, thresholds, scoring, or transformations;
- hidden invariants, failure paths, risk, or trade-offs;
- the user is learning and may want a notebook-ready explanation.

Use the smallest visual that genuinely improves understanding. Do not decorate simple answers with diagrams.

## Non-goals and safety

- Do not replace the main task with a long lesson when the user needs a fast decision.
- Do not create diagrams for simple naming, formatting, local syntax, or one-line rationale questions.
- Do not create HTML unless the user explicitly asks for HTML, interactive, browser-openable, printable, or reusable study material.
- Do not let this skill override factuality, domain safety, legal/medical/financial caution, tool-use requirements, or the need to inspect files before explaining code.
- If the topic is current, niche, regulated, or high-stakes, follow the host agent's normal verification and citation rules before presenting the visual explanation.

## Visual escalation rubric

Classify the request before choosing the format.

| Level | Use when | Output contract |
|---|---|---|
| 0 — Plain answer | Trivial/local; answer is naturally 1–2 sentences | No diagram. Short answer only. |
| 1 — Compact visual | One non-trivial concept, mechanism, flow, or comparison | One-sentence mental model, one visual, and 2–4 explanatory callouts. |
| 2 — Teaching note | Multiple actors/phases/options, invariants, failure modes, or code locations | Only the relevant teaching modules from the list below. |
| 3 — Interactive artifact | User explicitly asks for HTML/interactive/browser/printable/reusable artifact | One self-contained HTML file or complete HTML content. |

Escalate only when the visual earns its space. De-escalate when the user asks for speed, says “briefly”, or the answer is obvious without a diagram.

## Level 2 modules

Choose only modules that improve the explanation; do not emit empty or ceremonial sections.

- **Mental model** — one sentence that frames the idea.
- **Primary visual** — Mermaid, ASCII, a formula block, or a compact table. Lead with one visual.
- **Walkthrough** — numbered steps only when the idea has a real order, timeline, or state progression. For comparisons, maps, formulas, and taxonomies, use short unnumbered callouts instead.
- **Why it works** — name the invariant, causal link, or decision rule when one exists.
- **Trade-offs / caveats** — include only material uncertainty, risks, or boundaries.
- **Paper notes** — 2–4 compressed bullets when the user is learning or the answer is worth retaining.

Keep prose short. Let the visual carry structure; explain only the non-obvious parts.

## Choose the right visual by explanation shape

| Explanation shape | Preferred visual |
|---|---|
| Actors exchanging messages, waiting, or competing for a resource | Sequence diagram or swimlane timeline |
| Step-by-step logic, branching, validation, fallback | Flowchart or decision tree |
| Lifecycle, status changes, retries, phases | State machine |
| Components, boundaries, ownership, data movement | Component/data-flow diagram |
| Alternative choices, pros/cons, fit criteria | Comparison matrix |
| Scoring, formulas, probabilities, thresholds | Formula block + pipeline or probability tree |
| Cause/effect, feedback loops, incident dynamics | Causal map or timeline |
| Conceptual taxonomy or mental model | Concept map |
| Quick urgent answer | Decision first; optional tiny ASCII sketch only if it prevents ambiguity |

## Mermaid and ASCII rules

Prefer Mermaid when the host supports it. Otherwise use compact ASCII.

- Keep diagrams small: normally under 12 nodes and under 30 lines.
- Use short labels; avoid full sentences inside nodes.
- Use code/API names only where they anchor the explanation.
- For time/order, make the order visually explicit.
- For alternatives, use a table instead of forcing everything into a diagram.
- Never add decorative visuals that do not teach the mechanism.

## Codebase grounding

When explaining a real codebase:

- Inspect relevant files before making strong claims, if tool access is available.
- Tie visual nodes to actual functions, files, routes, data structures, queries, or services.
- Separate observed facts from assumptions and proposed changes.
- For proposed solutions, explain the intended path and invariant without modifying code unless implementation was requested.

## Interactive HTML artifact rules

Create a browser artifact only when explicitly requested.

If writing files in a repository:

1. Use the path requested by the user.
2. Otherwise prefer `.agent-artifacts/<topic-slug>.html` to avoid polluting production code.
3. If the repo has a docs area and the user wants a durable artifact, use `docs/explanations/<topic-slug>.html`.
4. Mention the file path in the final answer.

HTML requirements:

- One self-contained file.
- Inline CSS and JavaScript only; no CDNs, remote fonts, remote images, or build step.
- Include a visual model and only useful interactions, comparisons, failure paths, or printable notes.
- Set `model.lang`, localize `model.labels`, and choose `model.layout`: `"flow"` for ordered steps with arrows or `"grid"` for unordered concepts without arrows.
- Remove unused sections and replace all sample content before delivering the artifact.
- Include accessible labels and print-friendly styling.

Use `assets/interactive-template.html` as a starting point when a browser artifact is requested.

## Language

Answer in the user's language. Preserve code names, API names, formulas, and established terminology in their original form when that is clearer.

For Russian users, use Russian headings and labels by default:

- Ментальная модель
- Схема
- Что происходит
- Почему это работает
- Компромиссы / риски
- Конспект на бумагу

## Quality checklist

Before finalizing:

- Is the visual necessary, not decorative?
- Did you choose the visual by explanation shape rather than topic name?
- Is the output short enough to scan and copy into notes?
- Did you avoid slowing down urgent work?
- Did you include the invariant/decision rule when relevant?
- If HTML was requested, is it self-contained, localized, accessible, printable, and free of sample placeholders?

## Supporting references

Load references only under these conditions:

- Read `references/decision-rubric.md` only when evaluating or tuning activation, or when an explicit invocation is genuinely borderline.
- Read `references/visual-patterns.md` only after selecting a visual type and needing a concrete syntax/template.
- Read `references/examples.md` only when evaluating output quality or when the response contract remains unclear after reading this file.

The trigger corpus and baseline files are maintainer eval assets, not runtime references. Do not load them while answering ordinary user requests.
