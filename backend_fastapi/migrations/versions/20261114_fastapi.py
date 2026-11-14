from pathlib import Path

from alembic import op
from sqlalchemy import text

from app.seed_locations import GOVERNORATES

revision = "20261114_fastapi"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Frozen SQL snapshot, not live ORM metadata. Existing Nest user/session rows remain intact.
    sql = (Path(__file__).parent / "20261114_schema.sql").read_text(encoding="utf-8")
    for statement in sql.split(";"):
        if statement.strip():
            op.execute(statement)
    connection = op.get_bind()
    for gid, ar, en, areas in GOVERNORATES:
        connection.execute(
            text("INSERT INTO governorates(id,name_ar,name_en) VALUES (:id,:ar,:en)"), {"id": gid, "ar": ar, "en": en}
        )
        for aid, aar, aen in areas:
            connection.execute(
                text("INSERT INTO areas(id,governorate_id,name_ar,name_en) VALUES (:id,:gid,:ar,:en)"),
                {"id": aid, "gid": gid, "ar": aar, "en": aen},
            )


def downgrade():
    raise RuntimeError(
        "Use an isolated backup restore to revert the backend migration; user data is never dropped automatically."
    )
