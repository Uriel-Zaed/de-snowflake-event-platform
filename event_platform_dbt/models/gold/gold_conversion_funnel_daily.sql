{{ config(materialized='table') }}

WITH user_daily_flags AS (

    SELECT
        event_date,
        user_id,

        MAX(CASE WHEN is_product_view THEN 1 ELSE 0 END) AS viewed_product,
        MAX(CASE WHEN is_add_to_cart THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN is_purchase THEN 1 ELSE 0 END) AS purchased

    FROM {{ ref('fact_events') }}
    GROUP BY
        event_date,
        user_id

)

SELECT
    event_date,

    COUNT(*) AS active_users,

    SUM(viewed_product) AS users_viewed_product,
    SUM(added_to_cart) AS users_added_to_cart,
    SUM(purchased) AS users_purchased,

    ROUND(
        SUM(added_to_cart) / NULLIF(SUM(viewed_product), 0),
        4
    ) AS view_to_cart_rate,

    ROUND(
        SUM(purchased) / NULLIF(SUM(added_to_cart), 0),
        4
    ) AS cart_to_purchase_rate,

    ROUND(
        SUM(purchased) / NULLIF(SUM(viewed_product), 0),
        4
    ) AS view_to_purchase_rate,

    CURRENT_TIMESTAMP() AS gold_created_at

FROM user_daily_flags
GROUP BY event_date