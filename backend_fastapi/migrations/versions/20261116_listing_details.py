"""Add listing facts and the complete pinned source catalogue; retain existing IDs/data."""

import json
from pathlib import Path

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import insert

revision = "20261116_listing_details"
down_revision = "20261115_communications"
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    op.execute("SET LOCAL lock_timeout = '5s'")
    op.add_column("properties", sa.Column("area_measurement", sa.String(10), nullable=True))
    op.add_column("properties", sa.Column("location_url", sa.String(2048), nullable=True))
    op.add_column("properties", sa.Column("furnished", sa.Boolean(), nullable=True))
    # Replace the old combined constraint by name discovered from the live schema.
    for constraint in sa.inspect(bind).get_check_constraints("properties"):
        if all(part in constraint["sqltext"] for part in ("area_m2", "bedrooms", "capacity")):
            op.drop_constraint(constraint["name"], "properties", type_="check")
    op.alter_column("properties", "capacity", existing_type=sa.Integer(), nullable=True)
    op.create_check_constraint(
        "property_dimensions_valid",
        "properties",
        "area_m2 > 0 AND price > 0 AND bedrooms >= 0 AND bathrooms > 0 AND (capacity IS NULL OR capacity > 0)",
    )
    op.create_check_constraint(
        "shared_capacity_required", "properties", "category <> 'shared_rental' OR capacity IS NOT NULL"
    )
    op.create_check_constraint(
        "area_measurement_valid", "properties", "area_measurement IS NULL OR area_measurement IN ('net','gross')"
    )
    op.create_check_constraint(
        "furnished_applicable", "properties", "furnished IS NULL OR finishing IN ('lux','super_lux')"
    )
    # Legacy non-shared capacity values remain stored; they are no longer shown or required.
    rows = json.loads(
        (Path(__file__).resolve().parents[2] / "app/data/egypt-areas-20260908.json").read_text(encoding="utf-8")
    )
    areas = sa.table(
        "areas",
        sa.column("id", sa.String),
        sa.column("governorate_id", sa.String),
        sa.column("name_ar", sa.String),
        sa.column("name_en", sa.String),
    )
    for offset in range(0, len(rows), 500):
        bind.execute(insert(areas).values(rows[offset : offset + 500]).on_conflict_do_nothing(index_elements=["id"]))


def downgrade():
    raise RuntimeError("Restore an isolated backup; never automatically discard listing or catalogue data.")
