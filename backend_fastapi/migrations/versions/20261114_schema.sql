
CREATE TABLE IF NOT EXISTS users (
	id UUID NOT NULL,
	name VARCHAR(100) NOT NULL,
	email VARCHAR(254) NOT NULL,
	password_hash VARCHAR NOT NULL,
	role VARCHAR(30) NOT NULL,
	owner_verified BOOLEAN NOT NULL,
	active BOOLEAN NOT NULL,
	onboarding_complete BOOLEAN NOT NULL,
	active_intent VARCHAR(32),
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	PRIMARY KEY (id),
	UNIQUE (email)
)

;

CREATE TABLE IF NOT EXISTS auth_sessions (
	id UUID NOT NULL,
	user_id UUID NOT NULL,
	refresh_hash VARCHAR(64) NOT NULL,
	expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
	revoked_at TIMESTAMP WITH TIME ZONE,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
)

;
CREATE INDEX IF NOT EXISTS ix_auth_sessions_expires_at ON auth_sessions (expires_at);
CREATE INDEX IF NOT EXISTS ix_auth_sessions_user_id ON auth_sessions (user_id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_complete boolean NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS active_intent varchar(32);

CREATE TABLE governorates (
 id VARCHAR(32) NOT NULL,
	name_ar VARCHAR(80) NOT NULL,
	name_en VARCHAR(80) NOT NULL,
	PRIMARY KEY (id)
)

;

CREATE TABLE areas (
	id VARCHAR(40) NOT NULL,
	governorate_id VARCHAR(32) NOT NULL,
	name_ar VARCHAR(100) NOT NULL,
	name_en VARCHAR(100) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(governorate_id) REFERENCES governorates (id)
)

;
CREATE INDEX ix_areas_governorate_id ON areas (governorate_id);

CREATE TABLE user_intents (
	user_id UUID NOT NULL,
	intent VARCHAR(32) NOT NULL,
	PRIMARY KEY (user_id, intent),
	FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
)

;

CREATE TABLE properties (
	id UUID NOT NULL,
	owner_id UUID NOT NULL,
	title VARCHAR(150) NOT NULL,
	description TEXT NOT NULL,
	category VARCHAR(32) NOT NULL,
	area_id VARCHAR(40) NOT NULL,
	approximate_location VARCHAR(250) NOT NULL,
	latitude NUMERIC(10, 7),
	longitude NUMERIC(10, 7),
	area_m2 NUMERIC(10, 2) NOT NULL,
	bedrooms INTEGER NOT NULL,
	bathrooms INTEGER NOT NULL,
	capacity INTEGER NOT NULL,
	water BOOLEAN NOT NULL,
	electricity BOOLEAN NOT NULL,
	gas BOOLEAN NOT NULL,
	elevator BOOLEAN NOT NULL,
	finishing VARCHAR(25) NOT NULL,
	price NUMERIC(14, 2) NOT NULL,
	negotiable BOOLEAN NOT NULL,
	rental_period VARCHAR(20),
	custom_months INTEGER,
	deposit NUMERIC(14, 2),
	down_payment NUMERIC(14, 2),
	installment_count INTEGER,
	installment_amount NUMERIC(14, 2),
	total_beds INTEGER,
	available_beds INTEGER,
	status VARCHAR(20) NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	PRIMARY KEY (id),
	CHECK (area_m2 > 0 AND price > 0 AND bedrooms >= 0 AND bathrooms > 0 AND capacity > 0),
	CHECK (status IN ('draft','pending','approved','rejected')),
	FOREIGN KEY(owner_id) REFERENCES users (id),
	FOREIGN KEY(area_id) REFERENCES areas (id)
)

;
CREATE INDEX ix_properties_owner_id ON properties (owner_id);
CREATE INDEX properties_discovery_idx ON properties (status, area_id, category, price);
CREATE INDEX ix_properties_area_id ON properties (area_id);

CREATE TABLE assets (
	id UUID NOT NULL,
	owner_id UUID NOT NULL,
	property_id UUID,
	kind VARCHAR(20) NOT NULL,
	storage_name VARCHAR(80) NOT NULL,
	position INTEGER,
	national_id_cipher BYTEA,
	dob DATE,
	ocr_status VARCHAR(20),
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	PRIMARY KEY (id),
	CONSTRAINT asset_photo_position_unique UNIQUE (property_id, position),
	FOREIGN KEY(owner_id) REFERENCES users (id),
	FOREIGN KEY(property_id) REFERENCES properties (id),
	UNIQUE (storage_name)
)

;
CREATE INDEX ix_assets_owner_id ON assets (owner_id);
CREATE INDEX ix_assets_property_id ON assets (property_id);

CREATE TABLE housing_groups (
	id UUID NOT NULL,
	property_id UUID NOT NULL,
	owner_id UUID NOT NULL,
	tenant_admin_id UUID NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	PRIMARY KEY (id),
	UNIQUE (property_id),
	FOREIGN KEY(property_id) REFERENCES properties (id),
	FOREIGN KEY(owner_id) REFERENCES users (id),
	FOREIGN KEY(tenant_admin_id) REFERENCES users (id)
)

;
CREATE INDEX ix_housing_groups_owner_id ON housing_groups (owner_id);
CREATE INDEX ix_housing_groups_tenant_admin_id ON housing_groups (tenant_admin_id);

CREATE TABLE property_favorites (
	user_id UUID NOT NULL,
	property_id UUID NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	PRIMARY KEY (user_id, property_id),
	FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE,
	FOREIGN KEY(property_id) REFERENCES properties (id) ON DELETE CASCADE
)

;
CREATE INDEX ix_property_favorites_property_id ON property_favorites (property_id);

CREATE TABLE tenancies (
	property_id UUID NOT NULL,
	user_id UUID NOT NULL,
	active BOOLEAN NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	PRIMARY KEY (property_id, user_id),
	FOREIGN KEY(property_id) REFERENCES properties (id),
	FOREIGN KEY(user_id) REFERENCES users (id)
)

;
CREATE INDEX ix_tenancies_user_id ON tenancies (user_id);

CREATE TABLE property_verifications (
	id UUID NOT NULL,
	property_id UUID NOT NULL,
	identity_asset_id UUID NOT NULL,
	ownership_asset_id UUID NOT NULL,
	status VARCHAR(20) NOT NULL,
	reviewer_id UUID,
	review_note VARCHAR(1000),
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
	PRIMARY KEY (id),
	UNIQUE (property_id),
	FOREIGN KEY(property_id) REFERENCES properties (id),
	FOREIGN KEY(identity_asset_id) REFERENCES assets (id),
	FOREIGN KEY(ownership_asset_id) REFERENCES assets (id),
	FOREIGN KEY(reviewer_id) REFERENCES users (id)
)

;
CREATE INDEX ix_property_verifications_ownership_asset_id ON property_verifications (ownership_asset_id);
CREATE INDEX ix_property_verifications_identity_asset_id ON property_verifications (identity_asset_id);
CREATE INDEX ix_property_verifications_reviewer_id ON property_verifications (reviewer_id);
