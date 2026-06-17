{{ config(materialized='table') }}

SELECT
    event_date,

    EXTRACT(YEAR FROM event_date) AS year,
    EXTRACT(MONTH FROM event_date) AS month,
    EXTRACT(DAY FROM event_date) AS day_of_month,
    EXTRACT(DAYOFWEEK FROM event_date) AS day_of_week,
    EXTRACT(WEEK FROM event_date) AS week_of_year,
    EXTRACT(QUARTER FROM event_date) AS quarter,

    CASE
        WHEN EXTRACT(DAYOFWEEK FROM event_date) IN (0, 6) THEN TRUE
        ELSE FALSE
    END AS is_weekend,

    CURRENT_TIMESTAMP() AS dim_created_at

FROM (
    SELECT DISTINCT event_date
    FROM {{ ref('silver_events_clean') }}
    WHERE event_date IS NOT NULL
)
