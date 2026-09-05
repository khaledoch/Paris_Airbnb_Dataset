-- Property-type detail, filtered to real sample sizes only
SELECT
    l.room_type,
    l.property_type,
    COUNT(DISTINCT l.id) AS listing_count,
    ROUND(AVG(l.price)::numeric, 2) AS avg_nightly_price,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.price)::numeric, 2) AS median_nightly_price,
    ROUND(
        100.0 * SUM(CASE WHEN c.available = 'f' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(c.date), 0),
        2
    ) AS occupancy_rate_pct
FROM listings_clean l
LEFT JOIN calendar_clean c ON l.id = c.listing_id
WHERE l.room_type IS NOT NULL AND l.property_type IS NOT NULL
GROUP BY l.room_type, l.property_type
HAVING COUNT(DISTINCT l.id) >= 15
ORDER BY listing_count DESC;