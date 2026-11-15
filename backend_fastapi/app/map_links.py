"""User supplied map links only; never accept arbitrary URLs as HTTP destinations."""

import re
from urllib.parse import parse_qs, unquote, urlparse


def validate_map_url(value):
    value = value.strip()
    url = urlparse(value)
    if url.scheme != "https" or url.username or url.password or url.port:
        raise ValueError("INVALID_MAP_LINK")
    allowed = url.hostname in (
        "www.openstreetmap.org",
        "openstreetmap.org",
        "osm.org",
        "maps.app.goo.gl",
        "maps.google.com",
    )
    allowed |= url.hostname in ("www.google.com", "google.com", "goo.gl") and url.path.startswith("/maps")
    if not allowed:
        raise ValueError("INVALID_MAP_LINK")
    return value


def coordinates_from_url(value):
    url = urlparse(validate_map_url(value))
    query = parse_qs(url.query)
    pairs = [query.get(k, [""])[0] for k in ("mlat", "query", "q", "ll")]
    if "mlat" in query and "mlon" in query:
        pairs.insert(0, query["mlat"][0] + "," + query["mlon"][0])
    text = unquote(value)
    match = re.search(r"!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)", text)
    if match:
        pairs.insert(0, ",".join(match.groups()))
    match = re.search(r"#map=\d+/(-?\d+(?:\.\d+)?)/(-?\d+(?:\.\d+)?)", text)
    if match:
        pairs.append(",".join(match.groups()))
    for pair in pairs:
        match = re.fullmatch(r"\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*", pair)
        if match:
            lat, lon = map(float, match.groups())
            if 22 <= lat <= 32 and 24 <= lon <= 37:
                return dict(latitude=f"{lat:.7f}", longitude=f"{lon:.7f}")
            raise ValueError("LOCATION_OUTSIDE_EGYPT")
    return None
