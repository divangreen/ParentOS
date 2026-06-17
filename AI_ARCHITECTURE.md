# AI Architecture — ParentOS

Budget constraint: < SGD 100/month across all active users.

---

## Architecture

```
Nightly cron (Railway Cron Job)
  └── for each child with events today:
        1. Fetch daily metrics from PostgreSQL
        2. Render prompt template with metrics
        3. Call AI provider (OpenAI → Ollama fallback)
        4. Store result in ai_insights table
        5. Trigger Firebase push notification
```

On-demand path (parent taps "Generate"):
```
POST /insights/generate
  └── same steps 1–4, skip step 5
```

---

## Provider Strategy

Primary: OpenAI `gpt-4o-mini`
- Cost: ~$0.00015 per 1K input tokens, ~$0.0006 per 1K output tokens
- Estimated per-summary cost: ~$0.002 (≈ SGD 0.003)
- Break-even at SGD 100: ~33,000 summaries/month

Fallback: Ollama + Llama 3.2 (self-hosted on Railway)
- Cost: compute only (Railway free tier)
- Trigger: if OpenAI returns 429 or 503

Switch logic: environment variable `AI_PROVIDER=openai|ollama`

---

## Daily Summary Prompt

```
System:
You are a helpful parenting assistant. Summarise a baby's day for tired parents.
Be warm, concise, and reassuring. Flag genuine concerns clearly but calmly.
Output plain text only. Max 150 words.

User:
Baby: {name}, age {age_days} days

Today's data ({date}):
- Feedings: {feeding_count} feeds
  - Breast: {breast_feed_count} sessions, {total_breast_minutes} min total
  - Bottle: {bottle_feed_count} bottles, {total_volume_ml} ml total
- Sleep: {sleep_session_count} sessions, {sleep_total_minutes} min ({sleep_total_hours}h) total
  - Naps: {nap_count} | Night: {night_sleep_count}
- Diapers: {wet_count} wet, {dirty_count} dirty

Age-appropriate averages for {age_days}-day-old:
- Feeds: 8–12/day
- Sleep: 14–17h/day
- Wet diapers: 6+/day

Identify any anomalies. Give 1–2 short recommendations.
```

---

## Data Inputs

Metrics fetched per child for summary date (midnight to midnight, user's local timezone):

```sql
SELECT
  COUNT(*) FILTER (WHERE type = 'breast') AS breast_feed_count,
  COUNT(*) FILTER (WHERE type = 'bottle') AS bottle_feed_count,
  SUM(duration_minutes) FILTER (WHERE type = 'breast') AS total_breast_minutes,
  SUM(volume_ml) FILTER (WHERE type = 'bottle') AS total_volume_ml,
  COUNT(*) AS feeding_count
FROM feedings WHERE child_id = $1 AND logged_at::date = $2;

SELECT
  COUNT(*) AS sleep_session_count,
  SUM(duration_minutes) AS sleep_total_minutes,
  COUNT(*) FILTER (WHERE type = 'nap') AS nap_count,
  COUNT(*) FILTER (WHERE type = 'night') AS night_sleep_count
FROM sleeps WHERE child_id = $1 AND started_at::date = $2;

SELECT
  COUNT(*) FILTER (WHERE type IN ('wet','both')) AS wet_count,
  COUNT(*) FILTER (WHERE type IN ('dirty','both')) AS dirty_count
FROM diapers WHERE child_id = $1 AND logged_at::date = $2;
```

---

## Cost Estimate

| Users | Summaries/month | Est. OpenAI cost | SGD |
|-------|----------------|------------------|-----|
| 10 | 310 | $0.62 | ~$0.84 |
| 100 | 3,100 | $6.20 | ~$8.40 |
| 500 | 15,500 | $31.00 | ~$42.00 |
| 1,000 | 31,000 | $62.00 | ~$84.00 |

Budget alarm: PostHog + Railway env var alert at SGD 80/month. Auto-switch to Ollama at SGD 95.

---

## Anomaly Detection (Rule-based, no extra AI cost)

Applied before calling AI — injected into prompt as flags:

- Feeding gap > 4h during daytime → "Long gap between feeds detected"
- Total feeds < 6 → "Fewer feeds than typical today"
- Wet diapers < 4 → "Low wet diaper count — monitor hydration"
- Total sleep < 10h → "Less sleep than average today"

These rules run in Python before the AI call. They ensure the AI has structured signal, not just raw numbers.

---

## Guardrails

- AI output max 150 words (enforced via `max_tokens=200` parameter)
- System prompt prohibits medical diagnoses
- System prompt instructs to recommend pediatric consultation for any safety concern
- SECURITY_AGENT reviews prompts before production deployment
- Token count stored per summary for cost auditing
