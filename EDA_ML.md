# Python EDA — E-Commerce Delivery Analytics

In this EDA, I connect to my SQL Server database and pull the **Gold feature view** (`gold.vw_order_delivery_features_v4`) into Python to explore late delivery behavior, validate feature quality, and generate insights for dashboarding and machine learning.

---

## What I Analyzed
- **Dataset source:** `gold.vw_order_delivery_features_v4` (SQL Server)
- **Unit of analysis:** 1 row = 1 delivered order
- **Primary target:** `is_late` (1 = delivered after estimated date, else 0)


## EDA Workflow (What I Did)

### 1) Dataset profiling
- I inspected schema and types (`df.info()`), checked missingness, and validated uniqueness.
- I verified the grain is correct by confirming there are **0 duplicate `order_id`s**.

### 2) Missing value handling
- I computed missingness across all features.
- I treated missing `top_category` as `"Unknown"` to avoid dropping valid orders:
```python
df["top_category"] = df["top_category"].fillna("Unknown")
```

### 3) Target understanding (late delivery)
- I computed the overall late delivery rate and the late vs on-time class counts.

### 4) Distribution analysis + outliers
- I plotted distributions for key timing features:
  - `days_to_deliver`
  - `days_to_ship`
  - `days_carrier_to_customer`
  - `delay_days` / `late_days`
- I used clipped plots (e.g., 99th percentile) so the “typical” distribution is visible even when long tails exist.

### 5) Trend analysis (time series)
- I grouped by purchase month to measure:
  - monthly order volume
  - monthly late rate
  - monthly average delivery time

### 6) Segment analysis (state + category)
- I compared late rates by:
  - `customer_state`
  - `top_category`
- I applied a minimum sample size filter (e.g., `MIN_N=200`) to avoid misleading small-sample spikes.

### 7) Driver analysis (relationships)
- I compared numeric features across late vs on-time orders (boxplots).
- I computed correlations between numeric features and `is_late` to surface likely drivers.

---

## Key Findings & Insights

### Dataset grain + size
- The dataset contains **96,386 rows and 30 columns**.
- The grain is clean: **one row per delivered order** (no duplicated `order_id`).

### Data completeness
- Most features are complete.
- `top_category` is missing for **1,378 orders (~1.4%)** — I keep these as `"Unknown"`.
- Review metrics are missing for a small subset (likely orders without reviews).

### Late delivery rate
- Overall late rate is **~8.1%**.
- **Interpretation:** this is a moderately imbalanced classification problem, so accuracy alone will be misleading for ML.

### Delivery performance (pipeline timing)
- Average delivery time (`days_to_deliver`) is about **12.5 days**.
- The largest average stage is often **carrier → customer** (`days_carrier_to_customer`), suggesting last-mile time is a key contributor to lateness.

### Outliers and anomaly flags
- `delay_days` spans from very early deliveries to very late deliveries.
- I observed rare impossible values (e.g., negative shipping durations), indicating timestamp inconsistencies in a small number of rows.
- **Interpretation:** I will cap/flag extreme anomalies before training a model.

### Time trends
- Late rate varies month-to-month, suggesting seasonality or operational drift.
- **Interpretation:** model evaluation should use time-aware splits to avoid leakage.

### Geography and category risk
- Late rates differ meaningfully by **state**, indicating geographic delivery risk hotspots.
- Late rates vary by **top_category**, indicating product mix can influence delivery risk.
- **Interpretation:** state and category are important features for both dashboard segmentation and ML.

### What appears to drive late deliveries
- Time-based logistics features (`days_to_deliver`, `days_carrier_to_customer`, `delay_days`) are much more associated with late deliveries than spend features (`total_price`, `total_freight`).
- **Interpretation:** lateness is primarily explained by operational timing rather than order value.

---

