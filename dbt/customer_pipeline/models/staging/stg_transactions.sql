with source as (
    select
        record_content:transaction_id::bigint             as transaction_id,
        record_content:customer_id::int                    as customer_id,
        record_content:amount::number(12,2)                 as amount,
        record_content:currency::string                     as currency,
        record_content:transaction_type::string              as transaction_type,
        record_content:payment_method::string                as payment_method,
        record_content:status::string                         as status,
        record_content:transaction_timestamp::timestamp_ntz   as transaction_timestamp,
        record_content:updated_at::timestamp_ntz              as source_updated_at,
        record_metadata:CreateTime::timestamp_ntz             as _kafka_ingested_at,
        row_number() over (
            partition by record_content:transaction_id::bigint
            order by record_metadata:offset::int desc
        ) as _rn
    from {{ source('raw', 'transactions_raw') }}
    where record_content:transaction_id is not null
)

select
    transaction_id, customer_id, amount, currency, transaction_type,
    payment_method, status, transaction_timestamp, source_updated_at, _kafka_ingested_at
from source
where _rn = 1
