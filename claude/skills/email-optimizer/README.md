# Email Optimizer Skill

Expert system for writing marketing emails people actually open, read, and act on — distilled from the Pip Decks *Million Dollar Emails* methodology.

## Overview

This skill provides specialized expertise in email copywriting, subject lines, story-led emails, and diagnosing underperforming campaigns. It's triggered automatically when Claude detects email-related keywords in conversation.

## Automatic Triggers

The skill activates on terms like: email, subject line, preview text, newsletter, email copy, email marketing, open rate, click rate, cold email, email sequence, nurture sequence, broadcast, email CTA, unsubscribe, deliverability, email idea, email teardown.

## Core Methodology

**Give to Get.** You only buy from people you trust, and trust is built by giving before you ask. Be unreasonably generous; aim for ~3–4 value emails per sales ask.

**The three rules:** be useful, be interesting, be entertaining.

**The spine:** Give before you ask → Tell a story → Get it opened.

**The engine — build backwards:** the reader reads Story → Lesson → Ask; you build it Ask → Lesson → Story. Decide the ask first ("By the end of this email I want the reader to ___"), one email/one lesson/one ask, then find the story to land it.

**Get it opened:** subject line + preview text are one hook in two beats — the subject opens a loop, the preview deepens it. ~35 chars, curiosity or lesson-hint, no ALL CAPS / emoji / spam words / AI generators.

## Structure (progressive disclosure)

The core methodology lives in `SKILL.md`; the bulky swipe material is loaded on demand from `references/`:

```
email-optimizer/
├── SKILL.md                     # Core methodology + router
├── README.md                    # This file
└── references/
    ├── subject-lines.md         # 12 hook types + subject/preview pairing
    ├── idea-vault.md            # 50 prompts across 6 sources
    ├── diagnosis.md             # 4-symptom audit with benchmarks + fixes
    └── anatomy-examples.md      # 5 annotated real-email teardowns
```

## Capabilities

- Finished story-led emails built backwards
- Subject line + preview-text option sets by hook type
- Idea sprints (ask/lesson/story trios)
- Diagnoses of underperforming emails/campaigns with prioritized fixes
- Customer-testimonial interview scripts
- Before/after rewrites

## Example Prompts

- "Write a launch email for my new course"
- "Give me 5 subject lines for a re-engagement email"
- "My open rate dropped to 12% — what's wrong?"
- "I'm out of newsletter ideas, help me brainstorm"
- "Rewrite this email to be less salesy"

## Installation

Version-controlled in this repo under `claude/skills/email-optimizer/` and symlinked into `~/.claude/skills/` by `install.sh`.

## Related skills

- `landing-page-optimizer` and `about-page-optimizer` — sibling copy skills from the same Pip Decks "Million Dollar" family.

## License

Private skill — methodology adapted from Pip Decks *Million Dollar Emails* for personal use.
