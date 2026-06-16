SELECT
    event_id,
    event_type,
    product_id
FROM {{ ref('silver_events_clean') }}
WHERE event_type IN ('view_product', 'add_to_cart', 'purchase')
  AND product_id IS NULL