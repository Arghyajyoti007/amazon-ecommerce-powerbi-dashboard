-- ============================================
-- ANALYSIS QUERIES
-- Amazon E-Commerce Sales Dashboard
-- Author: Arghyajyoti Samui
-- Table: orders_partitioned
-- ============================================


-- ═══════════════════════════════════════════
-- SECTION 1: REVENUE & PROFIT OVERVIEW
-- Answers BPS 1 — Overall business health
-- ═══════════════════════════════════════════

-- 1.1 Overall Business KPIs
SELECT
    COUNT(DISTINCT order_id)                                    AS total_orders,
    COUNT(DISTINCT customer_name)                               AS total_customers,
    ROUND(SUM(sales), 2)                                        AS total_sales,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct
FROM orders_partitioned;


-- 1.2 Revenue and Profit by Year
SELECT
    YEAR(order_date)                                            AS order_year,
    COUNT(DISTINCT order_id)                                    AS total_orders,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct
FROM orders_partitioned
GROUP BY YEAR(order_date)
ORDER BY order_year;


-- 1.3 Revenue and Profit by Year and Month
SELECT
    YEAR(order_date)                                            AS order_year,
    MONTH(order_date)                                           AS order_month,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit
FROM orders_partitioned
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;


-- 1.4 Like-for-Like Comparison: 2023 vs 2024 (Jan-Oct only)
SELECT
    MONTH(order_date)                                           AS month_number,
    ROUND(SUM(CASE WHEN YEAR(order_date) = 2023 THEN sales * (1 - discount) ELSE 0 END), 2) AS revenue_2023,
    ROUND(SUM(CASE WHEN YEAR(order_date) = 2024 THEN sales * (1 - discount) ELSE 0 END), 2) AS revenue_2024,
    ROUND(
        (SUM(CASE WHEN YEAR(order_date) = 2024 THEN sales * (1 - discount) ELSE 0 END)
        - SUM(CASE WHEN YEAR(order_date) = 2023 THEN sales * (1 - discount) ELSE 0 END))
        / NULLIF(SUM(CASE WHEN YEAR(order_date) = 2023 THEN sales * (1 - discount) ELSE 0 END), 0) * 100
    , 2)                                                        AS yoy_growth_pct
FROM orders_partitioned
WHERE MONTH(order_date) BETWEEN 1 AND 10
GROUP BY MONTH(order_date)
ORDER BY month_number;


-- ═══════════════════════════════════════════
-- SECTION 2: CATEGORY & PRODUCT ANALYSIS
-- Answers BPS 2 and BPS 7
-- ═══════════════════════════════════════════

-- 2.1 Revenue and Profit by Category
SELECT
    category,
    COUNT(DISTINCT order_id)                                    AS total_orders,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct
FROM orders_partitioned
GROUP BY category
ORDER BY total_revenue DESC;


-- 2.2 Revenue and Profit by Sub-Category
SELECT
    category,
    sub_category,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(AVG(discount) * 100, 2)                               AS avg_discount_pct,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct
FROM orders_partitioned
GROUP BY category, sub_category
ORDER BY total_revenue DESC;


-- 2.3 High Revenue but Low Profit Products (Margin Drainers)
-- BPS 7 — identify products needing pricing revision
SELECT
    product_name,
    sub_category,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(AVG(discount) * 100, 2)                               AS avg_discount_pct,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct
FROM orders_partitioned
GROUP BY product_name, sub_category
HAVING SUM(sales * (1 - discount)) > 1000
   AND SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) < 0.05
ORDER BY total_revenue DESC
LIMIT 20;


-- 2.4 Top 10 Most Profitable Products
SELECT
    product_name,
    sub_category,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct
FROM orders_partitioned
GROUP BY product_name, sub_category
ORDER BY total_profit DESC
LIMIT 10;


-- 2.5 Bottom 10 Loss-Making Products
SELECT
    product_name,
    sub_category,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(AVG(discount) * 100, 2)                               AS avg_discount_pct
FROM orders_partitioned
GROUP BY product_name, sub_category
ORDER BY total_profit ASC
LIMIT 10;


-- ═══════════════════════════════════════════
-- SECTION 3: DISCOUNT vs PROFITABILITY
-- Answers BPS 4
-- ═══════════════════════════════════════════

-- 3.1 Profit by Discount Level
SELECT
    discount,
    COUNT(*)                                                    AS total_orders,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)                 AS loss_orders
FROM orders_partitioned
GROUP BY discount
ORDER BY discount;


-- 3.2 Discount vs Profit Margin by Sub-Category
SELECT
    sub_category,
    ROUND(AVG(discount) * 100, 2)                               AS avg_discount_pct,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    COUNT(*)                                                    AS total_orders
FROM orders_partitioned
GROUP BY sub_category
ORDER BY avg_discount_pct DESC;


-- 3.3 Loss Orders Analysis
SELECT
    COUNT(*)                                                    AS total_orders,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)                 AS loss_orders,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2)                                  AS loss_orders_pct,
    ROUND(SUM(CASE WHEN profit < 0 THEN profit ELSE 0 END), 2)  AS total_loss_amount
FROM orders_partitioned;


-- 3.4 Loss Orders by Category and Discount Level
SELECT
    category,
    discount,
    COUNT(*)                                                    AS total_orders,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)                 AS loss_orders,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2)                                  AS loss_pct
FROM orders_partitioned
GROUP BY category, discount
ORDER BY category, discount;


-- ═══════════════════════════════════════════
-- SECTION 4: REGIONAL ANALYSIS
-- Answers BPS 1, BPS 3, BPS 9
-- ═══════════════════════════════════════════

-- 4.1 Revenue and Profit by Region
SELECT
    region,
    COUNT(DISTINCT order_id)                                    AS total_orders,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct
FROM orders_partitioned
GROUP BY region
ORDER BY total_revenue DESC;


-- 4.2 Average Shipping Days by Region
-- BPS 3 — shipping pattern visibility
SELECT
    region,
    ROUND(AVG(date_diff('day', order_date, ship_date)), 2)      AS avg_shipping_days,
    MIN(date_diff('day', order_date, ship_date))                AS min_shipping_days,
    MAX(date_diff('day', order_date, ship_date))                AS max_shipping_days,
    COUNT(*)                                                    AS total_orders
FROM orders_partitioned
GROUP BY region
ORDER BY avg_shipping_days DESC;


-- 4.3 Average Shipping Days by Region and Segment
-- BPS 9 — correlation between shipping time and segment
SELECT
    region,
    segment,
    ROUND(AVG(date_diff('day', order_date, ship_date)), 2)      AS avg_shipping_days,
    COUNT(*)                                                    AS total_orders
FROM orders_partitioned
GROUP BY region, segment
ORDER BY region, avg_shipping_days DESC;


-- 4.4 Top 10 States by Revenue
SELECT
    state,
    region,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    COUNT(DISTINCT order_id)                                    AS total_orders
FROM orders_partitioned
GROUP BY state, region
ORDER BY total_revenue DESC
LIMIT 10;


-- ═══════════════════════════════════════════
-- SECTION 5: CUSTOMER SEGMENT ANALYSIS
-- Answers BPS 6
-- ═══════════════════════════════════════════

-- 5.1 Profit Margin by Segment
SELECT
    segment,
    COUNT(DISTINCT order_id)                                    AS total_orders,
    COUNT(DISTINCT customer_name)                               AS unique_customers,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(discount) * 100, 2)                               AS avg_discount_pct
FROM orders_partitioned
GROUP BY segment
ORDER BY profit_margin_pct DESC;


-- 5.2 Profit Margin by Segment and Year
SELECT
    segment,
    YEAR(order_date)                                            AS order_year,
    ROUND(SUM(profit) / NULLIF(SUM(sales * (1 - discount)), 0) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue
FROM orders_partitioned
GROUP BY segment, YEAR(order_date)
ORDER BY segment, order_year;


-- 5.3 Top 10 Customers by Profit
SELECT
    customer_name,
    segment,
    COUNT(DISTINCT order_id)                                    AS total_orders,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(AVG(discount) * 100, 2)                               AS avg_discount_pct
FROM orders_partitioned
GROUP BY customer_name, segment
ORDER BY total_profit DESC
LIMIT 10;


-- ═══════════════════════════════════════════
-- SECTION 6: TIME INTELLIGENCE QUERIES
-- Answers BPS 8
-- ═══════════════════════════════════════════

-- 6.1 Year over Year Revenue Growth
SELECT
    curr.order_year,
    curr.total_revenue                                          AS current_revenue,
    prev.total_revenue                                          AS previous_revenue,
    ROUND((curr.total_revenue - prev.total_revenue)
        / NULLIF(prev.total_revenue, 0) * 100, 2)              AS yoy_growth_pct
FROM (
    SELECT YEAR(order_date) AS order_year,
           SUM(sales * (1 - discount)) AS total_revenue
    FROM orders_partitioned
    GROUP BY YEAR(order_date)
) curr
LEFT JOIN (
    SELECT YEAR(order_date) AS order_year,
           SUM(sales * (1 - discount)) AS total_revenue
    FROM orders_partitioned
    GROUP BY YEAR(order_date)
) prev ON curr.order_year = prev.order_year + 1
ORDER BY curr.order_year;


-- 6.2 Monthly Revenue Trend — All Years
SELECT
    YEAR(order_date)                                            AS order_year,
    MONTH(order_date)                                           AS order_month,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS monthly_revenue,
    ROUND(SUM(profit), 2)                                       AS monthly_profit
FROM orders_partitioned
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;


-- 6.3 Quarterly Revenue by Year
SELECT
    YEAR(order_date)                                            AS order_year,
    QUARTER(order_date)                                         AS order_quarter,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS quarterly_revenue,
    ROUND(SUM(profit), 2)                                       AS quarterly_profit
FROM orders_partitioned
GROUP BY YEAR(order_date), QUARTER(order_date)
ORDER BY order_year, order_quarter;


-- 6.4 Revenue by Day of Week (All Years Combined)
SELECT
    day_of_week(order_date)                                     AS day_number,
    date_format(order_date, '%W')                               AS day_name,
    ROUND(SUM(sales * (1 - discount)), 2)                       AS total_revenue,
    COUNT(*)                                                    AS total_orders,
    ROUND(AVG(profit), 2)                                       AS avg_profit_per_order
FROM orders_partitioned
GROUP BY day_of_week(order_date), date_format(order_date, '%W')
ORDER BY day_number;


-- 6.5 Peak Month Identification Across All Years
SELECT
    MONTH(order_date)                                           AS month_number,
    ROUND(AVG(monthly_revenue), 2)                              AS avg_monthly_revenue
FROM (
    SELECT
        YEAR(order_date)  AS yr,
        MONTH(order_date) AS month_number,
        SUM(sales * (1 - discount)) AS monthly_revenue
    FROM orders_partitioned
    GROUP BY YEAR(order_date), MONTH(order_date)
) sub
GROUP BY MONTH(order_date)
ORDER BY avg_monthly_revenue DESC;


-- ═══════════════════════════════════════════
-- SECTION 7: SHIPPING ANALYSIS
-- Answers BPS 3 and BPS 9
-- ═══════════════════════════════════════════

-- 7.1 Overall Shipping Statistics
SELECT
    ROUND(AVG(date_diff('day', order_date, ship_date)), 2)      AS avg_shipping_days,
    MIN(date_diff('day', order_date, ship_date))                AS min_shipping_days,
    MAX(date_diff('day', order_date, ship_date))                AS max_shipping_days,
    COUNT(CASE WHEN date_diff('day', order_date, ship_date) > 5
               THEN 1 END)                                      AS late_shipments
FROM orders_partitioned;


-- 7.2 Shipping Days Distribution
SELECT
    date_diff('day', order_date, ship_date)                     AS shipping_days,
    COUNT(*)                                                    AS order_count,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(), 2)                                AS pct_of_total
FROM orders_partitioned
GROUP BY date_diff('day', order_date, ship_date)
ORDER BY shipping_days;


-- 7.3 Shipping Days by Category
SELECT
    category,
    ROUND(AVG(date_diff('day', order_date, ship_date)), 2)      AS avg_shipping_days,
    COUNT(*)                                                    AS total_orders
FROM orders_partitioned
GROUP BY category
ORDER BY avg_shipping_days DESC;


-- 7.4 Slowest Shipping Combinations (Region + Segment)
SELECT
    region,
    segment,
    ROUND(AVG(date_diff('day', order_date, ship_date)), 2)      AS avg_shipping_days,
    COUNT(*)                                                    AS total_orders,
    ROUND(SUM(profit), 2)                                       AS total_profit
FROM orders_partitioned
GROUP BY region, segment
ORDER BY avg_shipping_days DESC
LIMIT 10;
