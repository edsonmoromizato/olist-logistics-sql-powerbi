/*
===============================================================================
PROJECT: Olist E-Commerce Supply Chain
FILE: 01_logistics_analysis.sql
DESCRIPTION: Analysis of delivery SLAs, shipping lead times, and bottlenecks.
===============================================================================
*/

-- ==============================================================================
-- PHASE 1: DATA EXPLORATION & QUALITY CHECKS (Profiling)
-- ==============================================================================

-- 1.1 Inspect dataset structures and initial columns

SELECT * FROM olist_orders_dataset LIMIT 5;
SELECT * FROM olist_customers_dataset LIMIT 5;

-- 1.2 Validate primary key uniqueness (Ensure customer_id has no duplicates)
SELECT
  customer_id,
  COUNT(*)
FROM olist_orders_dataset
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ==============================================================================
-- PHASE 2: BUSINESS ANALYSIS & METRICS
-- ==============================================================================

-- QUERY 1: Average Delivery Days by Customer State
-- Business Intent: Identify regions with the highest shipping latency to optimize logistics.
-- Expected Result: Table grouped by state, ordered by avg_delivery_days descending.
-- ==============================================================================

SELECT
  c.customer_state,
  COUNT(o.order_id) AS total_orders,
  ROUND(AVG(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)),2) AS avg_delivery_days
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;


-- ============================================================================
-- QUERY 2: SLA Compliance (On-Time vs. Late Delivery Percentage)
-- Objective: Calculate overall fulfillment rate vs estimated delivery target.
-- ============================================================================

SELECT
  CASE
    WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On-Time'
    ELSE 'Late'
    END AS delivery_status,
  COUNT(o.order_id) AS total_orders,
  ROUND(
    COUNT(o.order_id) * 100.0 / (SELECT COUNT(*) FROM olist_orders_dataset WHERE order_status = 'delivered'), 2
  ) AS percentage
FROM olist_orders_dataset o
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status


-- ============================================================================
-- QUERY 3: Top 10 Product Categories with Worst Shipping Delays
-- Objective: Isolate product lines with the highest average delay beyond SLA.
-- ============================================================================

SELECT
  COALESCE(t.product_category_name_english, p.product_category_name) AS category_name,
  COUNT(o.order_id) AS total_orders,
  ROUND(
    AVG(julianday(o.order_delivered_customer_date) - julianday(o.order_estimated_delivery_date)),
    2
    ) AS avg_days_delayed
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
JOIN olist_products_dataset p ON i.product_id = p.product_id
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY category_name
ORDER BY avg_days_delayed DESC
LIMIT 10;


-- ============================================================================
-- QUERY 4: Seller-to-Customer Distance Impact (Bottleneck Routes)
-- Objective: Identify geographical state pairings with high delivery latency.
-- ============================================================================

SELECT
  s.seller_state,
  c.customer_state,
  COUNT(DISTINCT o.order_id) AS total_orders,
  ROUND(AVG(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)), 2) AS avg_delivery_days
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_state, c.customer_state
HAVING total_orders > 100
ORDER BY avg_delivery_days DESC
LIMIT 10;