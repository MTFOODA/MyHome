"""Add structured addresses, distinct visitors and independent property conversations."""

import sqlalchemy as sa
from alembic import op

revision = "20261116_address_engagement"
down_revision = "20261116_listing_details"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("SET LOCAL lock_timeout = '5s'")
    op.alter_column("properties", "approximate_location", existing_type=sa.String(250), type_=sa.String(500))
    for name, kind in [
        ("street_address", sa.String(160)),
        ("building_number", sa.String(20)),
        ("floor_number", sa.Integer()),
        ("unit_number", sa.String(20)),
        ("property_kind", sa.String(16)),
    ]:
        op.add_column("properties", sa.Column(name, kind, nullable=True))
    op.create_check_constraint(
        "property_floor_valid", "properties", "floor_number IS NULL OR floor_number BETWEEN -5 AND 100"
    )
    op.create_check_constraint(
        "property_address_complete",
        "properties",
        "num_nonnulls(street_address,building_number,floor_number,unit_number) IN (0,4)",
    )
    op.create_check_constraint(
        "property_kind_valid",
        "properties",
        "property_kind IS NULL OR property_kind IN ('apartment','studio','duplex','villa','room')",
    )
    op.create_table(
        "property_visits",
        sa.Column("property_id", sa.Uuid(), sa.ForeignKey("properties.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("property_visits_user_idx", "property_visits", ["user_id"])
    op.create_index(
        "properties_owner_created_page_idx", "properties", ["owner_id", sa.text("created_at DESC"), sa.text("id DESC")]
    )
    op.add_column("conversations", sa.Column("property_id", sa.Uuid(), sa.ForeignKey("properties.id")))
    op.add_column("conversations", sa.Column("seeker_id", sa.Uuid(), sa.ForeignKey("users.id")))
    # The existing XOR check only allows deal/group. Replace by an exact one-target check.
    for c in sa.inspect(op.get_bind()).get_check_constraints("conversations"):
        if "deal_id" in c["sqltext"] and "group_id" in c["sqltext"]:
            op.drop_constraint(c["name"], "conversations", type_="check")
    op.create_check_constraint(
        "conversation_target_valid",
        "conversations",
        "num_nonnulls(deal_id,group_id,property_id)=1 AND ((property_id IS NOT NULL)=(seeker_id IS NOT NULL))",
    )
    op.create_unique_constraint("uq_property_inquiry", "conversations", ["property_id", "seeker_id"])
    op.create_index("conversations_seeker_idx", "conversations", ["seeker_id"])
    op.execute(
        "DO $$ BEGIN IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='myhome') THEN GRANT SELECT,INSERT,UPDATE,DELETE ON property_visits TO myhome; END IF; END $$"
    )


def downgrade():
    raise RuntimeError("Restore an isolated backup; do not discard address, visitor or conversation data.")
