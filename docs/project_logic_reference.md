# Paris Airbnb Project Logic Reference

This document explains the purpose and logic of each project layer so the analysis can be maintained, reviewed, or rebuilt without relying on undocumented decisions.

## 1. Project Goal

The project analyzes the Paris Airbnb market from a business perspective. It focuses on the relationship between:

- listing supply
- nightly price
- calendar availability
- estimated occupancy
- estimated revenue potential
- property and room type
- neighborhood
- host status
- guest review quality

The intended audience includes investors, hosts, travelers, hiring managers, and anyone reviewing the portfolio project.

The project is designed to answer:

1. What does the Paris Airbnb market look like?
2. Which neighborhoods and listing types show stronger performance?
3. How do price, occupancy, revenue proxy, and review quality interact?
4. Do superhosts appear to perform differently from regular hosts?

## 2. Data Architecture

The raw files are loaded into PostgreSQL first:

- `listings`: one row per listing
- `calendar`: one row per listing and calendar date
- `reviews`: one row per review

The cleaning layer creates:

- `listings_clean`: listing-level dimension table
- `calendar_clean`: daily availability fact table
- `reviews_clean`: review-level fact table

The grain must be preserved:

- listing-level questions use one row per listing
- calendar questions use one row per listing-date
- review questions use one row per review

The calendar table must not be joined directly to reviews. They are separate fact tables and can multiply rows if joined together.

## 3. SQL Files

### `01_data_cleaning.sql`

**Purpose:** Build the clean PostgreSQL staging layer.

**Main logic:**

- converts listing IDs and host IDs to integer types
- converts price text into numeric price values
- converts boolean-like values such as `t` and `f` into real booleans
- converts date fields into SQL dates
- keeps listing, calendar, and review tables at their original useful grain
- creates a primary key on `listings_clean.id` and `reviews_clean.id`
- performs row-count and null checks after cleaning

**Important:** This script recreates the clean tables. It should only be rerun when the raw tables have been correctly loaded or intentionally refreshed.

### `02_neighborhood_revenue.sql`

**Business question:** Which neighborhoods generate the strongest value?

**Grain:** One output row per neighborhood.

**Main calculations:**

- `listing_count`: distinct listings in the neighborhood
- `avg_nightly_price`: average listing price
- `occupancy_rate_pct`: unavailable calendar days divided by calendar days, expressed from 0 to 100
- `estimated_revenue_proxy`: booked or unavailable days multiplied by listing price

The revenue value is a proxy, not official Airbnb revenue. It does not account for cleaning fees, taxes, discounts, cancellations, platform fees, or actual booking prices.

### `03_listing_performance.sql`

**Business question:** Which room and property types provide the strongest mix of price, occupancy, quality, and revenue efficiency?

**Grain:** One output row per `room_type` and `property_type` combination.

**Main calculations:**

- distinct listing count
- average nightly price
- average review score
- occupancy rate from calendar availability
- revenue per listing proxy

The query uses a left join from `listings_clean` to `calendar_clean`, then groups by room and property type. It returns the top 15 combinations by revenue per listing proxy and occupancy.

**Price-scope note:** This query does not filter out listings where `price` is null before counting listings or calculating calendar occupancy. SQL averages naturally ignore null prices, but listing counts and occupancy can still include listings without a usable price. This is intentional for a broader performance view and is the reason its percentages should not be compared directly with the Python market overview percentages.

### `04_host_market_insights.sql`

**Business question:** Do superhosts perform differently from regular hosts?

**Grain:** One output row per host status.

**Main calculations:**

- listing count
- average nightly price
- average review score
- average response rate
- occupancy rate from calendar availability
- estimated revenue proxy

Rows with an unknown superhost flag are excluded from the final result. The output compares known superhosts and regular hosts.

### `room_level_analysis.sql`

**Purpose:** Provide a simpler room-type summary.

**Grain:** One row per room type.

**Main calculations:**

- listing count
- average nightly price
- median nightly price
- occupancy rate

This is useful for a simple room-type chart or Excel comparison table.

### `property_level_analysis.sql`

**Purpose:** Provide property-type detail with a minimum sample-size rule.

**Grain:** One row per room type and property type.

Only combinations with at least 15 distinct listings are included. This prevents very rare property types from appearing as misleading leaders.

### `06_powerbi_listing_export.sql`

**Purpose:** Create one denormalized CSV source for an interactive Power BI dashboard when PostgreSQL views cannot be used because of storage constraints.

**Grain:** One row per listing.

The export combines listing attributes with calendar totals:

- listing ID
- neighborhood
- room type
- property type
- host segment
- nightly price
- review score
- capacity fields
- calendar days
- booked days
- occupancy rate
- estimated revenue proxy
- calendar date range

This single-table approach allows Power BI slicers and visuals to interact without relationships between separate aggregated CSVs.

## 4. Python Notebooks

### `00_data_verification.ipynb`

**Purpose:** Confirm that the database structure and data types are usable before cleaning and analysis.

Checks include:

- table row counts
- schema and column types
- duplicate keys
- null rates for suspicious columns
- sample values for prices, dates, IDs, and booleans
- calendar date coverage and availability fields
- review date and comment fields

This notebook is a diagnostic guardrail, not a dashboard or final business analysis.

### `01_market_overview.ipynb`

**Purpose:** Explain the overall Paris market.

Outputs include:

- total listing count used in the market summary
- average and median nightly price
- average review score
- room-type price and occupancy comparison
- neighborhood occupancy comparison
- charts for room-type price and neighborhood occupancy

The notebook uses PostgreSQL aggregations rather than loading the full calendar into pandas.

**Price-scope note:** The market overview filters to `price IS NOT NULL AND price > 0`. Therefore its listing population is smaller and cleaner for price analysis than SQL query 03, which keeps listings without prices in its broader performance population. This explains why occupancy percentages can differ. The Excel note should be retained wherever those results are compared.

### `02_pricing_and_amenities.ipynb`

**Purpose:** Explore which listing characteristics are associated with higher nightly prices. Despite the historical filename, the current notebook does not analyze amenities.

The current analysis compares:

- room type
- bedroom count
- guest capacity
- average nightly price
- listing volume

Amenities are not part of the implemented analysis because no amenity parsing or amenity-level comparison was completed.

Small groups are excluded from the detailed segment table to reduce the risk of treating one unusual luxury listing as a general market pattern.

### `03_neighborhood_and_host_analysis.ipynb`

**Purpose:** Compare neighborhood pricing and host segments.

The notebook presents:

- neighborhood price comparisons
- listing volume by neighborhood
- listing-level occupancy proxy
- host segment pricing
- host segment review quality
- host segment occupancy proxy

It is designed for explanatory charts and recommendations rather than database preparation.

## 5. Metric Definitions

### Occupancy rate

For calendar-based SQL analysis:

```text
unavailable or booked calendar days / total calendar days
```

The SQL outputs express this as a number from 0 to 100, such as `62.54`.

For Power BI percentage formatting, the single-table export stores the value as a decimal fraction, such as `0.6254`, so Power BI displays it as `62.54%`.

### Occupancy proxy

The Python listing-level overview may use listing availability fields such as `availability_365`. This is a listing-level proxy and is not identical to a weighted calendar calculation.

### Estimated revenue proxy

```text
booked or unavailable days * nightly price
```

This is a comparative estimate. It must not be described as confirmed revenue.

### Average nightly price

The average of valid positive listing prices in the relevant population. Null prices are ignored by the average function, but they may still affect counts in SQL queries that do not explicitly filter them.

## 6. Excel and Power BI Scope

### Excel

Excel is the quick summary layer. It is suitable for:

- KPI cards
- neighborhood ranking
- room-type comparison
- occupancy explanation
- host quality summary

The Excel note should explain that SQL query 03 includes listings without price while the Python market overview filters to positive prices. These different populations can produce different percentages.

### Power BI

The current Power BI workflow uses the exported `powerbi_listings.csv` created by `06_powerbi_listing_export.sql`, because loading the large PostgreSQL views is not practical with the available disk space. The PostgreSQL views remain documented SQL alternatives, but they are not required for the current dashboard.

The single listing-level CSV is the practical interactive fallback because all slicers and visuals read from one table. It avoids relationship problems between separate aggregated CSV files.

Recommended Power BI pages:

1. Introduction and navigation
2. Main market dashboard
3. Neighborhood drill-through dashboard

## 7. Interpretation Rules

- Do not compare percentages from different scopes without checking their filters and denominator.
- Do not call the revenue proxy actual revenue.
- Do not treat very small property-type groups as reliable leaders.
- Do not join calendar and reviews directly at detail level.
- Keep the raw data unchanged and perform transformations in the clean layer or export query.
- For interactive Power BI CSV work, prefer one denormalized listing-level export over several unrelated summary CSVs.

## 8. Reproducible Workflow

1. Load the raw CSV files into PostgreSQL.
2. Run `00_data_verification.ipynb` or the equivalent SQL checks.
3. Run `01_data_cleaning.sql` after confirming the raw tables are correct.
4. Run the four business SQL analyses.
5. Run `06_powerbi_listing_export.sql` when a single interactive Power BI CSV is needed.
6. Build Excel summaries using the documented scope of each output.
7. Import the final CSV or validated PostgreSQL views into Power BI.
8. Refresh only when the source data is intentionally updated.

This workflow keeps the project understandable, reproducible, and consistent across SQL, Python, Excel, and Power BI.
