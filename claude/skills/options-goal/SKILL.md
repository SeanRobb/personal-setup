---
name: options-goal
description: Autonomous design-iteration loop built on the options skill. Scaffolds a target with /options conventions, then runs research → build → persona review → cull → iterate rounds by itself until a goal condition holds (e.g. "5 both-liked, 2 interactive"), pausing only for tie-breaks and the final champion pin. Use when the user says "/options-goal", or asks to "iterate until the personas like it", "run the design loop until <condition>", or wants variant exploration driven to a win condition rather than round-by-round by hand. Not for non-visual work (API design, copy, backend).
---

# Options-Goal: run the options loop autonomously until a goal holds

This skill composes the `options` skill into a goal-seeking loop. The user
("the owner") states a target, reviewer personas, and a win condition; you
then run rounds of build → review → cull → iterate on your own, reporting a
scoreboard after each round, until the goal holds and the owner pins a
champion.

## Composition contract

**FIRST ACTION: read `~/.claude/skills/options/SKILL.md`.** Every
scaffolding convention comes from it verbatim and stays exactly compatible:
framework detection, target resolution, `manifest.json`, `mocks.ts`,
self-contained `OptionN.tsx` components, the grid index + `[id]` detail
pages, the shared ICP chip component, the champs index, and the
kill/champion/regen/promote/clean verbs. Its "What NOT to do" list applies
here too. This file only defines what it explicitly adds or overrides:

- The loop is autonomous (the base skill waits for the user between steps).
- Verdicts are strict LIKE/PASS (see REVIEW) instead of free-form, and
  chip labels change accordingly (`A ★LIKE` / `B PASS`, replacing the
  base's `ICP <by>` form).
- **Kill authority is delegated**: culling is autonomous (zero-LIKE
  auto-kill plus standing owner kill rules), overriding the base rule that
  the kill call is always the user's. Champion pinning stays the owner's.
- Manifest gains the extension fields below. One semantic override: `icp`
  becomes current-state per persona per option instead of the base's
  accumulating history (see REVIEW).
- All `/options/*` routes get `noindex` (robots meta tag or route header)
  at scaffold time.

## Invocation

```
/options-goal <target sentence or keywords> | personas: <persona spec> | goal: <win condition>
```

Examples:

```
/options-goal pricing table for the services page | personas: cautious non-technical buyer, design-literate slop skeptic | goal: 5 both-liked, 2 interactive
/options-goal hero section | personas: from docs/icp-*.md | goal: 3 both-liked
```

Defaults when omitted:

- **goal** → 5 liked-by-all with ≥2 animated/interactive.
- **personas** → ask the owner (AskUserQuestion) to describe 2 reviewers in
  one sentence each BEFORE starting. `personas: from <glob>` means read
  those files as the persona briefs.

The goal is a FREE-FORM exit condition — the owner writes it as a
sentence, not parameters. Store it verbatim in the manifest as
`goal.raw`, plus `goal.interpretation`: your one-sentence restatement of
what must be true to stop. If the wording is ambiguous, get a yes on the
interpretation before round 1; if it's plain (like the examples), record
it and go. After every review round, judge the manifest against the
interpretation. Two counting rules are fixed no matter how the goal is
worded: "liked" = a fresh (non-stale) LIKE on a non-killed option, and
"both-liked" / "liked-by-all" = every persona's CURRENT verdict (their
highest-round entry) on that option is such a LIKE. Any other quality
the goal names ("interactive", "animated", "on-brand", …) is yours to
judge per option at check time — counted among the options that
otherwise qualify (a quality nobody LIKEd doesn't satisfy the goal) —
and your judgment shows in the scoreboard so the owner can dispute it.

## Roles

- **Orchestrator (you, the main context)** — never edits project or
  scaffold files (scratchpad screenshots and git commits are yours; design
  and manifest edits are not). You run all owner-facing conversation
  (discovery questions, escalations, scoreboards), route feedback, and
  verify agent claims with your own greps and screenshots.
- **Lead builder (ONE persistent named agent for the whole loop)** — owns
  ALL shared-file edits: scaffolding, `manifest.json`, the grid's modules
  map, `mocks.ts`, the chip component, kill/status flips, chip updates. It
  carries cross-round memory: what died and why, what each persona wants,
  which directions are exhausted. Spawn it once with the Agent tool
  (`name: "lead-builder"`), continue it across rounds via SendMessage.
- **Per-variant builders (short-lived, fanned out each round)** — one per
  variant, 4–6 per round, each writes exactly ONE new self-contained
  `OptionN.tsx` from its brief. Fan out with the Workflow tool's
  `pipeline()` when available; otherwise YOU fan them out with parallel
  Agent calls using the lead's briefs (lead-serial only as a last resort).
  The lead assigns IDs up front from `next_id`, integrates each finished
  variant (module registration + manifest entry), and confirms the build
  compiles and every page renders before reporting the round built.
- **Researcher** — fresh agent for round 1's full research; delta re-runs
  between rounds (see RESEARCH).
- **Persona reviewers (one agent per persona, fresh each round)** — plus
  targeted re-check dispatches between rounds.

Copy is FROZEN for the entire loop — design only. Variants never change
headlines, body copy, prices, or claims. If a design genuinely needs
different copy, that's an owner escalation, not a builder decision.

## The loop

### 1. SCAFFOLD

Run the base skill's discovery questions (vibe / constants / variance)
with the owner YOURSELF via AskUserQuestion — agents can't interview the
owner — in the same exchange that collects personas if those are missing.
Then have the lead builder scaffold per the base skill, plus `noindex` on
every `/options/*` route (Next.js App Router: an `app/options/layout.tsx`
exporting `metadata = { robots: { index: false, follow: false } }`; other
frameworks: the equivalent robots meta per page). Record `goal`,
`personas`, and `round: 0` in the manifest. Commit. Dispatch the round-1
researcher in the same message that briefs the lead — scaffold and
research are independent; don't run them serially.

### 2. RESEARCH

Round 1: best practices + anti-slop patterns for this specific component
type (pricing table, hero, etc.), with concrete do/don't examples; the
report shapes round 1's variant briefs. Between rounds: re-run seeded
with the prior report plus the reviewers' standing objections and open
craft questions ("how do the good ones handle a 4th tier?") so it
researches the delta, not the baseline; skip the re-run when a round is
pure verbatim flip-changes with no open questions.

### 3. BUILD

The lead builder plans the round's variant set (4–6), assigns IDs, writes
the per-variant briefs, fans out the per-variant builders, integrates, and
verifies compile + rendered pages. Then YOU verify independently: grep
that the files/registrations exist, and capture the round's screenshot
set (every living variant's detail route, per the base skill's capture
spec) — inspecting those shots IS your render verification, and the same
set becomes the reviewers' input. An agent saying "done" is a claim, not
a fact.

**Motion capture** (only for options with declared `interactions` —
static variants cost nothing extra): in the same capture pass, drive each
declared interaction and save a labeled keyframe strip — **rest →
trigger → mid-animation → settled** — plus the relevant motion-spec
lines (CSS/JS transitions) as text. Also reconcile declarations against
code: grep each new `OptionN.tsx` for motion markers (`@keyframes`,
`animation`, `transition`, motion libraries) — undeclared motion is a
build defect: declare it or remove it. Builder self-declaration is never
the only gate.

Run the **mechanical motion audit** — executable checks, never eyeball
judgment:

- one-shot / ends static: after the declared duration elapses (hold the
  trigger for hover cases), run `document.getAnimations()` on the
  variant's subtree via the browser javascript tool — anything still
  running, or declared with infinite iterations, fails. (This catches
  loops a frame comparison would miss, e.g. a loop whose period matches
  the comparison interval.)
- reduced motion: the declared motion code carries a
  `prefers-reduced-motion` guard (media query or `matchMedia`)
- affordance at rest: the rest keyframe alone shows the hover affordance

An audit-failing option goes back to the lead builder as a build defect
and is PULLED from the round's review set; the round dispatches once the
surviving set is stable and live, and the fixed option re-enters via a
targeted re-check (never while its fix build is in flight).

### 4. REVIEW

One agent per persona, all dispatched in one message. Each judges the LIVE
pages AND the round's screenshots against a strict bar:

- **LIKE** = "I'd be happy to ship this exactly as-is."
- Everything else = **PASS** + the single highest-leverage change that
  would flip it to LIKE. One change, not a list.

For options with declared `interactions`, the reviewer also gets the
keyframe strips + motion specs next to the full-page shot, and the
verdict must cover the motion — no LIKE on an interactive option whose
interaction the persona hasn't judged from the keyframes and specs. The
shared strips are the motion verdict's anchor (live-page timing varies
per visit and never overrides them). A motion-blind verdict on an
interactive option is rejected at receipt — don't fold it into the
manifest; dispatch a targeted re-check covering the motion.

**Review scope**: options are immutable and the LIKE bar is absolute, so
a standing verdict on an unchanged option cannot legitimately change.
Each round a persona judges only options that are NEW since their last
verdict or whose verdict was stale-flagged; standing verdicts persist
and keep counting. The champion restatement is the exception: each round
every persona restates their champion across ALL living options, and the
★ migrates to wherever they now point.

**One current entry per persona per option.** A fresh verdict REPLACES
that persona's previous non-stale entry on the same option — no
accumulating LIKE+PASS chip pairs across rounds. Two kinds of history do
persist: entries flagged `stale` (muted, until a re-check replaces them),
and a superseded champion pick — the old option's entry loses its ★ in
place and its note records the supersession (per the base skill's history
rule); same single entry, never a second one.

The lead builder folds verdicts into the manifest as chips using the base
`{by, champion?, note}` shape plus the extension fields, so the grid shows
hover-note chips and a ★ on each persona's current champion.

### 5. CULL

After each review round:

- **AUTO-KILL** every option with zero LIKEs.
- Apply any standing **owner kill rules** immediately ("kill everything
  both passed on", "kill anything violating <premise>") — they stay in
  force for future rounds until revoked.
- Kill semantics are the base skill's (status flag, file stays on disk —
  anything is revivable). The addition: every kill writes a manifest
  `kill` note preserving WHY it died and what would revive it (e.g. "one
  bug from LIKE — revive if the overlap bug is fixed").

### 6. ITERATE

Next round evolves survivors:

- Apply each reviewer's flip-change **VERBATIM** — build exactly the change
  they asked for, not your interpretation of its spirit.
- **Convergence rule**: when reviewers independently describe the same
  ideal, build exactly that as its own variant.
- ALL feedback — owner's or a persona's — applied to an existing variant
  produces a **NEW numbered option**. Never mutate: the parent stays for
  A/B comparison and dies by the kill rules if superseded.

Feed the new round's briefs (with any fresh research) to the lead builder;
loop back to step 3.

### 7. OWNER CHANNEL

The owner can interject at any time with direction, screenshots, or
premise corrections. Handle:

- **Direction / kill rules** → apply immediately (steps 5–6).
- **Premise correction** → record in the manifest's `owner_directions`
  with `"kind": "premise_correction"`. It overrides all persona verdicts:
  stale-flag every verdict that predates it (see Operational rules) —
  affected options need re-review.
- **Screenshot feedback** → diagnose first (what exactly is the owner
  reacting to — spacing? contrast? a specific element?), state your
  diagnosis, then translate it into a builder brief. Don't build from a
  raw vibe.

### 8. RE-REVIEW

When a judged variant's successor or a fix lands, dispatch a TARGETED
re-check to the relevant persona(s) describing exactly what changed since
their verdict — not a full re-review of everything.

Reviews never race builds (see Operational rules). If a collision happens
anyway, stale-flag every verdict that could have seen the in-flight
state — the whole batch if the app was broken or half-integrated during
the review — and re-check.

### 9. CADENCE

Fully autonomous between owner inputs. After each review round, commit and
post a compact scoreboard — informational, not blocking. For each
interactive option in the round, record a short GIF of its money-moment
(the shared capture lens if it records, else claude-in-chrome
`gif_creator`) and attach the set to the scoreboard —
owner-facing evidence for tie-breaks and the champion pin. GIFs are for
the OWNER only; AI personas would read a single frame, so they get the
keyframe strips instead.

```
Round 3 — goal "5 both-liked, 2 interactive": have 2 both-liked, 1 of them interactive
| # | A | B | status |
|---|---|---|--------|
| 3 | ★LIKE | LIKE | both-liked |
| 7 | LIKE | PASS: tighten tier gap | 1 like |
| 8 | PASS: too dense | ★LIKE | 1 like |
| 5 | — | — | ⌫ r2: zero likes; revive if simplified |
Next: building 9 (from 7 + B's change), 10 (from 8 + A's change), 11 (convergence: both want quiet emphasis on middle tier)
```

Two routine things block on the owner:

1. **Persona tie-breaks** — when persona guidance splits with no dominant
   direction and the next round depends on the choice: flip-changes that
   contradict each other (or an owner direction) so both can't be
   honored, or champion restatements pointing at incompatible lineages
   when the round can't iterate both. Bring screenshots of the tied
   options; never pick for them. (Culling never ties — it's rule-driven.)
2. **Pinning the final champion once the goal holds** — personas advise,
   the owner decides. Present their split honestly if there is one.

**Stall escalation** (an escalation, not a routine block): if 2
consecutive rounds add zero net progress toward the goal — no new fresh
both-liked options and no PASSes flipped — stop building and escalate:
post the scoreboard, diagnose why convergence stalled (which objections
keep recurring, which directions are exhausted), and ask the owner
whether to loosen the goal, change direction, add a kill rule, or stop.
Never loop indefinitely against a bar the personas won't clear.

### 10. FINISH

Only after the owner pins the champion:

1. Promote it into the real component via the options skill's promote step
   (diff first, per the base skill).
2. Sweep any pattern-level fixes the champion implies elsewhere.
3. Delete ALL scaffolding (`/options/<target>/`, champs entry).
4. Sync e2e specs that assert on changed markup.
5. Run the full test suite.
6. Verify the promoted component in its REAL page context — not the
   options page — at desktop AND mobile, with the same screenshot tool
   used all loop.
7. **STOP** and show the owner the result. No push, no PR changes without
   the owner's say-so.

## Manifest extensions

On top of the base options schema — base fields unchanged (the one
semantic override is `icp` current-state, per REVIEW):

```jsonc
{
  // ...base fields (target, source, kind, prompt, constants, axes, next_id)...
  "goal": { "raw": "5 both-liked, 2 interactive",
            "interpretation": "stop when 5 non-killed options hold fresh LIKEs from both personas, at least 2 of those 5 interactive" },
  "personas": [ { "key": "A", "brief": "cautious non-technical buyer" },
                { "key": "B", "brief": "design-literate slop skeptic" } ],
  "round": 3,
  "owner_directions": [
    { "round": 2, "kind": "premise_correction", "text": "prices are placeholders — never style them as final" },
    { "round": 2, "kind": "kill_rule", "text": "kill everything both passed on" }
  ],
  "options": [{
    // base fields (id, file, status, note) unchanged; extensions:
    "parent": 4,                    // option this one forked from, null for de-novo
    "interactions": [               // declared by the variant's builder; omit for static variants
      { "el": "primary CTA", "trigger": "hover", "expect": "lifts 2px, shadow deepens, 180ms ease-out" },
      { "el": "tier cards", "trigger": "load", "expect": "one-shot stagger entrance, 400ms total" }
    ],
    "kill": { "round": 3, "why": "zero likes", "revive_if": "revive if the overlap bug is fixed" },
    "icp": [
      { "by": "A", "verdict": "LIKE", "champion": true, "round": 3, "note": "..." },
      { "by": "B", "verdict": "PASS", "round": 3, "note": "PASS — tighten the tier gap; that one change flips me." },
      { "by": "B", "verdict": "LIKE", "round": 2, "stale": true, "note": "pre-dates correction — liked the final-price styling" }
    ]
  }]
}
```

Chip rendering additions (extend the base chip component):

- Chip label includes the verdict: `A ★LIKE`, `B PASS`.
- ★ only on a persona's CURRENT champion.
- `stale: true` chips render muted, tooltip prefixed with the reason
  ("pre-dates correction", "raced build").

## Agent briefs

Every brief is self-contained — agents get no conversation history. A
brief may point at a file the lead wrote (that's still self-contained:
one Read, no history needed).

**Lead builder (once, at start):** target + source path, frozen copy,
constants/axes, manifest path and full extended schema, the shared-file
ownership rule ("you own manifest/grid/mocks/chips; per-variant builders
own only their one OptionN.tsx"), anti-slop + animation rules, and the
requirement to SendMessage a build report (files written, IDs, compile
status, page URLs) after every round.

**Per-variant builder (each variant, each round):** the path to a
ROUND-BRIEF file the lead writes once per round (frozen copy verbatim,
anti-slop + animation rules, the project's styling system, research
digest), plus the variant-specifics inline: the one file to write
(`OptionN.tsx`, exact path + ID), the prop contract (`sampleProps`
shape), and the specific direction or verbatim feedback item this
variant implements. Nothing else — no manifest, no shared files.
Deliverable: the file, plus — if the variant animates or responds to
interaction — an `interactions` list (element, trigger, expected
behavior, where the motion code lives; max 3 per option — needing more
means the design is too busy) for the lead to record in the manifest;
static variants return none.

**Researcher (round 1 + delta re-runs):** component type, project
context; re-runs also get the prior report, standing PASS reasons, and
open craft questions. Deliverable: a short report — patterns that work,
anti-slop patterns to avoid, 2–3 concrete ideas per open question.

**Persona reviewer (each round):** the base skill's Step 7.3 reviewer
inputs (persona brief, stay in character, opinionated, screenshots + the
manifest notes so it judges intent, not just pixels) plus this skill's
additions: live URLs, the strict LIKE bar, the one-flip-change rule for
every PASS, the review scope (new/stale-flagged options only + full-field
champion restatement), and — for options with declared `interactions` —
the keyframe strips + motion specs with the judge-the-motion requirement. Deliverable via SendMessage: per-option
`{verdict, note, flip_change?}` + current champion + a 2-sentence
synthesis.

**Targeted re-check:** persona brief, the specific option(s), their prior
verdict, and exactly what changed since it. Same LIKE bar.

## Operational rules

- **Acceptance = the shared lens.** Acceptance testing uses the SAME
  screenshot tool the reviewers and owner use (dev-server MCP when
  available, else claude-in-chrome). An agent's private test harness
  passing does not count as verification.
- **Reviews never race builds.** The build must be complete, integrated,
  and live before ANY review dispatches — initial round, targeted
  re-check, or owner spot-check.
- **Stale means doesn't count.** A verdict counts only while what it
  judged still holds. Any invalidation — a premise correction, a verdict
  that might have seen in-flight build state — flags the entry
  `stale: true` (muted chip, tooltip says why, excluded from goal counts)
  until a targeted re-check replaces it.
- **Animation discipline.** Every animation: one-shot, ends static,
  `prefers-reduced-motion` fallback; no looping ambient motion; hover
  affordances visible at rest. Never introduce: badges, ghost numerals,
  hype-cycle curves, ALL-CAPS letterspaced labels, boxed/bracketed active
  states, colored left-border callouts. Compliance is verified
  mechanically at capture time (the motion audit in BUILD), never
  delegated to personas — they judge taste, not compliance.
- **No invented facts,** prices, testimonials, or urgency in any variant.
- **Agents report or get replaced.** Every agent must SendMessage its
  deliverable to main — idling without reporting is failure. After one
  evidence-backed nudge goes unanswered for ~5 minutes, replace the agent
  with a FRESH one carrying a consolidated self-contained brief (for the
  lead builder, that brief must carry its cross-round memory — see
  Roles). Stale agents replay old queues; don't resuscitate them.
- **Commit after every round** (scaffold, chips, kills, owner directions)
  so the whole verdict history lives in git. Scaffolding never merges.

## What NOT to do (beyond the base skill's list)

- Don't edit files from the orchestrator context — everything goes through
  the lead builder.
- Don't mutate an existing option to apply feedback — fork to a new ID.
- Don't count stale LIKEs toward the goal.
- Don't dispatch a review while a build is in flight.
- Don't let personas pin the champion or break their own ties.
- Don't unfreeze copy to make a design work.
- Don't push, open, or modify PRs after FINISH without the owner's say-so.
