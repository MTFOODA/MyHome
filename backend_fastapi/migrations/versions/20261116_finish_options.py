"""Extend the existing finishing constraint without rewriting owner data."""

import sqlalchemy as sa
from alembic import op

revision = "20261116_finish_options"
down_revision = "20261116_optional_features"
branch_labels = None
depends_on = None


def upgrade():
    for check in sa.inspect(op.get_bind()).get_check_constraints("properties"):
        if "finishing" in check["sqltext"] and "furnished" not in check["sqltext"]:
            op.drop_constraint(check["name"], "properties", type_="check")
    op.create_check_constraint(
        "property_finishing_valid",
        "properties",
        "finishing IN ('red_brick','plastered','lux','super_lux','ultra_super_lux')",
    )


def downgrade():
    raise RuntimeError("Restore an isolated backup; do not silently remap ultra finishing values.")
