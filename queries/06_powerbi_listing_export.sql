-- 06_powerbi_listing_export.sql
-- Purpose: create one denormalized, interactive Power BI export.


WITH calendar_summary AS (
    SELECT
        listing_id,
        COUNT(*) AS calendar_days,
        COUNT(*) FILTER (WHERE available = FALSE) AS booked_days,
        MIN(date) AS calendar_start_date,
        MAX(date) AS calendar_end_date
    FROM calendar_clean
    GROUP BY listing_id
)
SELECT
    l.id AS listing_id,
    l.neighbourhood_cleansed AS neighborhood,
    l.room_type,
    l.property_type,
    CASE
        WHEN l.host_is_superhost IS TRUE THEN 'Superhost'
        WHEN l.host_is_superhost IS FALSE THEN 'Regular host'
        ELSE 'Unknown'
    END AS host_segment,
    l.price AS nightly_price,
    l.review_scores_rating AS review_score,
    l.accommodates,
    l.bedrooms,
    l.beds,
    l.latitude,
    l.longitude,
    COALESCE(cs.calendar_days, 0) AS calendar_days,
    COALESCE(cs.booked_days, 0) AS booked_days,
    ROUND(
        (
            COALESCE(cs.booked_days, 0)::numeric
            / NULLIF(cs.calendar_days, 0)
        )::numeric,
        2
    ) AS occupancy_rate_pct,
    ROUND(
        (COALESCE(cs.booked_days, 0) * COALESCE(l.price, 0))::numeric,
        2
    ) AS estimated_revenue_proxy,
    cs.calendar_start_date,
    cs.calendar_end_date
FROM listings_clean l
LEFT JOIN calendar_summary cs
    ON cs.listing_id = l.id
WHERE l.price IS NOT NULL
  AND l.price > 0;
