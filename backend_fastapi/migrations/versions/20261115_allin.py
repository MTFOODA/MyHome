from alembic import op

revision = "20261115_allin"
down_revision = "20261115_deals"
branch_labels = None
depends_on = None


def upgrade():
    for statement in [
        "ALTER TABLE properties ADD COLUMN original_price numeric(14,2)",
        "UPDATE properties SET original_price=price",
        "ALTER TABLE properties ALTER COLUMN original_price SET NOT NULL",
        "ALTER TABLE properties ADD COLUMN buyer_fee numeric(14,2) NOT NULL DEFAULT 0",
        "ALTER TABLE properties ADD COLUMN seller_fee numeric(14,2) NOT NULL DEFAULT 0",
        "ALTER TABLE properties ADD COLUMN reference_months integer CHECK(reference_months>0)",
        "UPDATE properties SET reference_months=CASE rental_period WHEN 'one_year' THEN 12 WHEN 'three_years' THEN 36 WHEN 'five_years' THEN 60 WHEN 'custom' THEN custom_months END WHERE category IN ('private_rental','shared_rental')",
        "ALTER TABLE deals ADD COLUMN category varchar(32)",
        "UPDATE deals d SET category=p.category FROM properties p WHERE p.id=d.property_id",
        "ALTER TABLE deals ALTER COLUMN category SET NOT NULL",
        "ALTER TABLE deals ADD COLUMN rental_months integer CHECK(rental_months>0)",
        # Frozen user-approved defaults: sale 1%; private .5/.75/1 month; shared .25/.375/.5 month.
        "UPDATE properties SET platform_fee=round(original_price*.01,2),buyer_fee=round(round(original_price*.01,2)/2,2),seller_fee=round(original_price*.01,2)-round(round(original_price*.01,2)/2,2),pricing_policy='all-in-v1' WHERE category IN ('sale_cash','sale_installments')",
        """WITH fees AS (SELECT id,trunc(original_price * CASE WHEN category='shared_rental' THEN CASE WHEN reference_months<=12 THEN .25 WHEN reference_months<=36 THEN .375 ELSE .5 END ELSE CASE WHEN reference_months<=12 THEN .5 WHEN reference_months<=36 THEN .75 ELSE 1 END END * least(reference_months::numeric/12,1) /(2*reference_months),2)*reference_months AS share FROM properties WHERE category IN ('private_rental','shared_rental') AND reference_months IS NOT NULL) UPDATE properties p SET buyer_fee=f.share,seller_fee=f.share,platform_fee=2*f.share,pricing_policy='all-in-v1' FROM fees f WHERE p.id=f.id""",
        "UPDATE properties SET display_price=price+buyer_fee/COALESCE(reference_months,1) WHERE pricing_policy='all-in-v1'",
        "ALTER TABLE properties ADD CONSTRAINT property_fee_shares_valid CHECK(buyer_fee>=0 AND seller_fee>=0 AND buyer_fee+seller_fee=platform_fee)",
    ]:
        op.execute(statement)


def downgrade():
    raise RuntimeError("Preserve original prices, all-in references and financial history; use isolated restore.")
