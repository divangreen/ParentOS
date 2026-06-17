from datetime import date, datetime, timedelta, timezone


def utc_today() -> date:
    return datetime.now(timezone.utc).date()


def day_bounds(day: date) -> tuple[str, str]:
    start = datetime.combine(day, datetime.min.time(), tzinfo=timezone.utc)
    end = start + timedelta(days=1)
    return start.isoformat(), end.isoformat()
