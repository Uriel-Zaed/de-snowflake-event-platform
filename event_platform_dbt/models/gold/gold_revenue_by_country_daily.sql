{{ config(materialized='table') }}

SELECT
    event_date,
    country,

    COUNT(*) AS purchase_events,

    ROUND(
        SUM(purchase_amount),
        2
    ) AS total_revenue,

    COUNT(DISTINCT user_id) AS purchasing_users,

    ROUND(
        SUM(purchase_amount)
        / NULLIF(COUNT(DISTINCT user_id), 0),
        2
    ) AS revenue_per_purchasing_user,

    CURRENT_TIMESTAMP() AS gold_created_at

FROM {{ ref('fact_purchases') }}
GROUP BY
    event_date,
    country