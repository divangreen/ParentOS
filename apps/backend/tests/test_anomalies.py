from app.anomalies import detect_anomalies


def _metrics(**overrides) -> dict:
    base = {
        "feeding_count": 8,
        "total_volume_ml": 400,
        "total_breast_minutes": None,
        "sleep_total_minutes": 900,
        "diaper_wet_count": 6,
        "diaper_dirty_count": 3,
    }
    base.update(overrides)
    return base


def test_healthy_day_has_no_anomalies():
    assert detect_anomalies(_metrics()) == []


def test_no_feedings_is_critical():
    anomalies = detect_anomalies(_metrics(feeding_count=0))
    codes = [a["code"] for a in anomalies]
    assert "no_feedings" in codes
    assert next(a for a in anomalies if a["code"] == "no_feedings")["severity"] == "critical"


def test_low_feeding_count_is_warning():
    anomalies = detect_anomalies(_metrics(feeding_count=3))
    codes = [a["code"] for a in anomalies]
    assert "low_feeding_count" in codes
    assert "no_feedings" not in codes


def test_no_wet_diapers_is_critical():
    anomalies = detect_anomalies(_metrics(diaper_wet_count=0))
    assert any(a["code"] == "no_wet_diapers" and a["severity"] == "critical" for a in anomalies)


def test_low_wet_diaper_count_is_warning():
    anomalies = detect_anomalies(_metrics(diaper_wet_count=2))
    assert any(a["code"] == "low_wet_diaper_count" and a["severity"] == "warning" for a in anomalies)


def test_low_sleep_is_warning():
    anomalies = detect_anomalies(_metrics(sleep_total_minutes=300))
    assert any(a["code"] == "low_sleep_total" and a["severity"] == "warning" for a in anomalies)


def test_multiple_anomalies_combine():
    anomalies = detect_anomalies(
        _metrics(feeding_count=0, diaper_wet_count=0, sleep_total_minutes=200)
    )
    codes = {a["code"] for a in anomalies}
    assert codes == {"no_feedings", "no_wet_diapers", "low_sleep_total"}
