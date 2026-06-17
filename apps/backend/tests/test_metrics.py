from datetime import date
from unittest.mock import MagicMock

from app.metrics import get_daily_metrics


def test_get_daily_metrics_aggregates_correctly():
    sb = MagicMock()

    feedings = [
        {"volume_ml": 90, "duration_minutes": None},
        {"volume_ml": 60, "duration_minutes": None},
        {"volume_ml": None, "duration_minutes": 15},
    ]
    sleeps = [{"duration_minutes": 45}, {"duration_minutes": 120}]
    diapers = [{"type": "wet"}, {"type": "dirty"}, {"type": "both"}]

    def table_side_effect(name):
        m = MagicMock()
        if name == "feedings":
            m.select.return_value.eq.return_value.gte.return_value.lt.return_value.execute.return_value = MagicMock(
                data=feedings
            )
        elif name == "sleeps":
            m.select.return_value.eq.return_value.gte.return_value.lt.return_value.execute.return_value = MagicMock(
                data=sleeps
            )
        elif name == "diapers":
            m.select.return_value.eq.return_value.gte.return_value.lt.return_value.execute.return_value = MagicMock(
                data=diapers
            )
        return m

    sb.table.side_effect = table_side_effect

    metrics = get_daily_metrics(sb, "child-1", date.today())

    assert metrics["feeding_count"] == 3
    assert metrics["total_volume_ml"] == 150
    assert metrics["total_breast_minutes"] == 15
    assert metrics["sleep_total_minutes"] == 165
    assert metrics["diaper_wet_count"] == 2
    assert metrics["diaper_dirty_count"] == 2


def test_get_daily_metrics_no_data():
    sb = MagicMock()
    sb.table.return_value.select.return_value.eq.return_value.gte.return_value.lt.return_value.execute.return_value = MagicMock(
        data=[]
    )

    metrics = get_daily_metrics(sb, "child-1", date.today())

    assert metrics["feeding_count"] == 0
    assert metrics["total_volume_ml"] is None
    assert metrics["total_breast_minutes"] is None
    assert metrics["sleep_total_minutes"] == 0
    assert metrics["diaper_wet_count"] == 0
    assert metrics["diaper_dirty_count"] == 0
