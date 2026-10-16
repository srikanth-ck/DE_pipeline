-- PostgreSQL 15+
CREATE SCHEMA IF NOT EXISTS demo;
SET search_path TO demo;

CREATE TABLE IF NOT EXISTS customer_stage (
    customer_id INTEGER,
    customer_name TEXT,
    city TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    city TEXT,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customer_stage(customer_id, customer_name, city) VALUES
(1, 'Asha Rao', 'Bengaluru'),
(2, 'Ravi Kumar', 'Mysuru')
ON CONFLICT DO NOTHING;

-- MERGE: update matched dimension rows; insert new customer rows.
MERGE INTO dim_customer AS target
USING customer_stage AS source
ON target.customer_id = source.customer_id
WHEN MATCHED THEN
    UPDATE SET customer_name = source.customer_name,
               city = source.city,
               updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name, city, updated_at)
    VALUES (source.customer_id, source.customer_name, source.city, CURRENT_TIMESTAMP);

-- Range partitioning example
CREATE TABLE IF NOT EXISTS sales_events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY,
    event_date DATE NOT NULL,
    customer_id INTEGER NOT NULL,
    amount NUMERIC(12,2) NOT NULL
) PARTITION BY RANGE (event_date);

CREATE TABLE IF NOT EXISTS sales_events_2026_h1
    PARTITION OF sales_events
    FOR VALUES FROM ('2026-01-01') TO ('2026-07-01');

CREATE TABLE IF NOT EXISTS sales_events_2026_h2
    PARTITION OF sales_events
    FOR VALUES FROM ('2026-07-01') TO ('2027-01-01');

INSERT INTO sales_events(event_date, customer_id, amount)
VALUES ('2026-02-01', 1, 1200.00), ('2026-08-15', 2, 900.00);

-- Bulk import example (prepare a CSV with customer_id, customer_name, city)
-- In psql, use a client-side path:
-- \copy customer_stage(customer_id, customer_name, city) FROM 'customers.csv' WITH (FORMAT csv, HEADER true)
-- Server-side alternative:
-- COPY customer_stage(customer_id, customer_name, city) FROM '/server/path/customers.csv' WITH (FORMAT csv, HEADER true);

-- Composite index: useful for queries filtering by customer and date.
CREATE INDEX IF NOT EXISTS idx_sales_customer_date
ON sales_events(customer_id, event_date);

-- Partial index: indexes only larger transactions.
CREATE INDEX IF NOT EXISTS idx_sales_large_amount
ON sales_events(event_date)
WHERE amount >= 1000;

-- Validate partitioned data and MERGE result.
SELECT * FROM dim_customer ORDER BY customer_id;
SELECT tableoid::regclass AS partition_name, * FROM sales_events ORDER BY event_date;
