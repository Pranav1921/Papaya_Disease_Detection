import math
import random


severity_map = {
    "powdery_mildew": 76.4,
    "ringspot_virus": 88.5,
    "leaf_curl": 65.0,
    "healthy": 0.0,
    "background": 0.0,
}


def calculate_haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def shops_within_radius(shops, lat: float, lng: float, radius_km: float):
    filtered = []
    for shop in shops:
        distance = calculate_haversine(lat, lng, shop["lat"], shop["lng"])
        if distance <= radius_km:
            shop_item = dict(shop)
            shop_item["distance_km"] = round(distance, 2)
            filtered.append(shop_item)
    filtered.sort(key=lambda item: item["distance_km"])
    return filtered


def severity_for(disease_key: str) -> float:
    base_severity = severity_map[disease_key]
    return round(base_severity + random.uniform(-4, 4), 1) if disease_key not in ("healthy", "background") else 0.0


def status_for(severity: float) -> str:
    if severity > 80:
        return "Critical"
    if severity > 50:
        return "Severe"
    if severity > 10:
        return "Moderate"
    return "Healthy"
