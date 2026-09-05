# Paris Airbnb Story Map

## Overall project narrative

This project tells a single story across all tools:

Paris Airbnb performance is examined through location, price, occupancy, listing characteristics, host status, and guest review quality. The project compares these factors across neighborhoods, room types, property types, and host segments.

## Story arc

### 1. SQL layer: foundation and KPI logic

Question: Where and how is value being created in Paris Airbnb?

Analyses:
- data quality and cleaning checks
- revenue estimation based on unavailable or booked calendar days × price
- neighborhood comparison using average price, occupancy, revenue proxy, and review score
- listing and host segmentation comparisons

Key outputs:
- cleaned staging tables
- KPI outputs for occupancy, revenue proxy, price, and neighborhood ranking
- listing-level export for interactive Power BI analysis

### 2. Python layer: explanatory market investigation

Question: How do listing type, capacity, and location relate to pricing and performance?

Analyses:
- Paris market overview by room type and neighborhood
- pricing by room type, bedroom count, and guest capacity
- listing-level neighborhood and host comparisons
- host quality and review patterns

Key outputs:
- charts for price and capacity segments
- occupancy and price comparisons
- neighborhood/host comparison visualizations

### 3. Excel layer: quick operational dashboard

Question: What is the easy-to-read market summary for managers or stakeholders?

Analyses:
- top neighborhoods by revenue
- average nightly rate by room type
- occupancy by area
- host quality score and review benchmark

Key outputs:
- compact dashboard with 4–6 charts
- simple filters and summary metrics
- quick comparison views for a business audience

### 4. Power BI layer: investor and traveler decision dashboard

Question: Where should an investor buy or a traveler book next?

Analyses:
- neighborhood price and occupancy comparison
- property and room type comparison
- price versus occupancy analysis
- host segment and review comparison

Key outputs:
- executive dashboard
- dynamic filters for area, room type, price range, and host quality
- narrative for both financial and traveler value

## Proposed chart map

### SQL / data prep
- cleaned table validation summary
- listing and property performance
- neighborhood revenue proxy
- host performance by segment

### Python notebook 1: Market Overview
- market-level price, review, and occupancy summary
- average price by room type
- occupancy proxy by neighborhood

### Python notebook 2: Pricing and Listing Characteristics
- average price by room type
- average price by bedroom count
- guest capacity and price segments

### Python notebook 3: Neighborhood and Host Analysis
- neighborhood price comparison
- host segment price and review comparison
- listing-level occupancy proxy by neighborhood and host segment

### Excel dashboard
- top 10 neighborhoods by revenue
- average price by room type
- occupancy by area
- host quality summary
- simple KPI cards

### Power BI final dashboard
- KPI cards for supply, price, occupancy, and revenue proxy
- average price by room type
- occupancy by neighborhood
- listing mix by room type
- price versus occupancy scatter plot
- neighborhood drill-through with property type, room type, host, and quality comparisons

## Recommended final narrative for the portfolio

The project tells a business story, not just a technical one:

Paris is a very competitive short-term rental market, but not all neighborhoods perform the same. The strongest opportunities combine healthy occupancy, good nightly pricing, and properties that match guest expectations. By combining location analysis, pricing intelligence, host performance, and review quality, we can identify neighborhoods and property types that are attractive for investment and also useful for choosing the right travel option.

This keeps the work both investable and user-friendly.
