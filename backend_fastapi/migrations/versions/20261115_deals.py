from alembic import op

revision = "20261115_deals"
down_revision = "20261115_portfolio"
branch_labels = None
depends_on = None


def upgrade():
    statements = [
        """CREATE TABLE staff_members(user_id uuid PRIMARY KEY REFERENCES users(id),specialty varchar(24) NOT NULL CHECK(specialty IN ('field_agent','document_reviewer')),active boolean NOT NULL DEFAULT true,professional_reference varchar(150),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now())""",
        """CREATE TABLE brokerage_terms(id uuid PRIMARY KEY,version varchar(60) NOT NULL UNIQUE,body_ar text NOT NULL,body_en text NOT NULL,due_condition varchar(2000) NOT NULL,legal_reference varchar(250) NOT NULL,created_by uuid NOT NULL REFERENCES users(id),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now())""",
        """CREATE TABLE payment_destinations(id uuid PRIMARY KEY,qr_asset_id uuid NOT NULL REFERENCES assets(id),recipient_name varchar(150) NOT NULL,created_by uuid NOT NULL REFERENCES users(id),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now())""",
        """CREATE TABLE deals(id uuid PRIMARY KEY,property_id uuid NOT NULL REFERENCES properties(id),buyer_id uuid NOT NULL REFERENCES users(id),seller_id uuid NOT NULL REFERENCES users(id),property_title varchar(150) NOT NULL,base_price numeric(14,2) NOT NULL CHECK(base_price>0),fee_total numeric(14,2) NOT NULL CHECK(fee_total>=0),buyer_fee numeric(14,2) NOT NULL,seller_fee numeric(14,2) NOT NULL,stage varchar(20) NOT NULL DEFAULT 'open' CHECK(stage IN ('open','accepted','completed','cancelled')),terms_id uuid REFERENCES brokerage_terms(id),reviewer_id uuid REFERENCES users(id),review_status varchar(20) NOT NULL DEFAULT 'pending' CHECK(review_status IN ('pending','approved','rejected')),contract_reference varchar(250),review_note varchar(2000),destination_id uuid REFERENCES payment_destinations(id),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),CHECK(buyer_id<>seller_id),CHECK(buyer_fee>=0 AND seller_fee>=0 AND buyer_fee+seller_fee=fee_total))""",
        "CREATE UNIQUE INDEX one_open_buyer_deal ON deals(property_id,buyer_id) WHERE stage IN ('open','accepted')",
        "CREATE UNIQUE INDEX one_accepted_property_deal ON deals(property_id) WHERE stage IN ('accepted','completed')",
        """CREATE TABLE deal_viewings(id uuid PRIMARY KEY,deal_id uuid NOT NULL REFERENCES deals(id),reference varchar(40) NOT NULL UNIQUE,scheduled_at timestamptz NOT NULL,staff_id uuid REFERENCES users(id),owner_confirmed boolean NOT NULL DEFAULT false,status varchar(20) NOT NULL DEFAULT 'requested' CHECK(status IN ('requested','confirmed','completed','cancelled')),completion_note varchar(1000),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now())""",
        "CREATE UNIQUE INDEX staff_viewing_slot ON deal_viewings(staff_id,scheduled_at) WHERE staff_id IS NOT NULL AND status IN ('confirmed','completed')",
        """CREATE TABLE deal_offers(id uuid PRIMARY KEY,deal_id uuid NOT NULL REFERENCES deals(id),created_by uuid NOT NULL REFERENCES users(id),amount numeric(14,2) NOT NULL CHECK(amount>0),status varchar(20) NOT NULL DEFAULT 'open' CHECK(status IN ('open','accepted','rejected','superseded')),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now())""",
        "CREATE UNIQUE INDEX one_open_deal_offer ON deal_offers(deal_id) WHERE status='open'",
        "CREATE UNIQUE INDEX one_accepted_deal_offer ON deal_offers(deal_id) WHERE status='accepted'",
        """CREATE TABLE deal_consents(deal_id uuid NOT NULL REFERENCES deals(id),user_id uuid NOT NULL REFERENCES users(id),digest varchar(64) NOT NULL,evidence_digest varchar(64) NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(deal_id,user_id))""",
        """CREATE TABLE fee_invoices(id uuid PRIMARY KEY,deal_id uuid NOT NULL REFERENCES deals(id),payer_id uuid NOT NULL REFERENCES users(id),amount numeric(14,2) NOT NULL CHECK(amount>=0),status varchar(20) NOT NULL DEFAULT 'unpaid' CHECK(status IN ('unpaid','reported','verified','rejected')),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),UNIQUE(deal_id,payer_id))""",
        """CREATE TABLE payment_claims(id uuid PRIMARY KEY,invoice_id uuid NOT NULL REFERENCES fee_invoices(id),reference varchar(100) NOT NULL UNIQUE,status varchar(20) NOT NULL DEFAULT 'reported' CHECK(status IN ('reported','verified','rejected')),verifier_id uuid REFERENCES users(id),verification_note varchar(2000),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now())""",
        "CREATE UNIQUE INDEX one_reported_invoice_claim ON payment_claims(invoice_id) WHERE status='reported'",
    ]
    for statement in statements:
        op.execute(statement)
    for table, columns in {
        "brokerage_terms": ["created_by"],
        "payment_destinations": ["qr_asset_id", "created_by"],
        "deals": ["property_id", "buyer_id", "seller_id", "terms_id", "reviewer_id", "destination_id"],
        "deal_viewings": ["deal_id", "staff_id"],
        "deal_offers": ["deal_id", "created_by"],
        "deal_consents": ["user_id"],
        "fee_invoices": ["deal_id", "payer_id"],
        "payment_claims": ["invoice_id", "verifier_id"],
    }.items():
        for column in columns:
            op.execute(f"CREATE INDEX {table}_{column}_idx ON {table}({column})")


def downgrade():
    raise RuntimeError("Restore an isolated backup; preserve consent, contract and payment evidence.")
