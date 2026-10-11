"""
Simulates a live application writing to the source Postgres database:
  1. Seeds customers on first run (idempotent).
  2. Continuously inserts transactions and updates pending ones, so Debezium
     captures both INSERT and UPDATE change events.
"""

import os
import random
import time

import psycopg2
from faker import Faker

fake = Faker()

PG_HOST = os.environ.get("POSTGRES_HOST", "localhost")
PG_DB = os.environ.get("POSTGRES_DB", "customer_db")
PG_USER = os.environ.get("POSTGRES_USER", "pipeline_user")
PG_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "pipeline_pass")

SEED_CUSTOMERS = int(os.environ.get("SEED_CUSTOMERS", 200))
TRANSACTIONS_PER_CYCLE = int(os.environ.get("TRANSACTIONS_PER_CYCLE", 5))
CYCLE_SECONDS = int(os.environ.get("CYCLE_SECONDS", 10))

TRANSACTION_TYPES = ["purchase", "purchase", "purchase", "subscription", "refund"]
PAYMENT_METHODS = ["credit_card", "paypal", "upi", "net_banking"]
CURRENCIES = ["USD", "USD", "EUR", "INR", "GBP"]


def get_connection(retries: int = 30, delay: int = 2):
    last_err = None
    for _ in range(retries):
        try:
            return psycopg2.connect(
                host=PG_HOST, dbname=PG_DB, user=PG_USER, password=PG_PASSWORD
            )
        except psycopg2.OperationalError as e:
            last_err = e
            time.sleep(delay)
    raise last_err


def seed_customers(conn, count: int):
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM customers")
        (existing,) = cur.fetchone()
        if existing >= count:
            print(f"[seed] {existing} customers already present - skipping seed.")
            return
        to_create = count - existing
        print(f"[seed] inserting {to_create} customers...")
        for _ in range(to_create):
            cur.execute(
                """
                INSERT INTO customers (first_name, last_name, email, country, signup_date)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (email) DO NOTHING
                """,
                (
                    fake.first_name(),
                    fake.last_name(),
                    fake.unique.email(),
                    fake.country(),
                    fake.date_between(start_date="-2y", end_date="today"),
                ),
            )
        conn.commit()


def insert_transaction(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT customer_id FROM customers ORDER BY random() LIMIT 1")
        row = cur.fetchone()
        if not row:
            return
        amount = round(random.uniform(5, 500), 2)
        txn_type = random.choice(TRANSACTION_TYPES)
        if txn_type == "refund":
            amount = -amount
        cur.execute(
            """
            INSERT INTO transactions
                (customer_id, amount, currency, transaction_type, payment_method, status, transaction_timestamp)
            VALUES (%s, %s, %s, %s, %s, %s, now())
            """,
            (row[0], amount, random.choice(CURRENCIES), txn_type,
             random.choice(PAYMENT_METHODS), "pending"),
        )
        conn.commit()


def promote_pending_transactions(conn):
    with conn.cursor() as cur:
        cur.execute(
            "SELECT transaction_id FROM transactions WHERE status = 'pending' ORDER BY random() LIMIT 3"
        )
        for (tid,) in cur.fetchall():
            new_status = random.choices(["completed", "failed"], weights=[9, 1])[0]
            cur.execute(
                "UPDATE transactions SET status = %s, updated_at = now() WHERE transaction_id = %s",
                (new_status, tid),
            )
        conn.commit()


def main():
    conn = get_connection()
    print("[generator] connected to Postgres.")
    seed_customers(conn, SEED_CUSTOMERS)
    while True:
        for _ in range(TRANSACTIONS_PER_CYCLE):
            insert_transaction(conn)
        promote_pending_transactions(conn)
        print(f"[generator] cycle complete: +{TRANSACTIONS_PER_CYCLE} transactions.")
        time.sleep(CYCLE_SECONDS)


if __name__ == "__main__":
    main()
