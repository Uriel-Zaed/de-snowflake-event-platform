{{ config(materialized='table') }}

SELECT
    event_date,
    event_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_id) AS unique_users,
    CURRENT_TIMESTAMP() AS gold_created_at

FROM {{ ref('fact_events') }}
GROUP BY
    event_date,
    event_type