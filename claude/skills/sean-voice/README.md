# Sean Voice Skill

Sean Robb's core writing voice — the shared, medium-agnostic layer applied to any prose published in his name. Originated as the `workhoodie-voice` skill in the workhoodie.com repo, generalized here for use across all projects.

## Overview

Keeps AI-drafted or AI-edited writing sounding like Sean instead of like a model. Covers voice principles, anti-patterns, a catalog of AI voice tells with before/after examples, and a specificity rule. Medium-specific style guides (blog long-form, LinkedIn social) live in their own project docs and build on top of this.

## Automatic Triggers

The skill activates on terms like: my voice, voice check, de-AI, AI tells, sound like me, write this as me, blog post, linkedin post, personal site copy.

## Core Principles

- **Conversational fragments** — written the way it'd be said out loud
- **Self-questioning** — show the thinking as it happened, don't just narrate outcomes
- **Connective tissue** — sentences breathe into each other; no false staccato rhythm
- **Quieter confidence** — declarative statements over rallying cries
- **Causal anchoring** — structural claims anchored in something concrete and checkable
- **Specificity** — the precise term over the impressive-sounding one

Plus a catalog of AI tells to strip: stock transitions, setup-and-flip pivots, editorial signposts, punchy triplets, decade forecasts, parallel negation, mic-drop closers, and more.

## Structure

```
sean-voice/
├── SKILL.md    # Voice principles + anti-patterns + AI tells catalog
└── README.md   # This file
```

Single-file skill — the voice guide is compact enough to keep in one place.

## Example Prompts

- "Write this LinkedIn post in my voice"
- "De-AI this draft"
- "Does this blog post sound like me?"
- "Edit this email so it doesn't read as generated"

## Installation

Provided by the `personal-setup` plugin (`claude/` is the plugin root). Install with `/plugin marketplace add SeanRobb/personal-setup` then `/plugin install personal-setup@sean-tools`.

## Related skills

- `email-optimizer` — email structure and strategy; this skill governs how the words sound.
- `about-page-optimizer` — About page framework; same relationship.
