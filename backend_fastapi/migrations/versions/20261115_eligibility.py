from alembic import op

revision = "20261115_eligibility"
down_revision = "20261115_allin"
branch_labels = None
depends_on = None


def upgrade():
    for sql in [
        "ALTER TABLE properties ADD COLUMN legal_eligibility varchar(20) NOT NULL DEFAULT 'pending' CHECK(legal_eligibility IN ('pending','eligible','ineligible'))",
        "ALTER TABLE properties ADD COLUMN eligibility_reviewer_id uuid REFERENCES users(id)",
        "CREATE INDEX properties_eligibility_reviewer_idx ON properties(eligibility_reviewer_id)",
        "ALTER TABLE properties ADD COLUMN eligibility_note varchar(2000)",
        "UPDATE properties SET pricing_policy='eligibility-pending',platform_fee=0,buyer_fee=0,seller_fee=0,display_price=price,reference_months=12 WHERE rental_period='old_rent'",
        "ALTER TABLE deals ADD COLUMN rental_period varchar(20)",
        "UPDATE deals d SET rental_period=p.rental_period FROM properties p WHERE p.id=d.property_id",
        "ALTER TABLE deals ADD COLUMN asking_price numeric(14,2)",
        "UPDATE deals SET asking_price=base_price",
        "ALTER TABLE deals ALTER COLUMN asking_price SET NOT NULL",
        "ALTER TABLE deals ADD COLUMN bed_reserved boolean NOT NULL DEFAULT false",
        "DROP INDEX one_accepted_property_deal",
        "CREATE UNIQUE INDEX one_accepted_property_deal ON deals(property_id) WHERE stage IN ('accepted','completed') AND category<>'shared_rental'",
    ]:
        op.execute(sql)


def downgrade():
    raise RuntimeError("Preserve legal eligibility and financial reference evidence.")
