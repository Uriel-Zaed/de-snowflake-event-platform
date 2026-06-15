{{ config(materialized='table') }}

SELECT
    event_date,
    country,

    COUNT_IF(event_type = 'purchase') AS purchase_events,

    ROUND(
        SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END),
        2
    ) AS total_revenue,

    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchasing_users,

    ROUND(
        SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END)
        / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END), 0),
        2
    ) AS revenue_per_purchasing_user,

    CURRENT_TIMESTAMP() AS gold_created_at

FROM {{ ref('silver_events_clean') }}
GROUP BY
    event_date,
    country