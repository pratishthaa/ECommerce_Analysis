# ECommerce_Analysis

# SQL Outputs & Insights Log (Olist / E-commerce Project)

This file documents the key **SQL-based checks, outputs, and insights** generated during the data preparation phase (Bronze → Silver → Gold).  
Goal: keep a clear audit trail of what was validated in SQL before moving to Python EDA / ML / Power BI.

---

## Project Context
- **Database:** SQL Server (SSMS 2022)
- **Schema(s):** `dbo` (raw), `silver` (clean), `gold` (analytics)
- **Dataset:** Olist Brazilian E-Commerce (Kaggle)

---

## Table Inventory
List the tables you loaded (raw):
- `dbo.orders`
- `dbo.order_items`
- `dbo.customers`
- `dbo.products`
- `dbo.sellers`
- `dbo.payments`
- `dbo.reviews`
- `dbo.geolocation`

> Add/remove based on what you have.

---

## 1) Row Counts (Sanity Check)

### Query
```sql
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM dbo.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM dbo.order_items
UNION ALL SELECT 'customers', COUNT(*) FROM dbo.customers;
