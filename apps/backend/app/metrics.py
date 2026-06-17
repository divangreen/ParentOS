from datetime import date

from app.dates import day_bounds


def get_daily_metrics(supabase, child_id: str, day: date) -> dict:
    """Aggregates feedings, sleeps, and diapers for a child on a given UTC day."""
    start, end = day_bounds(day)

    feedings = (
        supabase.table("feedings")
        .select("*")
        .eq("child_id", child_id)
        .gte("logged_at", start)
        .lt("logged_at", end)
        .execute()
        .data
    )
    sleeps = (
        supabase.table("sleeps")
        .select("*")
        .eq("child_id", child_id)
        .gte("started_at", start)
        .lt("started_at", end)
        .execute()
        .data
    )
    diapers = (
        supabase.table("diapers")
        .select("*")
        .eq("child_id", child_id)
        .gte("logged_at", start)
        .lt("logged_at", end)
        .execute()
        .data
    )

    bottle_feeds = [f for f in feedings if f["volume_ml"] is not None]
    breast_feeds = [f for f in feedings if f["duration_minutes"] is not None]

    return {
        "feeding_count": len(feedings),
        "total_volume_ml": sum(f["volume_ml"] for f in bottle_feeds) if bottle_feeds else None,
        "total_breast_minutes": sum(f["duration_minutes"] for f in breast_feeds) if breast_feeds else None,
        "sleep_total_minutes": sum(s["duration_minutes"] for s in sleeps),
        "diaper_wet_count": sum(1 for d in diapers if d["type"] in ("wet", "both")),
        "diaper_dirty_count": sum(1 for d in diapers if d["type"] in ("dirty", "both")),
    }
