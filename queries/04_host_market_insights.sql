-- 04_host_market_insights.sql
-- Business question: Do superhosts outperform regular hosts in price, satisfaction and booking likelihood?

WITH host_calendar AS (
    SELECT
        l.id,
        l.host_is_superhost,
        l.price,
        l.review_scores_rating,
        l.host_response_rate,
        c.available,
        c.date
    FROM listings_clean l
    LEFT JOIN calendar_clean c
        ON l.id = c.listing_id
),
host_summary AS (
    SELECT
        host_is_superhost,
        COUNT(DISTINCT id) AS listing_count,
        ROUND(AVG(price), 2) AS avg_nightly_price,
        ROUND(AVG(review_scores_rating), 2) AS avg_review_score,
        ROUND(AVG(host_response_rate), 4) AS avg_response_rate,
        ROUND(
            100.0 * SUM(CASE WHEN available = FALSE THEN 1 ELSE 0 END)
            / NULLIF(COUNT(date), 0),
            2
        ) AS occupancy_rate_pct,
        ROUND(
            SUM(CASE WHEN available = FALSE THEN COALESCE(price, 0) ELSE 0 END),
            2
        ) AS estimated_revenue_proxy
    FROM host_calendar
    WHERE host_is_superhost IS NOT NULL
    GROUP BY host_is_superhost
)
SELECT *
FROM host_summary
WHERE occupancy_rate_pct IS NOT NULL
ORDER BY estimated_revenue_proxy DESC;
