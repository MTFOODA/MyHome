from app.models import Area, Governorate


def full_address(db, prop, *, arabic=True):
    if not prop.street_address:
        return prop.approximate_location
    area = db.get(Area, prop.area_id)
    governorate = db.get(Governorate, area.governorate_id)
    place = [area.name_ar, governorate.name_ar] if arabic else [area.name_en, governorate.name_en]
    floor = (
        ("الدور الأرضي" if prop.floor_number == 0 else f"الدور {prop.floor_number}")
        if arabic
        else f"Floor {prop.floor_number}"
    )
    unit = f"شقة رقم {prop.unit_number}" if arabic else f"Apartment {prop.unit_number}"
    return "، ".join([f"{prop.building_number} {prop.street_address}", *place, floor, unit])
