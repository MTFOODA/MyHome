from fastapi import APIRouter, Depends
from pydantic import Field, field_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import db_session
from app.map_links import coordinates_from_url, validate_map_url
from app.models import Area, Governorate
from app.schemas import StrictModel
from app.security import authenticated

router = APIRouter(tags=["locations"])


@router.get("/locations/map-config")
def map_config():
    from app.config import settings

    config = settings()
    return dict(
        tile_url=config.map_tile_url, attribution=config.map_attribution, attribution_url=config.map_attribution_url
    )


class MapLink(StrictModel):
    url: str = Field(max_length=2048)

    @field_validator("url")
    @classmethod
    def valid_url(cls, value):
        return validate_map_url(value)


@router.post("/locations/parse-link")
def parse_link(body: MapLink, context=Depends(authenticated)):
    # Parse locally. No geocoding, remote fetches, billing, or SSRF destinations.
    from fastapi import HTTPException

    try:
        coordinates = coordinates_from_url(body.url)
    except ValueError as error:
        raise HTTPException(400, str(error)) from None
    return {"url": body.url, "coordinates": coordinates, "needs_map_selection": coordinates is None}


@router.get("/locations")
def locations(db: Session = Depends(db_session)):
    return {
        "governorates": [
            dict(id=g.id, name_ar=g.name_ar, name_en=g.name_en)
            for g in db.scalars(select(Governorate).order_by(Governorate.name_en))
        ],
        "areas": [
            dict(id=a.id, governorate_id=a.governorate_id, name_ar=a.name_ar, name_en=a.name_en)
            for a in db.scalars(select(Area).order_by(Area.name_en))
        ],
    }
