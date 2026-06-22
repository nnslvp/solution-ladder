---
name: solution-ladder
description: >
  Iterative architecture refinement skill. Forces structured exploration of 3 solution levels
  before recommending the optimal one. Use this skill whenever a task involves refactoring,
  changing how a feature is configured, toggling behavior across modules/packages/gems/services,
  managing global vs local configuration, or resolving design tensions between opt-in and opt-out
  patterns. Also trigger when the user asks to "fix", "clean up", or "improve" how something is
  wired together — especially when the problem smells like a leaky global default, inheritance
  complexity, or feature flags spreading through a codebase. Even if the user only asks for a
  quick fix, run the full ladder — the quick fix is Level 1 and you must go further.
---

# Solution Ladder

When you receive a task that involves architectural or configuration changes, do NOT stop at
the first working solution. Climb the Solution Ladder: have three solutions developed
**independently**, then judge them against the actual situation — which one fits, and which
ones are insufficient or overkill.

## Why this matters

Developers (and AI) naturally stop at the first thing that works. But architectural solutions
exist on a spectrum: the first solution usually patches the symptom, the second restructures
the mechanism, the third questions the default.

A single agent generating all three in one pass produces theater, not exploration: it decides
the winner upfront and writes the other two as strawmen. Anchoring guarantees the "comparison"
is fake. That is why in this skill each level is developed by a **separate subagent that does
not know the other levels exist**, and the verdict comes from a **blind judge** that sees
unlabeled solutions and judges fit-to-situation, not ladder aesthetics. No level is "almost
always right" — the right level is decided by the math of the specific codebase.

## The Three Levels

### Level 1 — "Patch" (conditional logic)
The fastest fix: conditionals, flags, or guards that suppress unwanted behavior. Minimal diff,
quick to ship, adds branching, doesn't change the underlying model. Legitimate when the problem
is local, temporary, or the surrounding code is frozen.

### Level 2 — "Escape hatch" (opt-out API)
A proper API to disable/override the behavior per-consumer. Cleaner than scattered conditionals,
but still assumes the global behavior is the right default. Legitimate when the default IS right
for the large majority of consumers and only a few need out.

### Level 3 — "Right default" (opt-in inversion)
Flip the model: remove the global default, make the behavior opt-in where needed. Maximum
clarity, no inheritance surprises, deletes the "undo" machinery. Legitimate when the math shows
many consumers don't want the behavior — and overkill when only one does.

## Execution

### Step 0 — Triage

Not every fix deserves four subagents. Choose the mode:

- **Deep ladder (subagents)** — the change affects multiple consumers/modules, is hard to
  reverse, touches a shared default, or the user explicitly asks for architectural analysis.
- **Quick ladder (inline)** — single-file change, few consumers, or no subagent tool available.
  Follow the fallback protocol at the end of this file.

Also sanity-check the premise: is the behavior actually wrong, or is the requirement wrong?
If "do nothing" is a plausible answer, say so before climbing anything.

### Step 1 — Build the context pack

Before spawning anyone, assemble a **neutral brief** that every subagent will receive verbatim.
It must contain facts, not opinions:

1. The problem statement as the user gave it.
2. The mechanism involved (mixin, config flag, middleware, decorator, base class, etc.) with
   the relevant code excerpts.
3. **The consumer census** — actually run `grep`/`rg` and count: how many consumers exist, how
   many use the behavior, how many fight it (look for existing workarounds, `skip_*`/`disable_*`
   calls, overrides). Real numbers, file paths included. This census later decides the verdict,
   so do it honestly now.
4. Constraints: code you don't own and can't fork, deadlines the user mentioned, framework
   conventions.

Do NOT include level names, ladder terminology, or any hint of a preferred direction.

### Step 2 — Spawn four explorers in parallel, in the same turn

Each explorer receives: the context pack + the contents of exactly one mandate file. They must
not see each other's mandates or outputs.

**Explorers are design-only — they do NOT touch files.** Every explorer (1–4) returns its solution
as a written proposal with the code shown as an illustrative diff/snippet inside its answer. No
explorer may edit, write, or create a file, or run a repo-mutating command — they explore and
propose; only the main agent applies anything, and only after the verdict.

| Subagent | Mandate file | Territory |
|----------|--------------|-----------|
| Explorer 1 | `agents/explorer-l1.md` | Minimal patch |
| Explorer 2 | `agents/explorer-l2.md` | Opt-out API |
| Explorer 3 | `agents/explorer-l3.md` | Opt-in inversion |
| Explorer 4 | `agents/explorer-wildcard.md` | Everything outside the ladder |

Explorers 1–3 are advocates: each produces the **best possible** version of its level —
working code, honest LOC count, migration list, failure modes. A weak strawman from any
explorer invalidates the whole exercise.

Explorer 4 exists because the ladder is a closed taxonomy: a judge choosing among three known
shapes can never pick a non-obvious solution, since non-obvious options never enter the
candidate set. The wildcard is barred from all three ladder shapes, which forces it sideways —
moving boundaries, changing decomposition, fixing the data model, reusing infrastructure the
codebase already has. It is allowed to conclude "the conventional shapes are right here"; that
is a valid result, not a failure.

### Step 3 — Blind judging

Shuffle the solutions into random order and relabel them **Solution A / B / C / D** (C/D count
depends on whether the wildcard produced a distinct solution or conceded). Strip every mention
of "level", "patch", "escape hatch", "inversion", "wildcard", emoji tags, and any ladder
vocabulary from the explorer outputs before passing them on.

Spawn a judge subagent with: the context pack + the anonymized solutions + the contents
of `agents/judge.md`. The judge ranks them by fit to THIS situation and explicitly flags which
solutions are insufficient and which are overkill.

### Step 4 — Fact-check loop, then synthesize

The judge's output ends with a "what would change my mind" section. Before accepting the
verdict, check it: if the verdict hinges on a fact that is **verifiable in the codebase** and
was missing or assumed in the context pack (e.g., "if more than N consumers actually override
this..."), go verify it now — grep, read the code, get the number. If the verified fact
contradicts the judge's assumption, update the context pack and re-run the judge once with the
correction. One iteration maximum; a judge that flip-flops beyond that signals the problem is
underspecified and the user should be asked.

Then map the verdict back to level names and present in the output format below. You may
disagree with the judge — but state the disagreement explicitly and justify it with facts
from the context pack, not with ladder ideology.

## Decision heuristics (for triage, the judge has its own copy)

- **You can't change the library/framework** — Level 2 may be the ceiling. State it.
- **Real time pressure** — Level 1 is acceptable as a temporary measure with a follow-up
  ticket; say so explicitly.
- **The default is correct for 90%+ of consumers** — opt-out (Level 2) genuinely beats making
  19 consumers opt in. The consumer census decides, not aesthetics.
- **Only 1–2 consumers total** — a full inversion may be overkill; proportionality matters.

## Generalized patterns to recognize

| Domain | Level 1 (Patch) | Level 2 (Opt-out) | Level 3 (Opt-in) |
|--------|-----------------|--------------------|--------------------|
| Feature flags | `if !disabled?` checks | `disable_feature(:x)` API | Off by default, `enable_feature(:x)` |
| Middleware | Skip with condition | `skip_before_action` | Include per-controller |
| Permissions | Scattered admin checks | `restrict_access` method | No access by default, grant explicitly |
| Logging | `if !quiet_mode` | `silence_logger_for(component)` | `attach_logger` where needed |
| Validation | Skip conditionally | `skip_validation :field` | Declare per-model |
| Event hooks | Guard clause in handler | `unsubscribe` API | Explicit `subscribe` |
| CSS/styling | `!important` overrides | `.no-theme` reset class | Apply theme per-component |

When you see ANY of these patterns, run the ladder.

## Anti-patterns to flag during context-pack assembly

- A method/config whose only job is to UNDO something another method did
- A `disable_*`/`skip_*` API with more callers than the original `enable_*`
- Boolean config flags that most consumers set to `false`
- Inheritance chains where children immediately override parent behavior
- Comments like "we don't need this here but it's included globally"

These are facts — put them in the census section of the context pack, without editorializing.

## Output format

```
## Analysis
[Context pack summary: mechanism, consumer census with real numbers, constraints]

## ⚡ Level 1 — Patch
[Explorer 1's solution: code + LOC + when this would be enough]

## 🔧 Level 2 — Escape Hatch
[Explorer 2's solution: code + LOC + when this would be enough]

## ✅ Level 3 — Right Default
[Explorer 3's solution: code + LOC + what it deletes]

## 🔭 Lateral — Outside the Ladder
[Explorer 4's solution: shape chosen, code + LOC + system-fit argument.
If the wildcard conceded, one line: "Lateral exploration confirmed this is a configuration
problem — sketches considered: ..."]

## Verdict
Judge's ranking: [labels mapped back to names, with one-line reasoning each]
Flagged as insufficient: [solution(s) + why]
Flagged as overkill: [solution(s) + why, or "none"]
Fact-check: [verified assumptions, or "verdict did not hinge on unverified facts"]

## Recommendation
Level N is recommended because [specific reason grounded in the census].
Lines of code: L1 = N, L2 = N, L3 = N (actual counts from explorer code).
Risk: [what could go wrong and mitigation].
Migration: [files/consumers that must change, from the census].
[If you disagree with the judge: state it here with factual justification.]
```

## Fallback: no subagent tool available

Run the same protocol sequentially yourself, preserving as much independence as the format
allows:

1. Build the context pack first (including the real consumer census) — this is non-negotiable.
2. Write each solution as a **complete, separate pass**: open the corresponding
   `agents/explorer-*.md` (l1, l2, l3, then wildcard), follow it fully, finish the solution
   before reading the next mandate. Do not edit earlier solutions after reading later mandates.
3. Then open `agents/judge.md` and judge your solutions against its checklist with fresh
   eyes — score each criterion in writing before forming a verdict. The written scores come
   first, the verdict second; this ordering is what protects you from rationalizing a
   pre-chosen winner.
4. Run the fact-check on the judge's "what would change my mind" section, then synthesize in
   the standard output format.
