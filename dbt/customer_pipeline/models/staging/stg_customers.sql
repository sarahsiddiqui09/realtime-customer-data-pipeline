-- Debezium emits one Kafka message per change, so a customer_id can appear many
-- times. Keep the latest message per customer_id by Kafka offset (monotonic per partition).

with source as (
    select
        record_content:customer_id::int            as customer_id,
        record_content:first_name::string           as first_name,
        record_content:last_name::string            as last_name,
        record_content:email::string                as email,
        record_content:country::string              as country,
        record_content:signup_date::date            as signup_date,
        record_content:updated_at::timestamp_ntz    as source_updated_at,
        record_metadata:CreateTime::timestamp_ntz   as _kafka_ingested_at,
        row_number() over (
            partition by record_content:customer_id::int
            order by record_metadata:offset::int desc
        ) as _rn
    from {{ source('raw', 'customers_raw') }}
    where record_content:customer_id is not null
)

select
    customer_id, first_name, last_name, email, country,
    signup_date, source_updated_at, _kafka_ingested_at
from source
where _rn = 1
