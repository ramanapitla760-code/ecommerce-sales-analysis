-- E-Commerce Data Analytics
-- MySQL analysis queries for portfolio use
-- Database: ecommerce_analytics
--
-- Tables:
-- customers, products, orders, order_items, payments, returns
--
-- Business rules:
-- 1. Revenue/profit KPIs use Completed orders only.
-- 2. Invalid/zero quantities are excluded from normal sales calculations.
-- 3. Revenue includes discounts.
-- 4. Profit = quantity * ((unit_price * (1 - discount)) - unit_cost).

USE ecommerce_analytics;


-- ============================================================
-- 1. ORDER STATUS
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS status_pct
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- ============================================================
-- 2. MASTER KPI QUERY
-- Single source of truth for the portfolio
-- ============================================================

SELECT
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount)), 2) AS total_revenue,
    ROUND(
        SUM(
            oi.quantity *
            ((p.unit_price * (1 - oi.discount)) - p.unit_cost)
        ),
        2
    ) AS total_profit,
    ROUND(
        SUM(
            oi.quantity *
            ((p.unit_price * (1 - oi.discount)) - p.unit_cost)
        ) * 100.0 /
        NULLIF(
            SUM(oi.quantity * p.unit_price * (1 - oi.discount)),
            0
        ),
        2
    ) AS profit_margin_pct,
    ROUND(
        SUM(oi.quantity * p.unit_price * (1 - oi.discount)) /
        NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0;


-- ============================================================
-- 3. REVENUE AND PROFIT BY CATEGORY
-- ============================================================

SELECT
    p.category,
    ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount)), 2) AS revenue,
    ROUND(
        SUM(
            oi.quantity *
            ((p.unit_price * (1 - oi.discount)) - p.unit_cost)
        ),
        2
    ) AS profit,
    ROUND(
        SUM(
            oi.quantity *
            ((p.unit_price * (1 - oi.discount)) - p.unit_cost)
        ) * 100.0 /
        NULLIF(
            SUM(oi.quantity * p.unit_price * (1 - oi.discount)),
            0
        ),
        2
    ) AS profit_margin_pct
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
GROUP BY p.category
ORDER BY revenue DESC;


-- ============================================================
-- 4. TOP 10 PRODUCTS BY REVENUE
-- ============================================================

SELECT
    p.product_name,
    p.category,
    ROUND(
        SUM(oi.quantity * p.unit_price * (1 - oi.discount)),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
GROUP BY p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 5. TOP 10 PRODUCTS BY PROFIT
-- ============================================================

SELECT
    p.product_name,
    p.category,
    ROUND(
        SUM(
            oi.quantity *
            ((p.unit_price * (1 - oi.discount)) - p.unit_cost)
        ),
        2
    ) AS profit
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
GROUP BY p.product_name, p.category
ORDER BY profit DESC
LIMIT 10;


-- ============================================================
-- 6. TOP 10 CUSTOMERS BY REVENUE
-- ============================================================

SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(oi.quantity) AS units_purchased,
    ROUND(
        SUM(oi.quantity * p.unit_price * (1 - oi.discount)),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
GROUP BY o.customer_id
ORDER BY revenue DESC
LIMIT 10;


-- ============================================================
-- 7. MONTHLY REVENUE TREND
-- ============================================================

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(
        SUM(oi.quantity * p.unit_price * (1 - oi.discount)),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed'
  AND oi.quantity > 0
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;


-- ============================================================
-- 8. PAYMENT METHOD ANALYSIS
-- ============================================================

SELECT
    payment_method,
    COUNT(*) AS payment_count
FROM payments
GROUP BY payment_method
ORDER BY payment_count DESC;


-- ============================================================
-- 9. RETURN ANALYSIS
-- Actual returns schema:
-- return_id, order_id, return_date, return_reason, return_quantity
-- ============================================================

SELECT
    return_reason,
    COUNT(*) AS return_records,
    SUM(return_quantity) AS returned_units
FROM returns
GROUP BY return_reason
ORDER BY returned_units DESC;


-- ============================================================
-- 10. CANCELLATION RATE
-- ============================================================

SELECT
    COUNT(*) AS total_orders,
    SUM(order_status = 'Cancelled') AS cancelled_orders,
    ROUND(
        SUM(order_status = 'Cancelled') * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate_pct
FROM orders;


-- ============================================================
-- 11. REPEAT CUSTOMERS
-- ============================================================

SELECT
    COUNT(*) AS repeat_customers
FROM (
    SELECT
        customer_id
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) > 1
) AS customer_order_counts;


-- ============================================================
-- 12. DATA QUALITY: INVALID QUANTITIES
-- ============================================================

SELECT
    COUNT(*) AS invalid_quantity_records
FROM order_items
WHERE quantity <= 0;


-- ============================================================
-- 13. DATA QUALITY: PRODUCTS WITH NEGATIVE UNIT MARGIN
-- These records are retained for investigation rather than deleted.
-- ============================================================

SELECT
    product_id,
    product_name,
    category,
    unit_cost,
    unit_price,
    ROUND(unit_price - unit_cost, 2) AS unit_margin
FROM products
WHERE unit_cost > unit_price
ORDER BY unit_margin ASC;


-- ============================================================
-- 14. PERFORMANCE OPTIMIZATION INDEXES
-- Add only if these indexes do not already exist.
-- ============================================================

CREATE INDEX idx_orders_order_id
    ON orders(order_id);

CREATE INDEX idx_orders_status
    ON orders(order_status(20));

CREATE INDEX idx_order_items_order_id
    ON order_items(order_id);

CREATE INDEX idx_order_items_product_id
    ON order_items(product_id);


-- ============================================================
-- PROJECT NOTES
-- ============================================================
-- The portfolio analysis uses Completed orders for sales KPIs.
-- Revenue:
-- quantity * unit_price * (1 - discount)
--
-- Profit:
-- quantity * ((unit_price * (1 - discount)) - unit_cost)
--
-- Exploratory queries that omit discounts should NOT be used
-- as the final KPI source.
