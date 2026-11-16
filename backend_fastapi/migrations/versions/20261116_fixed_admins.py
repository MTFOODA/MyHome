"""Add reserved operator login names without modifying historical users."""

import sqlalchemy as sa
from alembic import op

revision = "20261116_fixed_admins"
down_revision = "20261116_finish_options"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("users", sa.Column("username", sa.String(32), nullable=True))
    op.create_unique_constraint("users_username_key", "users", ["username"])


def downgrade():
    raise RuntimeError("Restore an isolated backup; operator login identities must not be discarded.")
