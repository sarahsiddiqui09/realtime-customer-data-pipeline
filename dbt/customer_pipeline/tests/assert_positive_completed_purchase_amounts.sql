-- Fails (returns rows) if any completed purchase has a non-positive amount.
select transaction_id, amount, transaction_type, status
from {{ ref('fct_transactions') }}
where transaction_type = 'purchase'
  and status = 'completed'
  and amount <= 0
