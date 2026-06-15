{{ config(materialized='ephemeral') }}

WITH ranked_events AS (

    SELECT
        event_id,
        user_id,
        session_id,
        event_type,
        event_timestamp,
        event_date,
        country,
        device,
        product_id,
        price,
        source_filename,
        loaded_at,
        bronze_created_at,

        ROW_NUMBER() OVER (
            PARTITION BY event_id
            ORDER BY loaded_at DESC
        ) AS row_num

    FROM {{ ref('bronze_events') }}

),

validated_events AS (

    SELECT
        *,

        CASE
            WHEN event_id IS NULL THEN 'missing_event_id'
            WHEN user_id IS NULL THEN 'missing_user_id'
            WHEN session_id IS NULL THEN 'missing_session_id'
            WHEN event_type IS NULL THEN 'missing_event_type'
            WHEN event_timestamp IS NULL THEN 'missing_event_timestamp'

            WHEN event_type NOT IN (
                'view_product',
                'add_to_cart',
                'purchase',
                'login',
                'logout',
                'search'
            ) THEN 'invalid_event_type'

            WHEN device NOT IN ('ios', 'android', 'web') THEN 'invalid_device'

            WHEN country NOT IN ('IL', 'US', 'GB', 'DE', 'FR', 'ES') THEN 'invalid_country'

            WHEN event_type = 'purchase'
                 AND price IS NULL THEN 'purchase_missing_price'

            WHEN event_type = 'purchase'
                 AND price <= 0 THEN 'purchase_invalid_price'

            WHEN event_type IN ('view_product', 'add_to_cart', 'purchase')
                 AND product_id IS NULL THEN 'product_event_missing_product_id'

            WHEN row_num > 1 THEN 'duplicate_event_id'

            ELSE NULL
        END AS rejection_reason

    FROM ranked_events

)

SELECT *
FROM validated_events