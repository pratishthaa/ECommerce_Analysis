# SQL Outputs & Insights Log — Olist E-Commerce (SQL Server)

I have documented the key **SQL checks, outputs, and insights** generated before running Python EDA / ML and building Power BI dashboard.  
This is to keep a clear record of **data quality**, **join integrity**, and **feature readiness**.

---

## Dataset Tables

| File / Table | Row Count |
|---|---:|
| `olist_customers_dataset` | 99,441 |
| `olist_geolocation_dataset` | 1,000,163 |
| `olist_order_items_dataset` | 112,650 |
| `olist_order_payments_dataset` | 103,886 |
| `olist_order_reviews_dataset` | 99,224 |
| `olist_orders_dataset` | 99,441 |
| `olist_products_dataset` | 32,951 |
| `olist_sellers_dataset` | 3,095 |
| `product_category_name_translation` | (not provided) |

---

### 1) Reviews table key behavior
- **`review_id` is not unique** (often appears twice).
- Some **orders have multiple review rows** (typically **2–3** in the cases checked).

**Interpretation**
- The reviews dataset should be treated as a **one-to-many** relationship with orders.
- For analytics/ML features, reviews must be **aggregated to the order level** (e.g., max review score, latest review, count of reviews) before joining to the main order table.

---

### 2) Missing values in `olist_orders_dataset` timestamps
Output from missing timestamp query:

| missing_purchase_ts | missing_approved_ts | missing_delivered_carrier_ts | missing_delivered_customer_ts | missing_estimated_delivery_ts |
|---:|---:|---:|---:|---:|
| 0 | 160 | 1783 | 2965 | 0 |

**Interpretation**
- `order_purchase_timestamp` and `order_estimated_delivery_date` are complete (0 missing), which is great for defining the late-delivery target.
- Missing `delivered_customer_date` likely indicates **canceled/unfulfilled orders** or orders not completed at the time of snapshot.  
  These rows should be **excluded from supervised training** where the target requires actual delivery.
- Missing `approved_at` and `delivered_carrier_date` are smaller but still relevant; these fields can be optional features depending on model design.

---

### 3) Date validity issue detected
Query: `order_delivered_carrier_date > order_delivered_customer_date`

- **Invalid rows found:** 23

**Interpretation**
- These are timestamp logic errors (carrier delivery date occurring after customer delivery date).
- ### Timestamp integrity issue (carrier date after customer delivery)
- Delivered orders (non-null delivered date): **96,470**
- Share of delivered orders affected: **0.000238 (~0.024%)**

**Decision**
- Treat these 23 rows as timestamp errors and exclude them from the analytics layer used for delivery-time features and ML training.
