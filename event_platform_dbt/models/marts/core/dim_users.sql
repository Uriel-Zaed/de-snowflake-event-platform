{{ config(materialized='table') }}

WITH user_events AS (

    SELECT
        user_id,
        country,
        device,
        event_timestamp,
        event_date
    FROM {{ ref('silver_events_clean') }}
    WHERE user_id IS NOT NULL

),

user_summary AS (

    SELECT
        user_id,
        MIN(event_timestamp) AS first_seen_at,
        MAX(event_timestamp) AS last_seen_at,
        MIN(event_date) AS first_seen_date,
        MAX(event_date) AS last_seen_date,
        COUNT(*) AS total_events,
        COUNT(DISTINCT session_id) AS total_sessions,
        COUNT(DISTINCT country) AS countries_count,
        COUNT(DISTINCT device) AS devices_count
    FROM {{ ref('silver_events_clean') }}
    WHERE user_id IS NOT NULL
    GROUP BY user_id

),

latest_user_attributes AS (

    SELECT
        user_id,
        country AS latest_country,
        device AS latest_device
    FROM user_events
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY event_timestamp DESC
    ) = 1

)

SELECT
    user_summary.user_id,
    latest_user_attributes.latest_country,
    latest_user_attributes.latest_device,
    user_summary.first_seen_at,
    user_summary.last_seen_at,
    user_summary.first_seen_date,
    user_summary.last_seen_date,
    user_summary.total_events,
    user_summary.total_sessions,
    user_summary.countries_count,
    user_summary.devices_count,
    CURRENT_TIMESTAMP() AS dim_created_at

FROM user_summary
LEFT JOIN latest_user_attributes
    ON user_summary.user_id = latest_user_attributes.user_id