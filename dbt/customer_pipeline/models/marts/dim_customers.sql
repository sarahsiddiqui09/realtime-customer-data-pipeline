select
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name as full_name,
    email,
    split_part(email, '@', 2)      as email_domain,
    country,
    signup_date,
    datediff('day', signup_date, current_date()) as days_since_signup,
    source_updated_at,
    _kafka_ingested_at             as last_synced_at
from {{ ref('stg_customers') }}
