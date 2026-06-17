# ARCHITECTURE.md — Living System Design

> Maintained by `arch` agent. Updated after every structural change.
> Last updated: [DATE] by arch-agent

---

## System Overview

```
[Replace with 1-paragraph description once defined]
```

## Component Diagram

```
[ascii or mermaid diagram goes here — arch agent updates this]

Example:
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│   Frontend  │────▶│   API Layer │────▶│   Database   │
│  (Next.js)  │     │  (FastAPI)  │     │  (Supabase)  │
└─────────────┘     └─────────────┘     └──────────────┘
```

## Data Models

```yaml
# arch agent fills this in
# Example:
# User:
#   id: uuid
#   email: string
#   created_at: timestamp
```

## API Surface

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| — | — | — | To be defined |

## Infrastructure

| Concern | Tool | Free Tier Limit |
|---------|------|-----------------|
| Frontend deploy | Vercel | 100GB bandwidth/mo |
| Backend deploy | Render | 750hrs/mo |
| Database | Supabase | 500MB, 2 projects |
| CI/CD | GitHub Actions | 2000 min/mo |
| Auth | Supabase Auth | 50k MAU |
| File storage | Supabase Storage | 1GB |

## Open Questions

<!-- arch agent lists unresolved design questions here -->

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 0.1 | [DATE] | Initial scaffold |
