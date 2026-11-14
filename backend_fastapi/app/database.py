from functools import lru_cache

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session

from app.config import settings


class Base(DeclarativeBase):
    pass


@lru_cache
def engine():
    url = settings().database_url.replace("postgresql://", "postgresql+psycopg://", 1)
    return create_engine(url, pool_pre_ping=True, pool_size=10, max_overflow=5, connect_args={"connect_timeout": 5})


def db_session():
    with Session(engine(), expire_on_commit=False) as session:
        yield session
