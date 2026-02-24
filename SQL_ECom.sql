/* =============================================================================
   Olist E-Commerce Project — SQL Data Quality, Silver/Gold Layer, and Insights
   Author: (you)
   Database: SQL Server (SSMS 2022)
   Notes:
   - This script includes the SQL I used so far + key outputs recorded as comments.
   - Table names assumed to match Kaggle imports under dbo.* as used below.
   - Schemas created: silver, gold
============================================================================= */

-- =========================
-- 0) Create schemas
-- =========================
CREATE SCHEMA silver AUTHORIZATION dbo;
GO
CREATE SCHEMA gold AUTHORIZATION dbo;
GO

/* =============================================================================
   1) Row counts (sanity check)
   Output you recorded (in zip order):
   customers: 99,441
   geolocation: 1,000,163
   order_items: 112,650
   order_payments: 103,886
   order_reviews: 99,224
   orders: 99,441
   products: 32,951
   sellers: 3,095
============================================================================= */
SELECT 'olist_customers_dataset' AS table_name, COUNT(*) AS row_count FROM dbo.olist_customers_dataset
UNION ALL SELECT 'olist_geolocation_dataset', COUNT(*) FROM dbo.olist_geolocation_dataset
UNION ALL SELECT 'olist_order_items_dataset', COUNT(*) FROM dbo.olist_order_items_dataset
UNION ALL SELECT 'olist_order_payments_dataset', COUNT(*) FROM dbo.olist_order_payments_dataset
UNION ALL SELECT 'olist_order_reviews_dataset', COUNT(*) FROM dbo.olist_order_reviews_dataset
UNION ALL SELECT 'olist_orders_dataset', COUNT(*) FROM dbo.olist_orders_dataset
UNION ALL SELECT 'olist_products_dataset', COUNT(*) FROM dbo.olist_products_dataset
UNION ALL SELECT 'olist_sellers_dataset', COUNT(*) FROM dbo.olist_sellers_dataset
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM dbo.product_category_name_translation;
GO

-- =========================
-- 2) Key uniqueness checks
-- =========================
-- Orders: order_id should be unique
SELECT order_id, COUNT(*) AS c
FROM dbo.olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;
GO

-- Customers: customer_id should be unique
SELECT customer_id, COUNT(*) AS c
FROM dbo.olist_customers_dataset
GROUP BY customer_id
HAVING COUNT(*) > 1;
GO

-- Products: product_id should be unique
SELECT product_id, COUNT(*) AS c
FROM dbo.olist_products_dataset
GROUP BY product_id
HAVING COUNT(*) > 1;
GO

-- Sellers: seller_id should be unique
SELECT seller_id, COUNT(*) AS c
FROM dbo.olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1;
GO

-- Order items: (order_id, order_item_id) should be unique
SELECT order_id, order_item_id, COUNT(*) AS c
FROM dbo.olist_order_items_dataset
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
GO

-- Payments: (order_id, payment_sequential) should be unique
SELECT order_id, payment_sequential, COUNT(*) AS c
FROM dbo.olist_order_payments_dataset
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;
GO

/* Reviews:
   - You observed review_id is NOT unique (often appears twice).
   - Some orders have 2–3 review rows.
*/
SELECT review_id, COUNT(*) AS c
FROM dbo.olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1;
GO

SELECT TOP 25
  order_id,
  COUNT(*) AS reviews_per_order
FROM dbo.olist_order_reviews_dataset
GROUP BY order_id
ORDER BY reviews_per_order DESC;
GO

-- =========================
-- 3) Missing timestamps (orders)
-- =========================
/* Output you recorded:
   missing_purchase_ts = 0
   missing_approved_ts = 160
   missing_delivered_carrier_ts = 1783
   missing_delivered_customer_ts = 2965
   missing_estimated_delivery_ts = 0
*/
SELECT
  SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_purchase_ts,
  SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS missing_approved_ts,
  SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS missing_delivered_carrier_ts,
  SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS missing_delivered_customer_ts,
  SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS missing_estimated_delivery_ts
FROM dbo.olist_orders_dataset;
GO

-- =========================
-- 4) Timestamp sanity checks
-- =========================
-- Delivered before purchase
SELECT COUNT(*) AS invalid_rows
FROM dbo.olist_orders_dataset
WHERE order_delivered_customer_date < order_purchase_timestamp;
GO

-- Carrier after customer delivery
/* You observed 23 rows */
SELECT COUNT(*) AS invalid_rows
FROM dbo.olist_orders_dataset
WHERE order_delivered_carrier_date > order_delivered_customer_date;
GO

-- Inspect those rows
SELECT TOP 50
  order_id,
  customer_id,
  order_status,
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date,
  order_estimated_delivery_date
FROM dbo.olist_orders_dataset
WHERE order_delivered_carrier_date > order_delivered_customer_date
ORDER BY order_purchase_timestamp;
GO

-- Quantify impact (delivered_orders, invalid_carrier_after_customer, pct_invalid)
/* Output you recorded:
   delivered_orders = 96470
   invalid_carrier_after_customer = 23
   pct_invalid = 0.000238  (~0.024%)
*/
SELECT
  COUNT(*) AS delivered_orders,
  SUM(CASE WHEN order_delivered_carrier_date > order_delivered_customer_date THEN 1 ELSE 0 END) AS invalid_carrier_after_customer,
  CAST(1.0 * SUM(CASE WHEN order_delivered_carrier_date > order_delivered_customer_date THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(10,6)) AS pct_invalid
FROM dbo.olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
GO

-- Additional sanity checks you ran (all returned 0 except delivered-before-approved)
-- Estimated delivery before purchase
SELECT COUNT(*) AS invalid_rows
FROM dbo.olist_orders_dataset
WHERE order_estimated_delivery_date < order_purchase_timestamp;
GO

-- Approved before purchase
SELECT COUNT(*) AS invalid_rows
FROM dbo.olist_orders_dataset
WHERE order_approved_at IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;
GO

-- Delivered before approved  (you observed 61 rows)
SELECT COUNT(*) AS invalid_rows
FROM dbo.olist_orders_dataset
WHERE order_approved_at IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date < order_approved_at;
GO

-- =========================
-- 5) Join integrity checks (you ran these and got 0 across them)
-- =========================
SELECT COUNT(*) AS orders_missing_customer
FROM dbo.olist_orders_dataset o
LEFT JOIN dbo.olist_customers_dataset c
  ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;
GO

SELECT COUNT(*) AS delivered_orders_missing_items
FROM dbo.olist_orders_dataset o
LEFT JOIN dbo.olist_order_items_dataset oi
  ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND oi.order_id IS NULL;
GO

SELECT COUNT(*) AS items_missing_product
FROM dbo.olist_order_items_dataset oi
LEFT JOIN dbo.olist_products_dataset p
  ON p.product_id = oi.product_id
WHERE p.product_id IS NULL;
GO

SELECT COUNT(*) AS items_missing_seller
FROM dbo.olist_order_items_dataset oi
LEFT JOIN dbo.olist_sellers_dataset s
  ON s.seller_id = oi.seller_id
WHERE s.seller_id IS NULL;
GO

-- =========================
-- 6) Silver: Clean delivered orders view (filters timestamp anomalies)
-- =========================
CREATE OR ALTER VIEW silver.vw_orders_delivered_clean AS
SELECT *
FROM dbo.olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL

  -- Remove carrier-after-customer errors (23)
  AND (
        order_delivered_carrier_date IS NULL
        OR order_delivered_carrier_date <= order_delivered_customer_date
      )

  -- Remove delivered-before-approved errors (61)
  AND (
        order_approved_at IS NULL
        OR order_approved_at <= order_delivered_customer_date
      );
GO

-- =========================
-- 7) Silver: Order-level aggregates (items, payments, reviews)
-- =========================
CREATE OR ALTER VIEW silver.vw_items_by_order AS
SELECT
  order_id,
  COUNT(*) AS items_count,
  COUNT(DISTINCT product_id) AS distinct_products,
  COUNT(DISTINCT seller_id) AS distinct_sellers,
  SUM(price) AS total_price,
  SUM(freight_value) AS total_freight
FROM dbo.olist_order_items_dataset
GROUP BY order_id;
GO

CREATE OR ALTER VIEW silver.vw_payments_by_order AS
SELECT
  order_id,
  COUNT(*) AS payment_rows,
  SUM(payment_value) AS total_payment_value,
  MAX(payment_installments) AS max_installments
FROM dbo.olist_order_payments_dataset
GROUP BY order_id;
GO

CREATE OR ALTER VIEW silver.vw_reviews_by_order AS
SELECT
  order_id,
  COUNT(*) AS review_rows,
  AVG(CAST(review_score AS FLOAT)) AS avg_review_score,
  MAX(review_score) AS max_review_score,
  MIN(review_score) AS min_review_score,
  MAX(review_creation_date) AS latest_review_creation_date
FROM dbo.olist_order_reviews_dataset
GROUP BY order_id;
GO

-- =========================
-- 8) Gold: Base feature view (EDA + ML + Power BI)
-- =========================
CREATE OR ALTER VIEW gold.vw_order_delivery_features AS
SELECT
  o.order_id,
  o.customer_id,
  o.order_purchase_timestamp,
  o.order_delivered_carrier_date,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,

  CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_late,

  DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date) AS days_to_deliver,
  DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_carrier_date) AS days_to_ship,
  DATEDIFF(day, o.order_delivered_carrier_date, o.order_delivered_customer_date) AS days_carrier_to_customer,

  c.customer_city,
  c.customer_state,

  i.items_count,
  i.distinct_products,
  i.distinct_sellers,
  i.total_price,
  i.total_freight,

  p.payment_rows,
  p.total_payment_value,
  p.max_installments,

  r.review_rows,
  r.avg_review_score,
  r.max_review_score

FROM silver.vw_orders_delivered_clean o
JOIN dbo.olist_customers_dataset c ON c.customer_id = o.customer_id
LEFT JOIN silver.vw_items_by_order i ON i.order_id = o.order_id
LEFT JOIN silver.vw_payments_by_order p ON p.order_id = o.order_id
LEFT JOIN silver.vw_reviews_by_order r ON r.order_id = o.order_id;
GO

-- Validate Gold metrics
/* Output you recorded:
   rows = 96386
   late_rate = 0.0811736144253315  (~8.12%)
   avg_days_to_deliver = 12.5035378581952
   avg_order_value = 137.048575747861
*/
SELECT
  COUNT(*) AS rows,
  AVG(CAST(is_late AS FLOAT)) AS late_rate,
  AVG(CAST(days_to_deliver AS FLOAT)) AS avg_days_to_deliver,
  AVG(CAST(total_price AS FLOAT)) AS avg_order_value
FROM gold.vw_order_delivery_features;
GO

-- Ensure no duplicate order_ids in Gold
SELECT order_id, COUNT(*) AS c
FROM gold.vw_order_delivery_features
GROUP BY order_id
HAVING COUNT(*) > 1;
GO

-- Spot check
SELECT TOP 20 *
FROM gold.vw_order_delivery_features
ORDER BY order_purchase_timestamp;
GO

-- =========================
-- 9) Gold: Delay severity features (v2)
-- =========================
CREATE OR ALTER VIEW gold.vw_order_delivery_features_v2 AS
SELECT
  f.*,
  DATEDIFF(day, f.order_estimated_delivery_date, f.order_delivered_customer_date) AS delay_days,
  CASE
    WHEN DATEDIFF(day, f.order_estimated_delivery_date, f.order_delivered_customer_date) > 0
    THEN DATEDIFF(day, f.order_estimated_delivery_date, f.order_delivered_customer_date)
    ELSE 0
  END AS late_days
FROM gold.vw_order_delivery_features f;
GO

/* Output you recorded:
   min_delay = -147
   max_delay = 188
   avg_delay = -11.8735604755877
*/
SELECT
  MIN(delay_days) AS min_delay,
  MAX(delay_days) AS max_delay,
  AVG(CAST(delay_days AS FLOAT)) AS avg_delay
FROM gold.vw_order_delivery_features_v2;
GO

/* Outlier quantification output you recorded:
   very_late_60plus = 84
   extreme_late_120plus = 26
   very_early_60plus = 35
   extreme_early_120plus = 4
*/
SELECT
  SUM(CASE WHEN delay_days >= 60 THEN 1 ELSE 0 END) AS very_late_60plus,
  SUM(CASE WHEN delay_days >= 120 THEN 1 ELSE 0 END) AS extreme_late_120plus,
  SUM(CASE WHEN delay_days <= -60 THEN 1 ELSE 0 END) AS very_early_60plus,
  SUM(CASE WHEN delay_days <= -120 THEN 1 ELSE 0 END) AS extreme_early_120plus
FROM gold.vw_order_delivery_features_v2;
GO

-- =========================
-- 10) Gold: Add time features (v3)
-- =========================
CREATE OR ALTER VIEW gold.vw_order_delivery_features_v3 AS
SELECT
  v2.*,
  DATENAME(weekday, order_purchase_timestamp) AS purchase_weekday,
  DATEPART(weekday, order_purchase_timestamp) AS purchase_weekday_num,
  DATEPART(month, order_purchase_timestamp) AS purchase_month,
  DATEPART(year, order_purchase_timestamp) AS purchase_year
FROM gold.vw_order_delivery_features_v2 v2;
GO

-- =========================
-- 11) Silver: Category features (top category per order)
-- =========================
CREATE OR ALTER VIEW silver.vw_order_category_counts AS
SELECT
  oi.order_id,
  p.product_category_name,
  COUNT(*) AS items_in_category
FROM dbo.olist_order_items_dataset oi
JOIN dbo.olist_products_dataset p
  ON p.product_id = oi.product_id
GROUP BY oi.order_id, p.product_category_name;
GO

CREATE OR ALTER VIEW silver.vw_order_top_category AS
WITH x AS (
  SELECT
    order_id,
    product_category_name,
    items_in_category,
    ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY items_in_category DESC, product_category_name) AS rn
  FROM silver.vw_order_category_counts
)
SELECT
  order_id,
  product_category_name AS top_category
FROM x
WHERE rn = 1;
GO

-- =========================
-- 12) Gold: Category-augmented feature view (v4)
-- =========================
CREATE OR ALTER VIEW gold.vw_order_delivery_features_v4 AS
SELECT
  v3.*,
  tc.top_category
FROM gold.vw_order_delivery_features_v3 v3
LEFT JOIN silver.vw_order_top_category tc
  ON tc.order_id = v3.order_id;
GO

-- Null checks for key fields (you recorded top_category nulls)
/* Output you recorded:
   null_total_price = 0
   null_total_freight = 0
   null_items_count = 0
   null_top_category = 1378
*/
SELECT
  SUM(CASE WHEN total_price IS NULL THEN 1 ELSE 0 END) AS null_total_price,
  SUM(CASE WHEN total_freight IS NULL THEN 1 ELSE 0 END) AS null_total_freight,
  SUM(CASE WHEN items_count IS NULL THEN 1 ELSE 0 END) AS null_items_count,
  SUM(CASE WHEN top_category IS NULL THEN 1 ELSE 0 END) AS null_top_category
FROM gold.vw_order_delivery_features_v4;
GO

-- Late rate by category (top 20) — your output included NULL category row (1378 orders)
SELECT TOP 20
  top_category,
  COUNT(*) AS orders,
  AVG(CAST(is_late AS FLOAT)) AS late_rate,
  AVG(CAST(late_days AS FLOAT)) AS avg_late_days
FROM gold.vw_order_delivery_features_v4
GROUP BY top_category
ORDER BY late_rate DESC, orders DESC;
GO

-- Late rate by state (top 15)
SELECT TOP 15
  customer_state,
  COUNT(*) AS orders,
  AVG(CAST(is_late AS FLOAT)) AS late_rate,
  AVG(CAST(late_days AS FLOAT)) AS avg_late_days
FROM gold.vw_order_delivery_features_v4
GROUP BY customer_state
ORDER BY late_rate DESC, orders DESC;
GO

-- Optional: eliminate NULL categories without dropping rows
-- CREATE OR ALTER VIEW gold.vw_order_delivery_features_v4 AS
-- SELECT v3.*, COALESCE(tc.top_category, 'Unknown') AS top_category
-- FROM gold.vw_order_delivery_features_v3 v3
-- LEFT JOIN silver.vw_order_top_category tc ON tc.order_id = v3.order_id;
-- GO
