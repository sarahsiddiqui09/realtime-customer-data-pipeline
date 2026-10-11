select
    transaction_id,
    customer_id,
    amount,
    net_amount,
    currency,
    transaction_type,
    payment_method,
    status,
    transaction_timestamp,
    date_trunc('day', transaction_timestamp) as transaction_date,
    days_since_signup_at_transaction,
    customer_country
from {{ ref('int_transactions_enriched') }}
