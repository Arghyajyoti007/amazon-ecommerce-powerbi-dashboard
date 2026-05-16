-- ============================================
-- DATA QUALITY CHECKS
-- Amazon E-Commerce Sales Dashboard
-- Author: Arghyajyoti Samui
-- Table: orders_partitioned
-- ============================================


-- ─────────────────────────────────────────
-- CHECK 1: Total Row Count
-- Expected: 5000 rows
-- ─────────────────────────────────────────
SELECT COUNT(*) AS total_rows
FROM orders_partitioned;


-- ─────────────────────────────────────────
-- CHECK 2: Null Check — All Critical Columns
-- Expected: 0 nulls in all columns
-- ─────────────────────────────────────────
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)        AS null_order_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END)       AS null_order_date,
    SUM(CASE WHEN ship_date IS NULL THEN 1 ELSE 0 END)        AS null_ship_date,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END)    AS null_customer_name,
    SUM(CASE WHEN segment IS NULL THEN 1 ELSE 0 END)          AS null_segment,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END)             AS null_city,
    SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END)            AS null_state,
    SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END)           AS null_region,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END)         AS null_category,
    SUM(CASE WHEN sub_category IS NULL THEN 1 ELSE 0 END)     AS null_sub_category,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END)     AS null_product_name,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END)            AS null_sales,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END)         AS null_quantity,
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END)         AS null_discount,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END)           AS null_profit
FROM orders_partitioned;


-- ─────────────────────────────────────────
-- CHECK 3: Duplicate Order IDs
-- Expected: 0 duplicates
-- ─────────────────────────────────────────
SELECT
    order_id,
    COUNT(*) AS occurrence
FROM orders_partitioned
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrence DESC;


-- ─────────────────────────────────────────
-- CHECK 4: Date Range Validation
-- Expected: 2021-01-01 to 2024-10-31
-- ─────────────────────────────────────────
SELECT
    MIN(order_date)  AS earliest_order,
    MAX(order_date)  AS latest_order,
    MIN(ship_date)   AS earliest_ship,
    MAX(ship_date)   AS latest_ship
FROM orders_partitioned;


-- ─────────────────────────────────────────
-- CHECK 5: Ship Date Before Order Date
-- Expected: 0 rows (ship cannot precede order)
-- ─────────────────────────────────────────
SELECT
    order_id,
    order_date,
    ship_date
FROM orders_partitioned
WHERE ship_date < order_date;


-- ─────────────────────────────────────────
-- CHECK 6: Negative Sales or Quantity
-- Expected: 0 rows
-- ─────────────────────────────────────────
SELECT
    order_id,
    sales,
    quantity
FROM orders_partitioned
WHERE sales < 0
   OR quantity <= 0;


-- ─────────────────────────────────────────
-- CHECK 7: Discount Out of Valid Range
-- Expected: all values between 0.0 and 1.0
-- ─────────────────────────────────────────
SELECT
    COUNT(*) AS invalid_discount_rows
FROM orders_partitioned
WHERE discount < 0
   OR discount > 1;

-- See all distinct discount values
SELECT DISTINCT discount
FROM orders_partitioned
ORDER BY discount;


-- ─────────────────────────────────────────
-- CHECK 8: Invalid Segment Values
-- Expected: only Consumer, Corporate, Home Office
-- ─────────────────────────────────────────
SELECT
    segment,
    COUNT(*) AS row_count
FROM orders_partitioned
GROUP BY segment
ORDER BY segment;


-- ─────────────────────────────────────────
-- CHECK 9: Invalid Region Values
-- Expected: only East, West, Central, South
-- ─────────────────────────────────────────
SELECT
    region,
    COUNT(*) AS row_count
FROM orders_partitioned
GROUP BY region
ORDER BY region;


-- ─────────────────────────────────────────
-- CHECK 10: Invalid Category Values
-- Expected: Furniture, Technology, Office Supplies
-- ─────────────────────────────────────────
SELECT
    category,
    COUNT(*) AS row_count
FROM orders_partitioned
GROUP BY category
ORDER BY category;


-- ─────────────────────────────────────────
-- CHECK 11: City vs State Mismatch (Known Issue)
-- Flags rows where city-state combination looks suspicious
-- ─────────────────────────────────────────
SELECT
    city,
    state,
    COUNT(*) AS occurrence
FROM orders_partitioned
GROUP BY city, state
ORDER BY city, state;

-- Known mismatch examples found during EDA:
-- Phoenix listed under CA (should be AZ)
-- Los Angeles listed under AZ (should be CA)
SELECT
    order_id,
    city,
    state
FROM orders_partitioned
WHERE (city = 'Phoenix'     AND state != 'AZ')
   OR (city = 'Los Angeles' AND state != 'CA')
   OR (city = 'Houston'     AND state != 'TX')
   OR (city = 'Chicago'     AND state != 'IL')
   OR (city = 'San Diego'   AND state != 'CA');


-- ─────────────────────────────────────────
-- CHECK 12: Partition Completeness
-- Verify all snapshot_day partitions loaded correctly
-- ─────────────────────────────────────────
SELECT
    snapshot_day,
    COUNT(*) AS rows_in_partition
FROM orders_partitioned
GROUP BY snapshot_day
ORDER BY snapshot_day;


-- ─────────────────────────────────────────
-- CHECK 13: Profit vs Sales Sanity Check
-- Profit should not exceed Sales in most cases
-- ─────────────────────────────────────────
SELECT
    order_id,
    sales,
    profit,
    ROUND((profit / NULLIF(sales, 0)) * 100, 2) AS profit_pct_of_sales
FROM orders_partitioned
WHERE profit > sales
ORDER BY profit DESC
LIMIT 20;


-- ─────────────────────────────────────────
-- CHECK 14: Loss Orders Summary
-- How many orders have negative profit
-- ─────────────────────────────────────────
SELECT
    COUNT(*)                                          AS total_orders,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)      AS loss_orders,
    ROUND(
        SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                 AS loss_orders_pct
FROM orders_partitioned;


-- ─────────────────────────────────────────
-- CHECK 15: Data Completeness by Year
-- Ensure all years have reasonable row counts
-- ─────────────────────────────────────────
SELECT
    YEAR(order_date) AS order_year,
    COUNT(*)         AS total_orders,
    MIN(order_date)  AS first_order,
    MAX(order_date)  AS last_order
FROM orders_partitioned
GROUP BY YEAR(order_date)
ORDER BY order_year;
