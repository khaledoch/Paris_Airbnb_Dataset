-- 03_listing_performance.sql
-- Business question: Which property types give the strongest mix of price and occupancy?

WITH listing_calendar AS (
    SELECT
        l.id,
        l.room_type,
        l.property_type,
        l.price,
        l.review_scores_rating,
        c.available,
        c.date
    FROM listings_clean l
    LEFT JOIN calendar_clean c
        ON l.id = c.listing_id
),
performance AS (
    SELECT
        room_type,
        property_type,
        COUNT(DISTINCT id) AS listing_count,
        ROUND(AVG(price), 2) AS avg_nightly_price,
        ROUND(AVG(review_scores_rating), 2) AS avg_review_score,
        ROUND(
            100.0 * SUM(CASE WHEN available = FALSE THEN 1 ELSE 0 END)
            / NULLIF(COUNT(date), 0),
            2
        ) AS occupancy_rate_pct,
        ROUND(
            SUM(CASE WHEN available = FALSE THEN COALESCE(price, 0) ELSE 0 END)
            / NULLIF(COUNT(DISTINCT id), 0),
            2
        ) AS revenue_per_listing_proxy
    FROM listing_calendar
    WHERE room_type IS NOT NULL AND property_type IS NOT NULL
    GROUP BY room_type, property_type
)
SELECT *
FROM performance
WHERE occupancy_rate_pct IS NOT NULL
ORDER BY revenue_per_listing_proxy DESC, occupancy_rate_pct DESC
LIMIT 15;
