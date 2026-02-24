# SQL Outputs & Insights Log — Olist E-Commerce (SQL Server)

I have documented the key **SQL checks, outputs, and insights** generated before running Python EDA / ML and building Power BI dashboard.  
This is to keep a clear record of **data quality**, **join integrity**, and **feature readiness**.

---

## Dataset Tables (Loaded from Zip)

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

# 1) Row Count Sanity Check

```sql
SELECT 'olist_customers_dataset' AS table_name, COUNT(*) AS row_count FROM dbo.olist_customers_dataset
UNION ALL SELECT 'olist_geolocation_dataset', COUNT(*) FROM dbo.olist_geolocation_dataset
UNION ALL SELECT 'olist_order_items_dataset', COUNT(*) FROM dbo.olist_order_items_dataset
UNION ALL SELECT 'olist_order_payments_dataset', COUNT(*) FROM dbo.olist_order_payments_dataset
UNION ALL SELECT 'olist_order_reviews_dataset', COUNT(*) FROM dbo.olist_order_reviews_dataset
UNION ALL SELECT 'olist_orders_dataset', COUNT(*) FROM dbo.olist_orders_dataset
UNION ALL SELECT 'olist_products_dataset', COUNT(*) FROM dbo.olist_products_dataset
UNION ALL SELECT 'olist_sellers_dataset', COUNT(*) FROM dbo.olist_sellers_dataset
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM dbo.product_category_name_translation;
