SELECT
    event_id,
    event_type,
    price
FROM {{ ref('silver_events_clean') }}
WHERE event_type != 'purchase'
  AND price IS NOT NULL