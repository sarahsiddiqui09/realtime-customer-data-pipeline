with transactions as (
    select * from {{ ref('stg_transactions') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
)

select
    t.transaction_id,
    t.customer_id,
    c.country     as customer_country,
    c.signup_date as customer_signup_date,
    t.amount,
    t.currency,
    t.transaction_type,
    t.payment_method,
    t.status,
    t.transaction_timestamp,
    -- Refunds are negative at the source; normalize into an explicit signed net_amount.
    case
        when t.transaction_type = 'refund' then -1 * abs(t.amount)
        else abs(t.amount)
    end as net_amount,
    datediff('day', c.signup_date, t.transaction_timestamp::date) as days_since_signup_at_transaction
from transactions t
left join customers c on t.customer_id = c.customer_id
