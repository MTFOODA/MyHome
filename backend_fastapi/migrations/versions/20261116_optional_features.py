"""Optional owner-declared features, preserving unknown legacy values."""

import sqlalchemy as sa
from alembic import op

revision = "20261116_optional_features"
down_revision = "20261116_address_engagement"
branch_labels = None
depends_on = None


def upgrade():
    for name in ("compound", "security", "internet", "garage"):
        op.add_column("properties", sa.Column(name, sa.Boolean(), nullable=True))
    op.add_column("properties", sa.Column("orientation", sa.String(16), nullable=True))
    op.add_column("properties", sa.Column("kitchen_type", sa.String(20), nullable=True))
    # The previous expression check was unnamed; PostgreSQL assigned its name.
    bind = op.get_bind()
    for check in sa.inspect(bind).get_check_constraints("properties"):
        if "furnished IS NULL" in check["sqltext"]:
            op.drop_constraint(check["name"], "properties", type_="check")
    op.create_check_constraint(
        "property_furnishing_valid",
        "properties",
        "furnished IS NULL OR finishing IN ('lux','super_lux','ultra_super_lux')",
    )
    op.create_check_constraint(
        "property_orientation_valid",
        "properties",
        "orientation IS NULL OR orientation IN ('north','south','east','west','north_south')",
    )
    op.create_check_constraint(
        "property_kitchen_valid",
        "properties",
        "kitchen_type IS NULL OR kitchen_type IN ('closed_kitchen','american_kitchen')",
    )


def downgrade():
    raise RuntimeError("Restore an isolated backup to downgrade; do not discard owner-declared features.")
