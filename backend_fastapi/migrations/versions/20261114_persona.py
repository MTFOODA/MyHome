from alembic import op

revision = "20261114_persona"
down_revision = "20261114_housing"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        "ALTER TABLE users ADD COLUMN housing_persona varchar(20) NOT NULL DEFAULT 'regular' CHECK (housing_persona IN ('regular','student','expatriate'))"
    )
    op.execute("UPDATE users SET housing_persona = role WHERE role IN ('student','expatriate')")


def downgrade():
    raise RuntimeError("Restore an isolated backup; do not discard user roles automatically.")
