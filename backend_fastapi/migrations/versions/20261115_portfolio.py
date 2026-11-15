from alembic import op

revision = "20261115_portfolio"
down_revision = "20261114_persona"
branch_labels = None
depends_on = None


def upgrade():
    for statement in [
        "ALTER TABLE properties ADD COLUMN availability varchar(12) NOT NULL DEFAULT 'active'",
        "ALTER TABLE properties ADD COLUMN closed_at timestamptz",
        "ALTER TABLE properties ADD COLUMN display_price numeric(14,2)",
        "UPDATE properties SET display_price=price",
        "ALTER TABLE properties ALTER COLUMN display_price SET NOT NULL",
        "ALTER TABLE properties ADD COLUMN platform_fee numeric(14,2) NOT NULL DEFAULT 0",
        "ALTER TABLE properties ADD COLUMN pricing_policy varchar(40) NOT NULL DEFAULT 'none'",
        "ALTER TABLE properties ADD CONSTRAINT property_availability_valid CHECK (availability IN ('active','paused','sold','rented'))",
        "ALTER TABLE properties ADD CONSTRAINT property_closure_valid CHECK ((availability IN ('sold','rented')) = (closed_at IS NOT NULL))",
        "ALTER TABLE properties ADD CONSTRAINT property_closure_category CHECK ((availability <> 'sold' OR category IN ('sale_cash','sale_installments')) AND (availability <> 'rented' OR category IN ('private_rental','shared_rental')))",
        "ALTER TABLE properties ADD CONSTRAINT property_public_price_valid CHECK (display_price >= price AND platform_fee >= 0)",
        "CREATE INDEX properties_owner_page_idx ON properties(owner_id,category,created_at DESC,id DESC)",
        "CREATE INDEX properties_owner_history_idx ON properties(owner_id,closed_at DESC,id DESC) WHERE closed_at IS NOT NULL",
        "ALTER TABLE property_favorites ADD COLUMN title_snapshot varchar(150)",
        "ALTER TABLE property_favorites ADD COLUMN category_snapshot varchar(32)",
        "ALTER TABLE property_favorites ADD COLUMN price_snapshot numeric(14,2)",
        "UPDATE property_favorites f SET title_snapshot=p.title,category_snapshot=p.category,price_snapshot=p.display_price FROM properties p WHERE p.id=f.property_id",
        "ALTER TABLE property_favorites ALTER COLUMN title_snapshot SET NOT NULL",
        "ALTER TABLE property_favorites ALTER COLUMN category_snapshot SET NOT NULL",
        "ALTER TABLE property_favorites ALTER COLUMN price_snapshot SET NOT NULL",
    ]:
        op.execute(statement)


def downgrade():
    raise RuntimeError("Restore an isolated backup; lifecycle and pricing history must be preserved.")
