SELECT
    event_id,
    rejection_reason
FROM {{ ref('silver_events_rejected') }}
WHERE rejection_reason IS NULL