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
- Verdicts are strict LIKE/PASS (see REVIEW) instead of free-form.
- Manifest gains the extension fields below (all additive).
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

Parse the goal into a predicate stored in the manifest, e.g.
`{"raw": "5 both-liked, 2 interactive", "liked_by_all": 5, "interactive_min": 2}`.
"Both-liked" / "liked-by-all" = every persona's CURRENT verdict on that
option is a fresh (non-stale) LIKE. A persona's CURRENT verdict on an
option is their highest-round entry for it. `interactive_min` counts
WITHIN the qualifying set: at least that many of the options counting
toward `liked_by_all` must be `interactive: true` — interactive options
nobody liked don't satisfy it. If the wording doesn't parse cleanly,
restate your interpretation to the owner and get a yes before round 1.
Check the predicate after every review round; only fresh LIKEs on
non-killed options count.

## Roles

- **Orchestrator (you, the main context)** — never edits project or
  scaffold files (scratchpad screenshots and git commits are yours; design
  and manifest edits are not). You run all owner-facing conversation
  (discovery questions, escalations, scoreboards), route feedback, verify
  agent claims with your own greps and screenshots, and commit after every
  round. If you catch yourself about to edit a project file, stop and send
  it to the lead builder instead.
- **Lead builder (ONE persistent named agent for the whole loop)** — owns
  ALL shared-file edits: scaffolding, `manifest.json`, the grid's modules
  map, `mocks.ts`, the chip component, kill/status flips, chip updates. It
  carries cross-round memory: what died and why, what each persona wants,
  which directions are exhausted. Spawn it once with the Agent tool
  (`name: "lead-builder"`), continue it across rounds via SendMessage.
- **Per-variant builders (short-lived, fanned out each round)** — one per
  variant, 4–6 per round, each writes exactly ONE new self-contained
  `OptionN.tsx` from a self-contained brief. Conflict-free by construction:
  variant files are independent; only the lead touches shared files. Fan
  out with the Workflow tool's `pipeline()` when available; otherwise the
  lead builds the variants itself serially under the same contract.
  The lead assigns IDs up front from `next_id`, integrates each finished
  variant (module registration + manifest entry), and confirms the build
  compiles and every page renders before reporting the round built.
- **Researcher (fresh agent per round)** — background research on best
  practices and anti-slop patterns for this component type.
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
Then have the lead builder scaffold with the answers baked into its brief:
manifest, mocks, grid, `[id]` detail pages, chip component, `noindex` on
every `/options/*` route (Next.js App Router: an `app/options/layout.tsx`
exporting `metadata = { robots: { index: false, follow: false } }`; other
frameworks: the equivalent robots meta per page). Record `goal`,
`personas`, and `round: 0` in the manifest. Commit.

### 2. RESEARCH

Dispatch the researcher: best practices + anti-slop patterns for this
specific component type (pricing table, hero, etc.), with concrete
do/don't examples. Its report shapes round 1's variant briefs. Re-run the
researcher between rounds, feeding in the reviewers' standing objections
and any open craft questions ("how do the good ones handle a 4th tier?").

### 3. BUILD

The lead builder plans the round's variant set (4–6), assigns IDs, writes
the per-variant briefs, fans out the per-variant builders, integrates, and
verifies compile + rendered pages. Then YOU verify independently — grep
that the files/registrations exist, screenshot the grid — before any
review dispatches. An agent saying "done" is a claim, not a fact.

### 4. REVIEW

One agent per persona, all dispatched in one message. Each judges the LIVE
pages AND full-page screenshots (~1280px, taken by you into the
scratchpad) of every non-killed variant, against a strict bar:

- **LIKE** = "I'd be happy to ship this exactly as-is."
- Everything else = **PASS** + the single highest-leverage change that
  would flip it to LIKE. One change, not a list.

Each round every persona also RESTATES their current champion across all
living options — the ★ migrates to wherever they now point; their previous
champion entry is demoted to a plain note (per the base skill's history
rule).

The lead builder folds verdicts into the manifest as chips using the base
`{by, champion?, note}` shape plus the extension fields, so the grid shows
hover-note chips and a ★ on each persona's current champion.

**One current entry per persona per option.** A fresh verdict REPLACES
that persona's previous non-stale entry on the same option — no
accumulating LIKE+PASS chip pairs across rounds. Two kinds of history do
persist: entries marked `stale` by a premise correction (muted, until a
re-review replaces them), and a superseded champion pick — the old
option's entry loses its ★ in place and its note records the supersession
(per the base skill's history rule); same single entry, never a second
one.

### 5. CULL

After each review round:

- **AUTO-KILL** every option with zero LIKEs.
- Apply any standing **owner kill rules** immediately ("kill everything
  both passed on", "kill anything violating <premise>") — they stay in
  force for future rounds until revoked.
- Every kill writes a manifest `kill` note preserving WHY it died and what
  would revive it (e.g. "one bug from LIKE — revive if the overlap bug is
  fixed"). Kills are status flags, never file deletions — anything is
  revivable.

### 6. ITERATE

Next round evolves survivors:

- Apply each reviewer's flip-change **VERBATIM** — build exactly the change
  they asked for, not your interpretation of its spirit.
- **Convergence rule**: when reviewers independently describe the same
  ideal, build exactly that as its own variant.
- ALL feedback — owner's or a persona's — applied to an existing variant
  produces a **NEW numbered option**. Never mutate: the parent stays for
  A/B comparison and dies by the kill rules if superseded.

Feed the new round's briefs (with the fresh research) to the lead builder;
loop back to step 3.

### 7. OWNER CHANNEL

The owner can interject at any time with direction, screenshots, or
premise corrections. Handle:

- **Direction / kill rules** → apply immediately (steps 5–6).
- **Premise correction** → record in the manifest's `owner_directions`
  with `"kind": "premise_correction"`. It overrides all persona verdicts.
  Mark every verdict that predates it `stale: true`; its chip renders
  muted with "pre-dates correction". Stale LIKEs don't count toward the
  goal — affected options need re-review.
- **Screenshot feedback** → diagnose first (what exactly is the owner
  reacting to — spacing? contrast? a specific element?), state your
  diagnosis, then translate it into a builder brief. Don't build from a
  raw vibe.

### 8. RE-REVIEW

When a judged variant's successor or a fix lands, dispatch a TARGETED
re-check to the relevant persona(s) describing exactly what changed since
their verdict — not a full re-review of everything.

**Timing rule**: the build must be complete, integrated, and live BEFORE
any review dispatches — never let a reviewer race an in-flight build. If a
timing collision happens anyway, invalidate every verdict that could have
seen the in-flight state — at minimum the affected option, the whole
batch if the app itself was broken or half-integrated during the review —
and re-check; never trust a verdict that might have seen stale pixels.

### 9. CADENCE

Fully autonomous between owner inputs. After each review round, commit and
post a compact scoreboard — informational, not blocking:

```
Round 3 — goal: 5 both-liked (have 2), ≥2 of them interactive (have 1)
| # | A | B | status |
|---|---|---|--------|
| 3 | ★LIKE | LIKE | both-liked |
| 7 | LIKE | PASS: tighten tier gap | 1 like |
| 8 | PASS: too dense | ★LIKE | 1 like |
| 5 | — | — | ⌫ r2: zero likes; revive if simplified |
Next: building 9 (from 7 + B's change), 10 (from 8 + A's change), 11 (convergence: both want quiet emphasis on middle tier)
```

Two routine things block on the owner (the stall escalation below is a
separate, exceptional case):

1. **Persona tie-breaks** — when the verdicts leave two or more options
   indistinguishable for a decision you must make (a cull call, or
   personas' champion restatements split with no dominant pick). Bring
   screenshots of the tied options; never pick for them.
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

All additive on top of the base options schema — base fields unchanged:

```jsonc
{
  // ...base fields (target, source, kind, prompt, constants, axes, next_id)...
  "goal": { "raw": "5 both-liked, 2 interactive", "liked_by_all": 5, "interactive_min": 2 },
  "personas": [ { "key": "A", "brief": "cautious non-technical buyer" },
                { "key": "B", "brief": "design-literate slop skeptic" } ],
  "round": 3,
  "owner_directions": [
    { "round": 2, "kind": "premise_correction", "text": "prices are placeholders — never style them as final" },
    { "round": 2, "kind": "kill_rule", "text": "kill everything both passed on" }
  ],
  "options": [{
    // base fields (id, file, status, note) unchanged; extensions:
    "born_round": 2,
    "parent": 4,                    // option this one forked from, null for de-novo
    "interactive": true,           // counts toward interactive_min
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
- ★ only on a persona's CURRENT champion; superseded champion entries
  become plain notes.
- `stale: true` chips render muted, tooltip prefixed "pre-dates
  correction".

## Agent briefs

Keep every brief self-contained — agents get no conversation history.

**Lead builder (once, at start):** target + source path, frozen copy,
constants/axes, manifest path and full extended schema, the shared-file
ownership rule ("you own manifest/grid/mocks/chips; per-variant builders
own only their one OptionN.tsx"), anti-slop + animation rules, and the
requirement to SendMessage a build report (files written, IDs, compile
status, page URLs) after every round.

**Per-variant builder (each variant, each round):** the one file to write
(`OptionN.tsx`, exact path + ID), the prop contract (`sampleProps` shape),
frozen copy verbatim, the specific direction or verbatim feedback item this
variant implements, relevant research findings, anti-slop + animation
rules, the project's styling system. Nothing else — no manifest, no shared
files.

**Researcher (each round):** component type, project context, and (round
≥2) the standing PASS reasons and open craft questions. Deliverable: a
short report — patterns that work, anti-slop patterns to avoid, 2–3
concrete ideas per open question.

**Persona reviewer (each round):** the persona brief (stay in character),
screenshot paths + live URLs for every living variant, the manifest notes
(judge intent, not just pixels), the strict LIKE bar, the one-flip-change
rule for every PASS, and the champion-restatement requirement. Deliverable
via SendMessage: per-option `{verdict, note, flip_change?}` + current
champion + a 2-sentence synthesis.

**Targeted re-check:** persona brief, the specific option(s), their prior
verdict, and exactly what changed since it. Same LIKE bar.

## Operational rules

- **Acceptance = the shared lens.** Acceptance testing uses the SAME
  screenshot tool the reviewers and owner use (dev-server MCP when
  available, else claude-in-chrome). An agent's private test harness
  passing does not count as verification.
- **Animation discipline.** Every animation: one-shot, ends static,
  `prefers-reduced-motion` fallback; no looping ambient motion; hover
  affordances visible at rest. Never introduce: badges, ghost numerals,
  hype-cycle curves, ALL-CAPS letterspaced labels, boxed/bracketed active
  states, colored left-border callouts.
- **No invented facts,** prices, testimonials, or urgency in any variant.
- **Agents report or get replaced.** Every agent must SendMessage its
  deliverable to main — idling without reporting is failure. After one
  evidence-backed nudge goes unanswered for ~5 minutes, replace the agent
  with a FRESH one carrying a consolidated self-contained brief (for the
  lead builder, that brief must carry its cross-round memory: what died
  and why, each persona's wants, exhausted directions). Stale agents
  replay old queues; don't resuscitate them.
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
