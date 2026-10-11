CREATE TABLE IF NOT EXISTS customers (
    customer_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    country         VARCHAR(100)    NOT NULL,
    signup_date     DATE            NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id          BIGSERIAL PRIMARY KEY,
    customer_id             INTEGER         NOT NULL REFERENCES customers(customer_id),
    amount                  NUMERIC(12, 2)  NOT NULL,
    currency                VARCHAR(3)      NOT NULL DEFAULT 'USD',
    transaction_type        VARCHAR(20)     NOT NULL,
    payment_method          VARCHAR(20)     NOT NULL,
    status                  VARCHAR(20)     NOT NULL,
    transaction_timestamp   TIMESTAMP       NOT NULL DEFAULT now(),
    created_at              TIMESTAMP       NOT NULL DEFAULT now(),
    updated_at              TIMESTAMP       NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(transaction_timestamp);

-- Debezium (pgoutput) subscribes to this publication.
CREATE PUBLICATION dbz_publication FOR TABLE customers, transactions;

INSERT INTO customers (first_name, last_name, email, country, signup_date) VALUES
    ('Aditi', 'Sharma', 'aditi.sharma@example.com', 'India', '2024-01-15'),
    ('Rahul', 'Verma', 'rahul.verma@example.com', 'India', '2024-02-20'),
    ('Emily', 'Clarke', 'emily.clarke@example.com', 'United Kingdom', '2024-03-05')
ON CONFLICT (email) DO NOTHING;
