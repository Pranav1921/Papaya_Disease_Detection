from recommend import TREATMENT_DATABASE, get_recommendation


FALLBACK_KEYS = {
    "status",
    "severity",
    "description",
    "chemical_treatment",
    "organic_treatment",
    "fertilizer",
    "prevention",
    "safety_interval",
    "market_price",
    "where_to_buy",
}


def test_get_recommendation_exact_key():
    assert get_recommendation("healthy") is TREATMENT_DATABASE["healthy"]


def test_get_recommendation_matches_substrings_and_normalizes_input():
    assert get_recommendation("papaya_ringspot_virus") is TREATMENT_DATABASE[
        "ringspot_virus"
    ]
    assert get_recommendation("  Healthy ") is TREATMENT_DATABASE["healthy"]


def test_get_recommendation_unknown_class_contains_raw_class_in_status():
    raw_class = "mystery_disease"
    recommendation = get_recommendation(raw_class)
    assert raw_class in recommendation["status"]
    assert set(recommendation) == FALLBACK_KEYS


def test_every_treatment_entry_has_fallback_key_set():
    assert all(set(entry) == FALLBACK_KEYS for entry in TREATMENT_DATABASE.values())
