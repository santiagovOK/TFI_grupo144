CREATE TABLE IF NOT EXISTS users (
    member_number VARCHAR(20) PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    dni VARCHAR(15) UNIQUE NOT NULL,
    birth_date DATE,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'USER' CHECK (role IN ('ADMIN', 'STAFF', 'USER')),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT chk_user_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
    );

CREATE TABLE IF NOT EXISTS enrollment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_number VARCHAR(20) NOT NULL REFERENCES users(member_number) ON DELETE RESTRICT,
    modality VARCHAR(20) NOT NULL CHECK (modality IN ('FREE', 'THREE', 'TWO')),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    comments VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT chk_enrollment_dates CHECK (end_date > start_date)
    );

CREATE TABLE IF NOT EXISTS payment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_id UUID NOT NULL REFERENCES enrollment(id) ON DELETE RESTRICT,
    amount DECIMAL(19,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'ARS' CHECK (currency IN ('ARS', 'USD')),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'CANCELLED')),
    payment_method VARCHAR(50),
    external_reference VARCHAR(100),
    comments VARCHAR(500),
    discount DECIMAL(19,2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS access (
    member_number VARCHAR(20) NOT NULL REFERENCES users(member_number) ON DELETE RESTRICT,
    enrollment_id UUID REFERENCES enrollment(id) ON DELETE RESTRICT,
    access_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'GRANTED' CHECK (status IN ('GRANTED', 'DENIED')),
    denied_reason VARCHAR(500),
    PRIMARY KEY (member_number, access_date)
    );

CREATE INDEX IF NOT EXISTS ix_enrollment_member_number ON enrollment (member_number);
CREATE INDEX IF NOT EXISTS ix_payment_enrollment_id ON payment (enrollment_id);
CREATE INDEX IF NOT EXISTS ix_access_enrollment_id ON access (enrollment_id);
CREATE INDEX IF NOT EXISTS ix_access_access_date ON access (access_date);
