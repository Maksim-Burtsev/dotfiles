# Visual patterns

Use these as templates. Adapt language, labels, and detail level to the user.

## 1. Sequence / swimlane: actors over time

Use for parallel requests, lock contention, turn order, handoffs, approvals, game fights, negotiations, and any “who acts when?” explanation.

```mermaid
sequenceDiagram
    participant A as Actor A
    participant B as Actor B
    participant R as Shared resource
    A->>R: start / acquire / act
    B->>R: request same resource
    R-->>B: wait / blocked / delayed
    A->>R: finish / release / commit
    R-->>B: proceed after re-check
```

Key teaching points:

- who can act in parallel;
- who must wait;
- what must be re-checked after waiting;
- where the invariant is enforced.

## 2. Flowchart: process or decision path

```mermaid
flowchart TD
    Start([Start]) --> Input[Read inputs]
    Input --> Check{Condition?}
    Check -- yes --> A[Path A]
    Check -- no --> B[Path B]
    A --> Done([Done])
    B --> Done
```

Use for validation, algorithms, onboarding, workflows, diagnosis, and fallback logic.

## 3. State machine: lifecycle

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Active: publish
    Active --> Paused: pause
    Paused --> Active: resume
    Active --> Completed: finish
    Active --> Failed: error
```

Use for order status, job lifecycle, retry systems, user journey stages, game phases, and learning phases.

## 4. Component / data-flow diagram

```mermaid
flowchart LR
    Input[Inputs] --> Transform[Transform / model / rule]
    Transform --> Score[Score / decision]
    Score --> Action[Action]
    Score --> Feedback[Feedback]
    Feedback --> Transform
```

Use for architecture, models, scoring, pipelines, ETL, analytics, content systems, and cause/effect loops.

## 5. Formula + pipeline

Use when numbers matter but the user needs intuition.

```text
Inputs → Normalize → Weight → Combine → Calibrate → Decision
```

| Part | Meaning | Watch out |
|---|---|---|
| Input | What enters the model | missing/noisy data |
| Weight | How much it matters | overfitting / bias |
| Threshold | When action happens | false positives/negatives |

## 6. Probability tree

```text
Start
├─ Event A: p(A)
│  ├─ Success: p(B|A)
│  └─ Fail:    1 - p(B|A)
└─ Not A: 1 - p(A)
   ├─ Success: p(B|¬A)
   └─ Fail:    1 - p(B|¬A)
```

Use for Bayes, risk, expected value, forecasting, sports prediction, A/B tests, and decision uncertainty.

## 7. Trade-off matrix

Use when the user asks “why this choice?” or several viable options exist.

| Option | Strength | Weakness | Best fit | Avoid when |
|---|---|---|---|---|
| Option A | ... | ... | ... | ... |
| Option B | ... | ... | ... | ... |
| Option C | ... | ... | ... | ... |

End with a decision rule: “choose X when ..., choose Y when ...”.

## 8. Concept map

```mermaid
flowchart TD
    Core[Core idea]
    Core --> Part1[Part 1]
    Core --> Part2[Part 2]
    Core --> Part3[Part 3]
    Part1 --> Implication1[Implication]
    Part2 --> Implication2[Implication]
```

Use for abstract concepts, theory, strategy, taxonomy, and “big picture” explanations.

## 9. Paper notes block

End non-trivial explanations with compact copyable notes:

```text
Конспект на бумагу:
- Главная идея: ...
- Инвариант / правило: ...
- Опасность: ...
- Когда применять: ...
```
