with transactions as (
    select * from {{ ref('fct_transactions') }}
    where status = 'completed'
),

customers as (
    select * from {{ ref('dim_customers') }}
),

agg as (
    select
        customer_id,
        count(*)               as total_transactions,
        sum(net_amount)        as lifetime_net_spend,
        avg(amount)            as avg_transaction_amount,
        min(transaction_date)  as first_transaction_date,
        max(transaction_date)  as last_transaction_date,
        sum(case when transaction_type = 'refund' then 1 else 0 end) as refund_count
    from transactions
    group by customer_id
)

select
    c.customer_id,
    c.full_name,
    c.email,
    c.country,
    c.signup_date,
    coalesce(a.total_transactions, 0) as total_transactions,
    coalesce(a.lifetime_net_spend, 0) as lifetime_net_spend,
    a.avg_transaction_amount,
    a.first_transaction_date,
    a.last_transaction_date,
    coalesce(a.refund_count, 0)       as refund_count,
    datediff('day', a.last_transaction_date, current_date()) as days_since_last_transaction,
    case
        when a.last_transaction_date is null then 'never_transacted'
        when datediff('day', a.last_transaction_date, current_date()) <= 30 then 'active'
        when datediff('day', a.last_transaction_date, current_date()) <= 90 then 'at_risk'
        else 'dormant'
    end as customer_status
from customers c
left join agg a on c.customer_id = a.customer_id
