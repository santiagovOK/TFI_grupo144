CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
    member_number VARCHAR(20) PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    dni VARCHAR(15) UNIQUE NOT NULL,
    birth_date TIMESTAMP,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT chk_user_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
    );

CREATE TABLE IF NOT EXISTS enrollment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_number VARCHAR(20) NOT NULL REFERENCES users(member_number) ON DELETE CASCADE,
    modality VARCHAR(20),
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    comments VARCHAR(500),
    weekly_accesses INTEGER NOT NULL DEFAULT 0,
    last_access_reset TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS payment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_id UUID NOT NULL REFERENCES enrollment(id) ON DELETE CASCADE,
    amount DECIMAL(19,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'ARS',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(50),
    external_reference VARCHAR(100),
    comments VARCHAR(500),
    discount DECIMAL(19,2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_id UUID NOT NULL REFERENCES enrollment(id) ON DELETE CASCADE,
    access_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'GRANTED',
    denied_reason VARCHAR(500)
    );