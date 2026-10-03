CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS persons (
    dni VARCHAR(15) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    birth_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_person_contact CHECK (email IS NOT NULL OR phone IS NOT NULL),
    CONSTRAINT chk_person_name CHECK (TRIM(name) <> ''),
    CONSTRAINT chk_person_last_name CHECK (TRIM(last_name) <> ''),
    CONSTRAINT chk_person_dni CHECK (TRIM(dni) <> ''),
    CONSTRAINT chk_person_email CHECK (TRIM(email) <> ''),
    CONSTRAINT chk_person_phone CHECK (TRIM(phone) <> '')
);

CREATE TABLE IF NOT EXISTS members (
    member_number VARCHAR(20) PRIMARY KEY,
    dni VARCHAR(15) UNIQUE NOT NULL REFERENCES persons(dni) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    join_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_member_number CHECK (TRIM(member_number) <> '')
);

CREATE TABLE IF NOT EXISTS employees (
    employee_code VARCHAR(20) PRIMARY KEY,
    dni VARCHAR(15) UNIQUE NOT NULL REFERENCES persons(dni) ON DELETE RESTRICT,
    work_email VARCHAR(255) NOT NULL, -- Unicidad case-insensitive asegurada mediante ux_employees_work_email
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('ADMIN', 'STAFF')),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_employee_code CHECK (TRIM(employee_code) <> ''),
    CONSTRAINT chk_employee_work_email CHECK (TRIM(work_email) <> ''),
    CONSTRAINT chk_employee_password CHECK (TRIM(password) <> '')
);
CREATE TABLE IF NOT EXISTS plans (
    plan_code VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    weekly_limit INTEGER,
    current_price DECIMAL(19,2) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_plan_code CHECK (TRIM(plan_code) <> ''),
    CONSTRAINT chk_plan_name CHECK (TRIM(name) <> ''),
    CONSTRAINT chk_plan_current_price CHECK (current_price >= 0),
    CONSTRAINT chk_plan_weekly_limit CHECK (weekly_limit IS NULL OR weekly_limit >= 0)
);


CREATE TABLE IF NOT EXISTS subscriptions (
    subscription_number SERIAL PRIMARY KEY,
    member_number VARCHAR(20) NOT NULL REFERENCES members(member_number) ON DELETE RESTRICT,
    plan_code VARCHAR(20) NOT NULL REFERENCES plans(plan_code) ON DELETE RESTRICT,
    price DECIMAL(19,2) NOT NULL,
    discount DECIMAL(19,2),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    comments VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT chk_subscription_dates CHECK (end_date > start_date),
    CONSTRAINT chk_subscription_price CHECK (price >= 0),
    CONSTRAINT chk_subscription_discount CHECK (discount IS NULL OR (discount >= 0 AND discount <= price)),
    CONSTRAINT no_overlap_subscriptions EXCLUDE USING gist (member_number WITH =, tstzrange(start_date, end_date, '[)') WITH &&) WHERE (status != 'CANCELLED')
);

CREATE TABLE IF NOT EXISTS payment (
    receipt_number SERIAL PRIMARY KEY,
    subscription_number INTEGER NOT NULL REFERENCES subscriptions(subscription_number) ON DELETE RESTRICT,
    amount DECIMAL(19,2) NOT NULL,
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
    member_number VARCHAR(20) NOT NULL REFERENCES members(member_number) ON DELETE RESTRICT,
    subscription_number INTEGER REFERENCES subscriptions(subscription_number) ON DELETE RESTRICT,
    access_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('GRANTED', 'DENIED')),
    denied_reason VARCHAR(500),
    CONSTRAINT chk_access_logic CHECK ((status = 'GRANTED' AND subscription_number IS NOT NULL) OR (status = 'DENIED' AND denied_reason IS NOT NULL))
    );

CREATE INDEX IF NOT EXISTS ix_persons_email ON persons (LOWER(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_employees_work_email ON employees (LOWER(work_email));
CREATE INDEX IF NOT EXISTS ix_subscriptions_member_number ON subscriptions (member_number);
CREATE INDEX IF NOT EXISTS ix_payment_subscription_number ON payment (subscription_number);
CREATE INDEX IF NOT EXISTS ix_access_subscription_number ON access (subscription_number);
CREATE INDEX IF NOT EXISTS ix_access_access_date ON access (access_date);
CREATE INDEX IF NOT EXISTS ix_subscriptions_plan_code ON subscriptions (plan_code);