---
name: options
description: Visual iteration loop for front-end design. Scaffolds /options/<target> routes inside the user's web app, generates N variants of a component/page/section, runs a persona/ICP review round whose verdicts render as hoverable chips on the option pages, then a kill → champion → regen → promote loop driven by the user. Use when the user says "/options" (with or without args) or asks to "explore variations", "try a few directions", "give me options for", or otherwise wants to compare visual design alternatives for a UI piece side-by-side.
---

# Options: visual iteration for front-end design

A loop for exploring visual variants of a UI piece (component, page, or
section) at full fidelity inside the user's actual dev app, then promoting a
winner back to source.

## When to invoke

The user has typed `/options ...` or asked to explore visual variations.
You should NOT invoke this for: API design, copy variants, backend
alternatives, or any non-visual exploration.

## Lifecycle / commands

The skill is hybrid — slash subcommands drive primary actions, natural
language drives selection between them.

| Input | Action |
|---|---|
| `/options new <target> <N> "<prompt>"` | Discover, scaffold, generate N options |
| `/options review [target]` | Run the persona review round, fold verdicts back into the manifest/chips |
| `/options regen [N]` | Add N more (default 3), keeping survivors + champions |
| `/options promote [id]` | Replace source file with champion; ask to clean up |
| `/options clean [target]` | Delete `/options/<target>/` scaffolding |
| "kill 2 and 4" | Mark options 2 and 4 as killed |
| "champion 3" / "pin 3" | Mark option 3 as champion |
| "unkill 4" / "unchampion 3" | Revert to active |
| "regen but weirder / more conservative / focused on X" | Same as regen with steering |

**The standard workflow is: scaffold → persona review → verdicts rendered
back onto the option pages as chips → the user reviews with that feedback
visible and gives kills/champions in chat.** The persona review is not
optional garnish; run it after every scaffold and every regen (a targeted
addendum review for just the new variants is fine) unless the user says to
skip it. The personas advise; the user decides.

Always parse target/IDs leniently. "Kill the second and fourth ones" should
work the same as "kill 2 and 4".

## Step 1 — Framework detection

Detect the framework once per project, cache mentally for the session:

| Check | Framework | Routes go in |
|---|---|---|
| `next.config.*` exists AND `app/` dir exists | Next.js App Router | `app/options/<target>/` |
| `next.config.*` exists AND `pages/` dir exists | Next.js Pages Router | `pages/options/<target>/` |
| `vite.config.*` exists AND `src/main.tsx` imports a router | Vite + react-router | `src/options/<target>/` + register route |
| `astro.config.*` exists | Astro | `src/pages/options/<target>/` |
| Anything else | Ask the user where /options routes should live |

For Vite/react-router, you'll need to add a lazy route entry to wherever
routes are defined. For Next App Router everything is filesystem-based.

## Step 2 — Target resolution

Three target forms:

- **Bare name** (`hero`): grep with ripgrep for
  `rg -n "export (default )?(function|const) <Name>" src/ app/ components/`
  - 0 matches → treat as new section, confirm with user
  - 1 match → use it
  - 2+ matches → list paths, ask which
- **Explicit path** (`src/components/Hero.tsx`): skip grep, use as-is
- **Prefixed**:
  - `page:<name>` → page composition, no single source file
  - `section:<name>` → new freestanding section, no existing source

## Step 3 — Props detection (component targets only)

For an existing component, find realistic prop values:

```bash
rg -n "<<Name>[ />]" src/ app/ --type tsx --type jsx -A 10
```

Pick the call site with the richest set of props as the sample. Write those
into `mocks.ts` as `export const sampleProps = {...}`. If no usage exists,
read the component's prop interface and fabricate plausible values; mention
in chat what you fabricated.

## Step 4 — Conversational discovery

Before generating, ask 2–3 short questions in a single AskUserQuestion call:

1. **Vibe / references** — mood, examples, comparable sites
2. **Constants** — what should stay constant across options (copy,
   structure, content, brand)
3. **Variance** — how different from each other (subtle iterations vs wildly
   divergent directions)

Skip the questions and proceed with defaults only if the user explicitly
says "just go" or gives a very detailed prompt that answers all three.

## Step 5 — Scaffold

For Next.js App Router (analogous paths for other frameworks):

```
app/options/<target>/
  manifest.json
  mocks.ts             # sampleProps export
  Option1.tsx
  Option2.tsx
  ...
  OptionN.tsx
  page.tsx             # grid index
  [id]/page.tsx        # full-bleed detail
app/options/champs/
  page.tsx             # cross-target champions index (create once)
```

Each `OptionK.tsx` is a self-contained React component that renders ONE
variant of the target with the sample props. Variants should differ along
the axes from discovery. Champion files become the source of truth on
promote, so write them as if they were the real component (no debug
clutter), but it's OK to put the variant directly in JSX without extracting
sub-components.

## Step 6 — Report

After scaffolding, print:

```
✓ 5 options ready for hero
  http://localhost:3000/options/hero

  1. <one-line description of option 1>
  2. <one-line description of option 2>
  ...

  Reply with "kill 2 and 4, champion 3" or "/options regen" or "/options promote 3".
```

Do NOT screenshot *for the user* — they open the URL themselves. (The
persona review step below takes its own screenshots as reviewer input;
that's different.) Start the dev server only if one isn't already running
and the review step needs it.

## Step 7 — Persona review loop

After scaffolding (and after every regen), run a review round with
independent persona agents before asking the user to judge:

1. **Find the personas.** Look for persona/ICP docs in the project (e.g.
   `docs/icp-*.md`, `docs/personas/`). If none exist, ask the user which
   perspectives should review (e.g. "the buyer" and "a design-literate
   skeptic") and improvise the persona brief from their answer. Two
   personas with *opposing* failure modes work best — one who punishes
   burying the facts, one who punishes overselling.
2. **Capture reviewer input.** Build, then screenshot every variant's
   detail route full-page at ~1280px into the scratchpad. Screenshots keep
   each reviewer's context clean and guarantee both judge identical pixels.
3. **Spawn one background agent per persona** (all in one message so they
   run concurrently). Each agent: reads its persona doc, stays in
   character, reviews every variant from the screenshots + the manifest
   notes (so it judges the *intent*, not just pixels), and returns
   per-target CHAMPION / runner-up / KILLs with persona-voiced reasons plus
   a short cross-target synthesis. Instruct it to be opinionated — no
   fence-sitting — and to flag anything that distorts a factual claim.
4. **Fold verdicts into the manifest.** Every option gets an `icp` array
   (see schema below): `champion: true` for that persona's suggested
   champion, plain entries for every other piece of feedback (kills,
   runner-ups, caveats), with the reasoning as a 1–2 sentence
   persona-voiced quote.
5. **Render chips.** A shared chip component on both the grid and detail
   pages shows one chip per feedback entry next to the option's status:
   starred chip = suggested champion, plain chip = other feedback, distinct
   color per persona, and the reasoning in a tooltip on hover/focus
   (`tabindex="0"` so keyboard users get it too).
6. **Synthesize in chat.** Report agreements, conflicts, and a recommended
   champion per target — explicitly framed as input to the *user's*
   kill/champion call, never as a decision. Where two personas' champions
   vary independent axes, offer (or just cut) a merge variant — merges of
   compatible champions routinely beat both parents.
7. **Iterate.** When the user's feedback produces new/changed variants, run
   a targeted addendum review of just those variants and update the chips.

## Manifest schema

`app/options/<target>/manifest.json`:

```json
{
  "target": "hero",
  "source": "src/components/Hero.tsx",
  "kind": "component",
  "prompt": "dark editorial",
  "constants": ["copy", "headline"],
  "axes": ["typography", "layout", "color"],
  "next_id": 6,
  "options": [
    {"id": 1, "file": "Option1.tsx", "status": "killed", "note": "too busy", "icp": []},
    {"id": 2, "file": "Option2.tsx", "status": "champion", "pinned_at": "2026-06-05T10:00:00Z", "icp": [
      {"by": "A", "champion": true, "note": "The one I'd actually buy from — the credentials are legible instead of decorative."},
      {"by": "B", "note": "Runner-up — clean, but the footnote strip beats it on restraint."}
    ]},
    {"id": 3, "file": "Option3.tsx", "status": "active", "icp": [
      {"by": "B", "champion": true, "note": "The only one that reads like a person made a layout decision."}
    ]},
    {"id": 4, "file": "Option4.tsx", "status": "killed", "icp": []},
    {"id": 5, "file": "Option5.tsx", "status": "active", "icp": []}
  ]
}
```

Rules:

- IDs are stable. Survivors keep their IDs across regen.
- `kind`: `"component"`, `"page"`, or `"section"`.
- `source` is null for section/page kinds with no existing source.
- Status: `"active"`, `"champion"`, or `"killed"`.
- Killed files stay on disk (the grid page renders them faded). Only
  cleanup or promote removes them.
- `next_id` increments by 1 each time a new option is added (never reuses).
- `icp` holds persona-review feedback (normalize it to `[]` on every entry
  so the JSON type stays uniform). Each entry: `by` (short persona key,
  e.g. "A"/"B"), optional `champion: true` (that persona's suggested
  champion for the target — rendered as a starred chip), and `note` (the
  persona-voiced why, 1–2 sentences — rendered as the chip's tooltip).
  Keep entries current: a persona's superseded champion pick stays as a
  plain note ("my champion before #16 — ..."), so the history reads on the
  page.

## Kill / champion / regen

When the user says "kill 2 and 4, champion 3":

1. Read the manifest.
2. Update statuses. If a `note` is given ("kill 2 — too busy"), capture it.
3. Write manifest back.
4. Reply in chat with a one-line summary:
   ```
   ⌫ killed 2, 4  ☆ championed 3  survivors: 1, 3, 5
   ```
5. Tell the user the page will reflect changes on refresh.

On `/options regen [N]` (default N=3):

1. Read manifest.
2. Read champion files (positive reference) and killed files + their notes
   (negative reference).
3. Generate N new options:
   - Keep the same axes and constants
   - Push variance away from killed directions, toward champion direction
   - If the user added steering ("but weirder"), apply that on top
4. Append new options to manifest starting at `next_id`. Bump `next_id`.
5. Reply with the same report block as step 6 of new, listing only the new
   options.

## Promote

On `/options promote [id]` (id defaults to the single champion, or asks if
multiple):

1. Read the option file.
2. Adapt it back to the original source's shape:
   - Replace `import { sampleProps } from './mocks'` with the prop
     destructuring the real component used
   - Match the prop interface / TypeScript signature of the original
   - Strip any option-page wrapper divs (the original was probably
     prop-driven without an outer container)
3. Show the diff against the current source file (use Bash `diff -u
   src/components/Hero.tsx <(<adapted>)` or render the proposed file and ask
   for confirmation).
4. On confirm, overwrite the source file. For section/page kinds with no
   source, ask where the new component should live.
5. Update the cross-target champions index — remove this target.
6. Ask: "clean up app/options/hero/?" — if yes, delete the folder and the
   route.

## Cleanup

`/options clean <target>` (or `/options clean` for all):

1. Delete `app/options/<target>/`.
2. Remove from `app/options/champs/page.tsx`.
3. If `app/options/` has no remaining children, delete `app/options/champs/`
   and `app/options/` too.

## Page renderer templates

### Grid index — `app/options/<target>/page.tsx`

Use this template (adjust framework/import paths as needed):

```tsx
import manifest from "./manifest.json";
import Link from "next/link";

const modules: Record<string, () => Promise<{ default: React.ComponentType<any> }>> = {
  // Filled in at scaffold time, one line per option:
  // "Option1.tsx": () => import("./Option1"),
};

import { sampleProps } from "./mocks";

export default async function Page() {
  const champions = manifest.options.filter(o => o.status === "champion");
  const active = manifest.options.filter(o => o.status === "active");
  const killed = manifest.options.filter(o => o.status === "killed");
  const ordered = [...champions, ...active, ...killed];

  const loaded = await Promise.all(
    ordered.map(async (o) => {
      const mod = await modules[o.file]();
      return { ...o, Component: mod.default };
    })
  );

  return (
    <main style={{ padding: 24, background: "#0a0a0a", color: "#fff", minHeight: "100vh" }}>
      <header style={{ marginBottom: 24, display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
        <h1 style={{ fontSize: 18, fontWeight: 500 }}>
          {manifest.target} — {manifest.prompt}
        </h1>
        <span style={{ fontSize: 12, opacity: 0.6 }}>
          {champions.length} ☆ · {active.length} active · {killed.length} ⌫
        </span>
      </header>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(420px, 1fr))", gap: 16 }}>
        {loaded.map(({ id, status, note, Component }) => (
          <Link
            key={id}
            href={`/options/${manifest.target}/${id}`}
            style={{
              border: "1px solid #222",
              borderRadius: 8,
              overflow: "hidden",
              opacity: status === "killed" ? 0.35 : 1,
              filter: status === "killed" ? "grayscale(1)" : undefined,
              textDecoration: "none",
              color: "inherit",
              display: "block",
            }}
          >
            <div style={{ padding: "6px 10px", fontSize: 11, background: "#111", display: "flex", justifyContent: "space-between" }}>
              <span>
                {status === "champion" && "☆ "}
                {status === "killed" && "⌫ "}
                #{id}
              </span>
              {note && <span style={{ opacity: 0.6 }}>{note}</span>}
            </div>
            <div style={{ background: "#fff", color: "#000" }}>
              <Component {...sampleProps} />
            </div>
          </Link>
        ))}
      </div>
    </main>
  );
}
```

Fill the `modules` object with one entry per option file at scaffold time;
update it on each regen.

Give the grid header two filter toggles — "hide killed" and "champions
only" — implemented as buttons with `aria-pressed` that toggle
data-attributes on `<body>` (CSS does the hiding via the blocks' status
classes). Persist the state in localStorage under one key so the filter
carries across every target's grid page.

### Detail route — `app/options/<target>/[id]/page.tsx`

```tsx
import manifest from "../manifest.json";
import { sampleProps } from "../mocks";
import { notFound } from "next/navigation";

export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const opt = manifest.options.find(o => String(o.id) === id);
  if (!opt) notFound();
  const mod = await import(`../${opt.file.replace(".tsx", "")}`);
  const Component = mod.default;
  return <Component {...sampleProps} />;
}
```

### ICP chips — shared component used by grid + detail pages

One small shared component renders the `icp` feedback next to each option's
status bar. Framework-agnostic spec (adapt to the project):

- One chip per `icp` entry, labeled `ICP <by>`; a distinct muted color per
  persona; `champion: true` chips get a leading ★ (gold) and a subtle ring.
- The `note` renders in a tooltip positioned above the chip, visible on
  `:hover` and `:focus-visible`; give the chip `tabindex="0"` and an
  `aria-label` containing the full note so it works without a pointer.
- Monospace, pill-shaped, small (~0.7rem) — it belongs to the scaffolding
  chrome, not the design under review, so keep it visually distinct from
  the variant's own styling.
- `prefers-reduced-motion`: no tooltip transition.

### Champions index — `app/options/champs/page.tsx`

Iterate the filesystem under `app/options/`, read each `manifest.json`, and
render a list of champions per target with links to their detail routes.
Regenerate this whole file each time a champion changes (it's small).

## Style notes

- Each `OptionK.tsx` must accept the same prop shape as `sampleProps`. The
  simplest form is `export default function Option1(props: any) { return ... }`.
- The grid page intentionally uses inline styles + dark chrome so it can't
  conflict with any global CSS the project ships.
- The option files themselves should use the project's actual styling
  system (Tailwind, CSS modules, etc.) so they look the way they will when
  promoted.

## Concurrency / champs index

Multiple targets coexist freely. Each lives in its own folder under
`app/options/`. The `/options/champs` route is the cross-target dashboard —
update it whenever a champion is added, removed, or a target is cleaned up.

## What NOT to do

- Don't screenshot for the user or narrate what variants look like — they
  open the URL. (Persona reviewers DO get screenshots; that's their input.)
- Don't let personas decide. Their verdicts are chips and a synthesis; the
  kill/champion call is always the user's.
- Don't ship a review round where every persona has the same failure mode —
  pick reviewers who disagree for different reasons.
- Don't add interactive on-page buttons for kill/champion — the chat skill
  is the control surface; the page is a viewer.
- Don't put any logic in `OptionK.tsx` that wouldn't survive promotion (no
  console.logs, no debug overlays, no test ids that won't apply in prod).
- Don't reuse IDs after a kill. Always increment `next_id`.
- Don't delete killed option files — they're history. They go away only on
  cleanup or promote.
- Don't promote without showing a diff first.
- Don't generate options without asking the discovery questions, unless the
  user explicitly says "just go".
