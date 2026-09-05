-- 01_data_cleaning.sql
-- Goal: create a clean staging layer for the Paris Airbnb project without losing the grain needed for Power BI.
--
-- Architecture rule:
--   - listings = dimension table (1 row per property)
--   - calendar and reviews = fact tables (keep detailed grain)
--   - never pre-aggregate away detail before the dashboard layer
--
-- Data checks already verified in the project notebook:
--   - host_profile_id is not safe to use because of float precision corruption
--   - price fields are text strings and need numeric conversion
--   - date columns are likely stored as text and need conversion
--   - boolean-like fields are likely stored as 't'/'f' and need real bool conversion
--   - the null-heavy and corrupted columns identified in the raw schema should be dropped from the cleaned model

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) Audit the raw tables before cleaning
-- -----------------------------------------------------------------------------
SELECT 'listings' AS table_name, COUNT(*) AS row_count FROM listings;
SELECT 'calendar' AS table_name, COUNT(*) AS row_count FROM calendar;
SELECT 'reviews' AS table_name, COUNT(*) AS row_count FROM reviews;

SELECT *
FROM listings
LIMIT 5;

SELECT *
FROM calendar
LIMIT 5;

SELECT *
FROM reviews
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 2) Clean listings into a dimension table
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS listings_clean;

CREATE TABLE listings_clean AS
SELECT
    CAST(id AS BIGINT) AS id,
    CAST(host_id AS BIGINT) AS host_id,
    NULLIF(TRIM(name), '') AS name,
    NULLIF(TRIM(description), '') AS description,
    NULLIF(TRIM(neighbourhood_cleansed), '') AS neighbourhood_cleansed,
    CASE WHEN latitude IS NULL THEN NULL ELSE CAST(latitude AS NUMERIC) END AS latitude,
    CASE WHEN longitude IS NULL THEN NULL ELSE CAST(longitude AS NUMERIC) END AS longitude,
    NULLIF(TRIM(property_type), '') AS property_type,
    NULLIF(TRIM(room_type), '') AS room_type,
    CASE WHEN accommodates IS NULL THEN NULL ELSE CAST(accommodates AS INT) END AS accommodates,
    NULLIF(TRIM(bathrooms_text), '') AS bathrooms_text,
    CASE WHEN bedrooms IS NULL THEN NULL ELSE CAST(bedrooms AS INT) END AS bedrooms,
    CASE WHEN beds IS NULL THEN NULL ELSE CAST(beds AS INT) END AS beds,
    CASE
        WHEN price IS NULL THEN NULL
        WHEN TRIM(price) = '' THEN NULL
        ELSE CAST(REGEXP_REPLACE(price, '[^0-9.-]', '', 'g') AS NUMERIC)
    END AS price,
    CASE 
        WHEN lower(COALESCE(host_is_superhost, '')) IN ('t','true','y','yes','1') THEN TRUE
        WHEN lower(COALESCE(host_is_superhost, '')) IN ('f','false','n','no','0') THEN FALSE
        ELSE NULL
    END AS host_is_superhost,
    CASE 
        WHEN lower(COALESCE(host_has_profile_pic, '')) IN ('t','true','y','yes','1') THEN TRUE
        WHEN lower(COALESCE(host_has_profile_pic, '')) IN ('f','false','n','no','0') THEN FALSE
        ELSE NULL
    END AS host_has_profile_pic,
    CASE 
        WHEN lower(COALESCE(host_identity_verified, '')) IN ('t','true','y','yes','1') THEN TRUE
        WHEN lower(COALESCE(host_identity_verified, '')) IN ('f','false','n','no','0') THEN FALSE
        ELSE NULL
    END AS host_identity_verified,
    CASE 
        WHEN lower(COALESCE(has_availability, '')) IN ('t','true','y','yes','1') THEN TRUE
        WHEN lower(COALESCE(has_availability, '')) IN ('f','false','n','no','0') THEN FALSE
        ELSE NULL
    END AS has_availability,
    CASE
        WHEN host_response_rate IS NULL THEN NULL
        ELSE CAST(host_response_rate AS NUMERIC)
    END AS host_response_rate,
    CASE
        WHEN host_acceptance_rate IS NULL THEN NULL
        ELSE CAST(host_acceptance_rate AS NUMERIC)
    END AS host_acceptance_rate,
    CASE
        WHEN review_scores_rating IS NULL THEN NULL
        ELSE CAST(review_scores_rating AS NUMERIC)
    END AS review_scores_rating,
    CASE
        WHEN review_scores_accuracy IS NULL THEN NULL
        ELSE CAST(review_scores_accuracy AS NUMERIC)
    END AS review_scores_accuracy,
    CASE
        WHEN review_scores_cleanliness IS NULL THEN NULL
        ELSE CAST(review_scores_cleanliness AS NUMERIC)
    END AS review_scores_cleanliness,
    CASE
        WHEN review_scores_checkin IS NULL THEN NULL
        ELSE CAST(review_scores_checkin AS NUMERIC)
    END AS review_scores_checkin,
    CASE
        WHEN review_scores_communication IS NULL THEN NULL
        ELSE CAST(review_scores_communication AS NUMERIC)
    END AS review_scores_communication,
    CASE
        WHEN review_scores_location IS NULL THEN NULL
        ELSE CAST(review_scores_location AS NUMERIC)
    END AS review_scores_location,
    CASE
        WHEN review_scores_value IS NULL THEN NULL
        ELSE CAST(review_scores_value AS NUMERIC)
    END AS review_scores_value,
    CASE WHEN last_scraped IS NULL THEN NULL ELSE CAST(last_scraped AS DATE) END AS last_scraped,
    CASE WHEN calendar_last_scraped IS NULL THEN NULL ELSE CAST(calendar_last_scraped AS DATE) END AS calendar_last_scraped,
    CASE WHEN first_review IS NULL THEN NULL ELSE CAST(first_review AS DATE) END AS first_review,
    CASE WHEN last_review IS NULL THEN NULL ELSE CAST(last_review AS DATE) END AS last_review,
    NULLIF(TRIM(host_name), '') AS host_name,
    NULLIF(TRIM(host_location), '') AS host_location,
    NULLIF(TRIM(host_about), '') AS host_about,
    CASE WHEN availability_30 IS NULL THEN NULL ELSE CAST(availability_30 AS INT) END AS availability_30,
    CASE WHEN availability_60 IS NULL THEN NULL ELSE CAST(availability_60 AS INT) END AS availability_60,
    CASE WHEN availability_90 IS NULL THEN NULL ELSE CAST(availability_90 AS INT) END AS availability_90,
    CASE WHEN availability_365 IS NULL THEN NULL ELSE CAST(availability_365 AS INT) END AS availability_365,
    CASE WHEN number_of_reviews IS NULL THEN NULL ELSE CAST(number_of_reviews AS INT) END AS number_of_reviews,
    CASE WHEN number_of_reviews_ltm IS NULL THEN NULL ELSE CAST(number_of_reviews_ltm AS INT) END AS number_of_reviews_ltm,
    CASE WHEN number_of_reviews_l30d IS NULL THEN NULL ELSE CAST(number_of_reviews_l30d AS INT) END AS number_of_reviews_l30d,
    CASE WHEN reviews_per_month IS NULL THEN NULL ELSE CAST(reviews_per_month AS NUMERIC) END AS reviews_per_month
FROM listings;

ALTER TABLE listings_clean
    ADD PRIMARY KEY (id);

-- -----------------------------------------------------------------------------
-- 3) Clean calendar into fact table grain
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS calendar_clean;

CREATE TABLE calendar_clean AS
SELECT
    CAST(listing_id AS BIGINT) AS listing_id,
    CASE WHEN NULLIF(TRIM(date), '') IS NULL THEN NULL ELSE CAST(NULLIF(TRIM(date), '') AS DATE) END AS date,
    CASE 
        WHEN lower(COALESCE(available, '')) IN ('t','true','y','yes','1') THEN TRUE
        WHEN lower(COALESCE(available, '')) IN ('f','false','n','no','0') THEN FALSE
        ELSE NULL
    END AS available,
    CASE WHEN minimum_nights IS NULL THEN NULL ELSE CAST(minimum_nights AS INT) END AS minimum_nights,
    CASE WHEN maximum_nights IS NULL THEN NULL ELSE CAST(maximum_nights AS INT) END AS maximum_nights
FROM calendar;

-- -----------------------------------------------------------------------------
-- 4) Clean reviews into fact table grain
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS reviews_clean;

CREATE TABLE reviews_clean AS
SELECT
    CAST(id AS BIGINT) AS id,
    CAST(listing_id AS BIGINT) AS listing_id,
    CASE WHEN NULLIF(TRIM(date), '') IS NULL THEN NULL ELSE CAST(NULLIF(TRIM(date), '') AS DATE) END AS review_date,
    CAST(reviewer_id AS BIGINT) AS reviewer_id,
    NULLIF(TRIM(reviewer_name), '') AS reviewer_name,
    NULLIF(TRIM(comments), '') AS comments
FROM reviews;

ALTER TABLE reviews_clean
    ADD PRIMARY KEY (id);

-- -----------------------------------------------------------------------------
-- 5) Quick validation checks after cleaning
-- -----------------------------------------------------------------------------
SELECT 'listings_clean' AS table_name, COUNT(*) AS row_count FROM listings_clean;
SELECT 'calendar_clean' AS table_name, COUNT(*) AS row_count FROM calendar_clean;
SELECT 'reviews_clean' AS table_name, COUNT(*) AS row_count FROM reviews_clean;

SELECT
    'listings_clean' AS table_name,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_prices,
    SUM(CASE WHEN host_is_superhost IS NULL THEN 1 ELSE 0 END) AS null_superhost_flag
FROM listings_clean;

SELECT
    'calendar_clean' AS table_name,
    SUM(CASE WHEN available IS NULL THEN 1 ELSE 0 END) AS null_available_flag,
    COUNT(*) AS total_rows
FROM calendar_clean;

SELECT
    'reviews_clean' AS table_name,
    SUM(CASE WHEN comments IS NULL THEN 1 ELSE 0 END) AS null_comments,
    COUNT(*) AS total_rows
FROM reviews_clean;

COMMIT;
