# About Page Optimizer Skill

Expert system for writing an About page that converts — distilled from the Pip Decks *Million Dollar About Page* methodology. A sibling to the `landing-page-optimizer` skill.

## Overview

Turns an About page from a résumé or company-history dump into a conversion tool that builds know-like-trust. Triggered automatically when Claude detects About-page-related keywords.

## Automatic Triggers

The skill activates on terms like: about page, about us, our story, founder story, founder bio, personal brand, know like trust, brand story, meet the team, my story.

## Core Methodology

**The reframe:** the About page is a conversion powerhouse, and it must be about the *customer*, not just you. Goal = connection, not comprehensiveness.

**The Story Mirror Framework (8 sections):** Human connection → Problem recognition → Transformation moment → Journey to solution → Guide positioning → Proof of impact → Human dimension → Call to action. The customer is the hero; you're the guide ("You're not Luke Skywalker, you're Yoda").

**The 5-pass trust checklist:** strip self-promotion → authenticity → tighten (~500 words) → readability → connection (the cocktail-party test).

## Structure

```
about-page-optimizer/
├── SKILL.md    # Story Mirror framework + trust checklist + anti-patterns
└── README.md   # This file
```

Single-file skill — the methodology is compact enough to keep in one place.

## Capabilities

- Full About page in the 8-section Story Mirror sequence
- Rewrite of an existing About page (failure mode named)
- Section-by-section audit against the framework
- A trust-checklist edit pass on a user's draft

## Example Prompts

- "Help me write my About page"
- "My About page is just a list of my credentials — fix it"
- "Audit the About page copy on my site"
- "Rewrite this founder bio so it connects with customers"

## Installation

Version-controlled in this repo under `claude/skills/about-page-optimizer/` and symlinked into `~/.claude/skills/` by `install.sh`.

## Related skills

- `landing-page-optimizer` — page-copy sibling for landing pages.
- `email-optimizer` — same storytelling principles applied to email.

## License

Private skill — methodology adapted from Pip Decks *Million Dollar About Page* for personal use.
