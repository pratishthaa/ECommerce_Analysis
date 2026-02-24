# Olist E‑Commerce — SQL Outputs & Insights

This file is the documentation of insights I collected over what I validated and learned in SQL Server.

---

## What I loaded into SQL Server
I imported the Olist dataset into SQL Server (`dbo.*`) and confirmed ingestion completeness using row counts:

- Customers: 99,441  
- Geolocation: 1,000,163  
- Order Items: 112,650  
- Payments: 103,886  
- Reviews: 99,224  
- Orders: 99,441  
- Products: 32,951  
- Sellers: 3,095  

---

## Data quality checks I ran (and what I found)

### Keys + relationship structure
- `order_id`, `customer_id`, `product_id`, `seller_id` behave as unique identifiers in their respective tables.
- Composite keys worked as expected for:
  - order items: (`order_id`, `order_item_id`)
  - payments: (`order_id`, `payment_sequential`)

**Important finding:** `review_id` is *not unique* (often appears twice) and some orders have **2–3** review rows.  
**What I did:** I treated reviews as **one‑to‑many** and aggregated them to the order level before joining.

---

### Missing timestamps (orders)
I checked for missingness in order lifecycle timestamps:

- missing_purchase_ts = 0  
- missing_approved_ts = 160  
- missing_delivered_carrier_ts = 1783  
- missing_delivered_customer_ts = 2965  
- missing_estimated_delivery_ts = 0  

**Interpretation**
- Purchase + estimated delivery are complete, so I can safely define lateness using delivered vs. estimated date.
- Missing delivery timestamps likely represent canceled/unfulfilled orders; I exclude these from “delivered-only” modeling/metrics.

---

### Timestamp integrity
I checked for impossible timestamp sequences:

- `order_delivered_carrier_date > order_delivered_customer_date`: **23 rows**  
  - Out of delivered orders, this is **0.000238 (~0.024%)** — very small but worth filtering.
- `order_delivered_customer_date < order_approved_at`: **61 rows**  
  - Also invalid for a standard order lifecycle.

**Decision:** I filtered these anomalies out in my Silver clean view rather than guessing corrections.

---

### Join integrity
All join integrity checks returned **0 missing links**, meaning:
- Orders join to customers cleanly
- Delivered orders join to order items cleanly
- Order items join to products and sellers cleanly

This minimized risk of silent row loss when building my analytics dataset.

---

## Silver/Gold layering approach

### Silver (clean + safe joins)
I created:
- `silver.vw_orders_delivered_clean` — delivered orders only, excluding the 23 + 61 timestamp anomalies
- `silver.vw_items_by_order` — order totals and basket composition
- `silver.vw_payments_by_order` — order-level payment totals
- `silver.vw_reviews_by_order` — order-level review aggregations

This prevents row duplication when joining one‑to‑many tables.

---

### Gold (features for Python EDA + ML + Power BI)
I created `gold.vw_order_delivery_features` and validated:

- Clean delivered orders: **96,386**
- Late delivery rate: **0.08117 (~8.12%)**
- Average delivery time: **12.50 days**
- Average order value (items total): **137.05**

**Interpretation**
- Late deliveries are a meaningful minority class (~8%), suitable for a late‑delivery risk model.
- Delivery time varies a lot; I will handle outliers carefully in Python EDA.

---

## Delay severity insights
I added:
- `delay_days = delivered_date − estimated_delivery_date` (negative = early)
- `late_days = max(delay_days, 0)` (late severity)

Results:
- min delay_days = **-147**
- max delay_days = **188**
- avg delay_days = **-11.87**

**Interpretation**
- On average, deliveries arrive ~11.9 days early (estimated delivery date appears conservative).
- Extreme outliers exist, so I quantified them:
  - delay ≥ 60: **84**
  - delay ≥ 120: **26**
  - delay ≤ -60: **35**
  - delay ≤ -120: **4**

---

## Category + region insights (SQL)

### Category
I engineered a “top category per order” feature and summarized lateness by category.

Highest late rates among the top 20 categories by late_rate included:
- `casa_conforto_2`: 17.39% late (n=23)
- `moveis_colchao_e_estofado`: 13.51% late (n=37)
- `audio`: 12.93% late (n=348)

I found **1,378 orders** where `top_category` is NULL.
**Decision:** keep these orders and treat the category as **Unknown** in BI/ML (rather than dropping them).

### State
States with the highest late rates (top 15):
- AL: 23.93% (n=397)
- MA: 19.67% (n=717)
- PI: 15.97% (n=476)
- CE: 15.34% (n=1,278)
- SE: 15.22% (n=335)

This suggests strong geographic/logistics variation that I will visualize in Power BI and explore statistically in Python.
