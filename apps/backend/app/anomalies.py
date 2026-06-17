from typing import Literal, TypedDict


class Anomaly(TypedDict):
    code: str
    severity: Literal["warning", "critical"]
    message: str


def detect_anomalies(metrics: dict) -> list[Anomaly]:
    """Rule-based newborn care anomaly checks, run before/alongside AI summarization."""
    anomalies: list[Anomaly] = []

    if metrics["feeding_count"] == 0:
        anomalies.append(
            {"code": "no_feedings", "severity": "critical", "message": "No feedings logged today."}
        )
    elif metrics["feeding_count"] < 6:
        anomalies.append(
            {
                "code": "low_feeding_count",
                "severity": "warning",
                "message": (
                    f"Only {metrics['feeding_count']} feedings logged today "
                    "(newborns typically feed 8-12 times/day)."
                ),
            }
        )

    if metrics["diaper_wet_count"] == 0:
        anomalies.append(
            {
                "code": "no_wet_diapers",
                "severity": "critical",
                "message": "No wet diapers logged today — possible dehydration risk.",
            }
        )
    elif metrics["diaper_wet_count"] < 4:
        anomalies.append(
            {
                "code": "low_wet_diaper_count",
                "severity": "warning",
                "message": f"Only {metrics['diaper_wet_count']} wet diapers logged today (expected 6+ after day 5).",
            }
        )

    if metrics["sleep_total_minutes"] < 480:
        anomalies.append(
            {
                "code": "low_sleep_total",
                "severity": "warning",
                "message": (
                    f"Only {metrics['sleep_total_minutes']} minutes of sleep logged today "
                    "(newborns typically sleep 14-17 hours/day)."
                ),
            }
        )

    return anomalies
