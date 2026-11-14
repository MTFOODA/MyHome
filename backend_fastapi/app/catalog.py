from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import db_session
from app.models import Area, Governorate

router = APIRouter(tags=["locations"])


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
