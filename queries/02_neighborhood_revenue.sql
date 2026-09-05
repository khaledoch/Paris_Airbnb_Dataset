-- 02_neighborhood_revenue.sql
-- Business question: Which neighborhoods in Paris generate the strongest value?

WITH listing_calendar AS (
    SELECT
        l.id,
        l.neighbourhood_cleansed,
        l.price,
        c.available,
        c.date
    FROM listings_clean l
    LEFT JOIN calendar_clean c
        ON l.id = c.listing_id
),
neighborhood_summary AS (
    SELECT
        neighbourhood_cleansed,
        COUNT(DISTINCT id) AS listing_count,
        ROUND(AVG(price), 2) AS avg_nightly_price,
        ROUND(
            100.0 * SUM(CASE WHEN available = FALSE THEN 1 ELSE 0 END)
            / NULLIF(COUNT(date), 0),
            2
        ) AS occupancy_rate_pct,
        ROUND(
            SUM(CASE WHEN available = FALSE THEN COALESCE(price, 0) ELSE 0 END),
            2
        ) AS estimated_revenue_proxy
    FROM listing_calendar
    WHERE neighbourhood_cleansed IS NOT NULL
    GROUP BY neighbourhood_cleansed
)
SELECT *
FROM neighborhood_summary
WHERE occupancy_rate_pct IS NOT NULL
ORDER BY estimated_revenue_proxy DESC
LIMIT 10;








ll
