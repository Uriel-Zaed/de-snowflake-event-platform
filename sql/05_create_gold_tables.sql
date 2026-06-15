-- ============================================================
-- 05_create_gold_tables.sql
-- Purpose: Create Gold business-ready analytics tables
-- ============================================================

USE WAREHOUSE EVENT_PLATFORM_WH;
USE DATABASE EVENT_PLATFORM;

-- ------------------------------------------------------------
-- 1. Daily metrics
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE GOLD.DAILY_METRICS AS
SELECT
    event_date,

    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS daily_active_users,
    COUNT(DISTINCT session_id) AS total_sessions,

    COUNT_IF(event_type = 'view_product') AS product_views,
    COUNT_IF(event_type = 'add_to_cart') AS add_to_cart_events,
    COUNT_IF(event_type = 'purchase') AS purchase_events,

    ROUND(SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END), 2) AS total_revenue,

    ROUND(
        SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END)
        / NULLIF(COUNT_IF(event_type = 'purchase'), 0),
        2
    ) AS avg_order_value,

    ROUND(
        COUNT_IF(event_type = 'purchase')
        / NULLIF(COUNT(DISTINCT session_id), 0),
        4
    ) AS purchase_events_per_session,

    CURRENT_TIMESTAMP() AS gold_created_at

FROM SILVER.EVENTS_CLEAN
GROUP BY event_date;


-- ------------------------------------------------------------
-- 2. Daily events by type
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE GOLD.EVENTS_BY_TYPE_DAILY AS
SELECT
    event_date,
    event_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_id) AS unique_users,
    CURRENT_TIMESTAMP() AS gold_created_at

FROM SILVER.EVENTS_CLEAN
GROUP BY
    event_date,
    event_type;


-- ------------------------------------------------------------
-- 3. Daily revenue by country
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE GOLD.REVENUE_BY_COUNTRY_DAILY AS
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

FROM SILVER.EVENTS_CLEAN
GROUP BY
    event_date,
    country;


-- ------------------------------------------------------------
-- 4. Daily conversion funnel
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE GOLD.CONVERSION_FUNNEL_DAILY AS
WITH user_daily_flags AS (
    SELECT
        event_date,
        user_id,

        MAX(CASE WHEN event_type = 'view_product' THEN 1 ELSE 0 END) AS viewed_product,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased

    FROM SILVER.EVENTS_CLEAN
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
GROUP BY event_date;