# CONTEXT.md — Shared Agent Memory

> All agents read this before acting. Keep under 100 lines.
> Format: `[AGENT] [DATE] — note`

## Current State

```yaml
phase:        "setup"          # setup | building | testing | deployed
last_change:  ""
active_agent: ""
blockers:     []
```

## Active Decisions

<!-- Agents: add 1-line summaries here. Full rationale in DECISIONS.md -->

## Component Ownership

| Component | Owner Agent | Status |
|-----------|-------------|--------|
| Database schema | arch | pending |
| API routes | dev | pending |
| Frontend | dev | pending |
| Docs | doc | pending |
| Tests | qa | pending |

## Inter-Agent Handoff Queue

<!-- Format: [FROM → TO] task description -->
