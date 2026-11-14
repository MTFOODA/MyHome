from alembic import op

revision = "20261114_housing"
down_revision = "20261114_fastapi"
branch_labels = None
depends_on = None


def upgrade():
    statements = [
        """CREATE TABLE housing_applications (
            id uuid PRIMARY KEY, property_id uuid NOT NULL REFERENCES properties(id),
            user_id uuid NOT NULL REFERENCES users(id), status varchar(20) NOT NULL DEFAULT 'pending',
            created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
            UNIQUE(property_id,user_id), CHECK(status IN ('pending','accepted','rejected'))
        )""",
        "CREATE INDEX applications_property_idx ON housing_applications(property_id)",
        "CREATE INDEX applications_user_idx ON housing_applications(user_id)",
        """CREATE TABLE audit_events (
            id uuid PRIMARY KEY, actor_id uuid NOT NULL REFERENCES users(id), action varchar(40) NOT NULL,
            target_id uuid NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
        )""",
        "CREATE INDEX audit_events_actor_idx ON audit_events(actor_id)",
        "ALTER TABLE properties ADD CONSTRAINT properties_category_check CHECK (category IN ('sale_cash','sale_installments','private_rental','shared_rental'))",
        "ALTER TABLE properties ADD CONSTRAINT properties_finishing_check CHECK (finishing IN ('red_brick','plastered','lux','super_lux'))",
        "ALTER TABLE properties ADD CONSTRAINT properties_beds_check CHECK (category <> 'shared_rental' OR (total_beds IS NOT NULL AND available_beds IS NOT NULL AND available_beds >= 0 AND available_beds <= total_beds AND total_beds <= capacity))",
        "ALTER TABLE properties ADD CONSTRAINT properties_installments_check CHECK (category <> 'sale_installments' OR (down_payment IS NOT NULL AND installment_count IS NOT NULL AND installment_amount IS NOT NULL AND installment_count > 0 AND installment_amount > 0 AND down_payment + installment_count * installment_amount = price))",
        "ALTER TABLE user_intents ADD CONSTRAINT user_intents_allowed CHECK (intent IN ('owner_sale_cash','owner_sale_installments','owner_private_rental','owner_shared_rental','buyer_cash','buyer_installments','tenant_private','tenant_shared'))",
    ]
    for statement in statements:
        op.execute(statement)


def downgrade():
    raise RuntimeError("Restore an isolated backup instead of automatically dropping application data.")
