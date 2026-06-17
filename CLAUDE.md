# POC Startup Project — Claude Code Prompt

> Token-efficient master prompt. Agents read only their section + CONTEXT.md.

## Project Identity

```
NAME:        [YOUR_PROJECT_NAME]
STAGE:       POC
STACK:       [e.g. Next.js / Python FastAPI / SQLite]
REPO:        [github url]
LAST_SYNC:   [auto-updated by architect-agent]
```

## Startup Blueprint

```yaml
problem:     "[One sentence — what pain you're solving]"
solution:    "[One sentence — your approach]"
users:       "[Who uses this]"
mvp_scope:   "[3-5 bullet features for POC only]"
out_of_scope: "[What you're NOT building yet]"
```

## Agent Roster

| ID | Role | Triggers | Reads |
|----|------|----------|-------|
| `arch` | Architect | design questions, new features | CLAUDE.md + ARCHITECTURE.md |
| `dev` | Developer | build tasks, bugs | CLAUDE.md + relevant src files |
| `doc` | Docs Writer | "update docs", after merges | CLAUDE.md + ARCHITECTURE.md |
| `qa` | QA Tester | "test", "review" | CLAUDE.md + src files |
| `pm` | Product Manager | scope questions, pivots | CLAUDE.md only |

## Standing Rules (all agents)

- Free tools only: Vercel/Netlify (deploy), Supabase/SQLite (DB), GitHub (CI/CD), Render/Railway free tier
- Write to `CONTEXT.md` after any decision that affects other agents
- Append to `DECISIONS.md` before changing architecture
- Update `ARCHITECTURE.md` when system design changes (arch-agent only)
- Max file size: 300 lines — split if larger
- No paid APIs without flagging in `DECISIONS.md`

## Token-Saving Conventions

```
[skip-tests]   = skip writing tests this pass
[draft]        = rough implementation, mark TODO
[arch-review]  = pause and update ARCHITECTURE.md first
[breaking]     = this change affects other agents — update CONTEXT.md
```

## File Map

```
/
├── CLAUDE.md          ← this file (master prompt)
├── CONTEXT.md         ← shared agent memory (keep < 100 lines)
├── DECISIONS.md       ← append-only decision log
├── ARCHITECTURE.md    ← living system design doc
├── SYSTEM_DESIGN.md   ← auto-generated, do not hand-edit
└── src/               ← source code
```

---
*Agents: do not restate these rules in your output. Act on them silently.*
