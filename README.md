# E-Commerce Delivery Analysis (Excel → SQL → Python EDA/Model → Power BI)

<p align="center">
  <img src="logo.png" alt="Project logo" width="540"/>
</p>

This project is an end-to-end analytics case study on e-commerce order delivery performance. I started with quick exploratory checks in Excel, then built a clean analytics layer in SQL Server, performed deeper EDA + baseline modeling in Python, and finally created a Power BI dashboard to communicate insights.

**Repo:** https://github.com/pratishthaa/ECommerce_Analysis

---

## What I built
### 1) Excel (initial analysis)
- Performed quick sanity checks and early exploration to understand delivery dates, delays, and basic distributions.
- Identified the key outcome to analyze: **late delivery** (delivered after estimated date).

### 2) SQL Server (data modeling + quality checks)
- Imported the raw dataset tables into SQL Server.
- Ran data quality checks (missing values, timestamp consistency, join integrity).
- Created a **Gold analytics view** at the *order level* to support analysis and dashboarding:
  - `gold.vw_order_delivery_features_v4`

### 3) Python (EDA + baseline ML)
- Connected Python to SQL Server and pulled the Gold view into pandas.
- Performed EDA:
  - late rate trends over time
  - state and category hotspots
  - delivery pipeline timing (ship vs carrier-to-customer)
  - outlier inspection and data sanity checks
- Built baseline models to predict late delivery risk and evaluated with imbalance-aware metrics (PR-AUC, lift/top-K style evaluation).
- Compared imbalance strategies (class weighting vs downsampling) and confirmed class weighting was more stable for this dataset.

### 4) Power BI (dashboard)
- Built a 4-page dashboard:
  - **Home** (navigation)
  - **Delivery Pipeline** (where delays occur)
  - **Segmentation** (state/category hotspots)
  - **Summary** (executive KPIs and trends)
- Used measures such as late rate, on-time rate, percentile delivery times, and review coverage to make the dashboard informative and decision-ready.

---

## Key insights (high level)
- Late deliveries are a minority but meaningful share of orders (imbalanced outcome).
- Delivery time is largely driven by the **carrier → customer** stage.
- Late rate varies by **month**, **state**, and **product category**, creating clear hotspots for monitoring.
- For modeling, ranking-style evaluation (e.g., top-risk segments / lift) is more useful than accuracy alone.

---

## Files in this repo
- `*.ipynb` — Python EDA and modeling notebooks  
- `*.sql` — SQL scripts for data quality checks and view creation  
- `*.pbix` — Power BI dashboard file  
- `README_*.md` — supporting documentation (SQL/EDA notes)

---

## How to run
1. Load raw tables into SQL Server
2. Run SQL scripts to create the Gold view (`gold.vw_order_delivery_features_v4`)
3. Run the Python notebooks for EDA/modeling
4. Connect Power BI to SQL Server and load the Gold view to reproduce the dashboard
