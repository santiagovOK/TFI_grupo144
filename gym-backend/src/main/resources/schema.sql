CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS users (
    member_number VARCHAR(20) PRIMARY KEY,
    email VARCHAR(255),
    password VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    dni VARCHAR(15) UNIQUE NOT NULL,
    birth_date DATE,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'USER' CHECK (role IN ('ADMIN', 'STAFF', 'USER')),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_user_contact CHECK (email IS NOT NULL OR phone IS NOT NULL),
    CONSTRAINT chk_user_staff_login CHECK (role = 'USER' OR (email IS NOT NULL AND password IS NOT NULL)),
    CONSTRAINT chk_user_name CHECK (TRIM(name) <> ''),
    CONSTRAINT chk_user_last_name CHECK (TRIM(last_name) <> ''),
    CONSTRAINT chk_user_dni CHECK (TRIM(dni) <> ''),
    CONSTRAINT chk_user_email CHECK (TRIM(email) <> ''),
    CONSTRAINT chk_user_phone CHECK (TRIM(phone) <> '')
    );

CREATE TABLE IF NOT EXISTS enrollment (
    subscription_number SERIAL PRIMARY KEY,
    member_number VARCHAR(20) NOT NULL REFERENCES users(member_number) ON DELETE RESTRICT,
    modality VARCHAR(20) NOT NULL CHECK (modality IN ('FREE', 'THREE', 'TWO')),
    price DECIMAL(19,2) NOT NULL,
    discount DECIMAL(19,2),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    comments VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELLED', 'EXPIRED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_enrollment_dates CHECK (end_date > start_date),
    CONSTRAINT chk_enrollment_price CHECK (price >= 0),
    CONSTRAINT chk_enrollment_discount CHECK (discount IS NULL OR (discount >= 0 AND discount <= price)),
    CONSTRAINT no_overlap_enrollment EXCLUDE USING gist (member_number WITH =, tstzrange(start_date, end_date, '[)') WITH &&) WHERE (status != 'CANCELLED')
    );

CREATE TABLE IF NOT EXISTS payment (
    receipt_number SERIAL PRIMARY KEY,
    subscription_number INTEGER NOT NULL REFERENCES enrollment(subscription_number) ON DELETE RESTRICT,
    amount DECIMAL(19,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'ARS' CHECK (currency IN ('ARS', 'USD')),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'CANCELLED')),
    payment_method VARCHAR(50),
    gateway_payment_id VARCHAR(100) UNIQUE,
    comments VARCHAR(500),
    discount DECIMAL(19,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT chk_payment_discount CHECK (discount IS NULL OR (discount >= 0 AND discount <= amount))
    );

CREATE TABLE IF NOT EXISTS access (
    access_id SERIAL PRIMARY KEY,
    member_number VARCHAR(20) NOT NULL REFERENCES users(member_number) ON DELETE RESTRICT,
    subscription_number INTEGER REFERENCES enrollment(subscription_number) ON DELETE RESTRICT,
    access_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('GRANTED', 'DENIED')),
    denied_reason VARCHAR(500),
    CONSTRAINT chk_access_logic CHECK ((status = 'GRANTED' AND subscription_number IS NOT NULL) OR (status = 'DENIED' AND denied_reason IS NOT NULL))
    );

CREATE UNIQUE INDEX IF NOT EXISTS ux_users_email_staff ON users (LOWER(email)) WHERE role IN ('ADMIN', 'STAFF');
CREATE INDEX IF NOT EXISTS ix_enrollment_member_number ON enrollment (member_number);
CREATE INDEX IF NOT EXISTS ix_payment_subscription_number ON payment (subscription_number);
CREATE INDEX IF NOT EXISTS ix_access_subscription_number ON access (subscription_number);
CREATE INDEX IF NOT EXISTS ix_access_access_date ON access (access_date);