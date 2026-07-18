-- =============================================================================
-- Apex Distribution Group — Supply Chain SQL Analysis
-- 10 queries covering ABC classification, supplier performance, stockouts,
-- inventory efficiency, and fulfillment. Tested and verified against
-- apex_supply_chain.db (SQLite).
-- =============================================================================

-- =============================================================================
-- QUERY 1: ABC PRODUCT CLASSIFICATION (REVENUE-DERIVED, NOT A LOOKUP COLUMN)
-- Techniques: CTE, window function (cumulative SUM), ranking, Pareto analysis
-- =============================================================================
-- BUSINESS OBJECTIVE: Classify all ~200 SKUs into A/B/C tiers based on their
-- actual revenue contribution, the standard inventory-management technique
-- for prioritizing which products get the tightest inventory control.
-- WHY LEADERSHIP REQUESTED IT: "Treat every SKU the same" wastes attention on
-- low-value products and under-protects high-value ones from stockouts.
-- BUSINESS INTERPRETATION: A-tier products (the smallest SKU count, largest
-- revenue share) deserve the most attentive replenishment and safety stock:
-- C-tier products are candidates for reduced safety stock or discontinuation.
-- OPERATIONAL IMPACT: Directly informs where to focus inventory planning
-- resources instead of spreading them evenly across all 198 SKUs.
-- =============================================================================
WITH product_revenue AS (
    SELECT p.product_id, p.product_name, p.category,
           SUM(o.quantity_fulfilled * p.unit_price) AS revenue
    FROM fact_orders o
    JOIN dim_products p ON p.product_id = o.product_id
    GROUP BY p.product_id, p.product_name, p.category
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rank_by_revenue,
        ROUND(SUM(revenue) OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING) / SUM(revenue) OVER () * 100, 1) AS cumulative_pct
    FROM product_revenue
)
SELECT
    product_name, category, ROUND(revenue,0) AS revenue, rank_by_revenue, cumulative_pct,
    CASE
        WHEN cumulative_pct <= 70 THEN 'A'
        WHEN cumulative_pct <= 90 THEN 'B'
        ELSE 'C'
    END AS derived_abc_class
FROM ranked
ORDER BY revenue DESC
LIMIT 20;


-- =============================================================================
-- QUERY 2: SUPPLIER ON-TIME DELIVERY %, RANKED (WORST TO BEST)
-- Techniques: CASE, aggregate, window function (RANK)
-- =============================================================================
-- BUSINESS OBJECTIVE: Identify which suppliers consistently deliver late.
-- WHY LEADERSHIP REQUESTED IT: Late deliveries are a leading cause of
-- downstream stockouts — this is the earliest point in the supply chain to
-- catch the problem before it reaches customers.
-- BUSINESS INTERPRETATION: Suppliers ranked worst are candidates for a
-- performance conversation, contract renegotiation, or dual-sourcing.
-- OPERATIONAL IMPACT: A prioritized supplier scorecard procurement can act on
-- directly, not just an aggregate "our suppliers are sometimes late" finding.
-- =============================================================================
SELECT
    s.supplier_name,
    s.region,
    COUNT(*) AS total_pos,
    ROUND(AVG(CASE WHEN julianday(po.actual_delivery_date) <= julianday(po.promised_delivery_date) THEN 1.0 ELSE 0.0 END) * 100, 1) AS on_time_delivery_pct,
    ROUND(AVG(julianday(po.actual_delivery_date) - julianday(po.promised_delivery_date)), 1) AS avg_days_late,
    RANK() OVER (ORDER BY AVG(CASE WHEN julianday(po.actual_delivery_date) <= julianday(po.promised_delivery_date) THEN 1.0 ELSE 0.0 END) ASC) AS worst_supplier_rank
FROM fact_purchase_orders po
JOIN dim_suppliers s ON s.supplier_id = po.supplier_id
GROUP BY s.supplier_name, s.region
ORDER BY on_time_delivery_pct ASC
LIMIT 10;


-- =============================================================================
-- QUERY 3: STOCKOUT/BACKORDER RATE BY PRODUCT VELOCITY AND CATEGORY
-- Techniques: CASE, aggregate, multi-dimensional grouping
-- =============================================================================
-- BUSINESS OBJECTIVE: Determine which products experience the most stockouts,
-- and whether the pattern concentrates in specific categories.
-- WHY LEADERSHIP REQUESTED IT: Stockouts directly cost revenue — leadership
-- needs to know if this is a broad problem or concentrated in identifiable
-- product groups.
-- BUSINESS INTERPRETATION: A pattern concentrated in low-velocity, low-
-- priority SKUs suggests a forecasting/reorder-point fix: concentration in
-- high-velocity SKUs would be a much more urgent, higher-revenue-impact issue.
-- OPERATIONAL IMPACT: Targets safety-stock and reorder-point adjustments to
-- the specific product segment actually driving lost sales.
-- =============================================================================
SELECT
    p.category,
    p.velocity_tier,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.status != 'Fulfilled' THEN 1 ELSE 0 END) AS problem_orders,
    ROUND(SUM(CASE WHEN o.status != 'Fulfilled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS stockout_rate_pct
FROM fact_orders o
JOIN dim_products p ON p.product_id = o.product_id
GROUP BY p.category, p.velocity_tier
ORDER BY stockout_rate_pct DESC
LIMIT 12;


-- =============================================================================
-- QUERY 4: INVENTORY TURNOVER & DAYS INVENTORY OUTSTANDING (DIO) BY VELOCITY TIER
-- Techniques: CTE, aggregate, business-formula calculation
-- =============================================================================
-- BUSINESS OBJECTIVE: Calculate the two headline inventory-efficiency KPIs
-- executives track — how many times inventory turns over per year, and how
-- many days of supply are sitting on hand.
-- WHY LEADERSHIP REQUESTED IT: Low turnover / high DIO ties up working
-- capital in unsold inventory: this quantifies exactly how much, by tier.
-- BUSINESS INTERPRETATION: If C-tier products show dramatically higher DIO
-- than A-tier, that capital-efficiency gap is concentrated in exactly the
-- products least worth carrying extra stock of.
-- OPERATIONAL IMPACT: A finance-relevant KPI (working capital tied up in
-- inventory) directly connected to the ABC classification from Query 1.
-- =============================================================================
WITH cogs AS (
    SELECT p.velocity_tier, SUM(o.quantity_fulfilled * p.unit_cost) AS total_cogs
    FROM fact_orders o JOIN dim_products p ON p.product_id = o.product_id
    GROUP BY p.velocity_tier
),
daily_inventory_value AS (
    SELECT p.velocity_tier, i.snapshot_date, SUM(i.on_hand_qty * i.unit_cost) AS inv_value_that_date
    FROM fact_inventory i JOIN dim_products p ON p.product_id = i.product_id
    GROUP BY p.velocity_tier, i.snapshot_date
),
avg_inventory_value AS (
    SELECT velocity_tier, AVG(inv_value_that_date) AS avg_inv_value
    FROM daily_inventory_value
    GROUP BY velocity_tier
)
SELECT
    c.velocity_tier,
    ROUND(c.total_cogs, 0) AS annual_cogs,
    ROUND(a.avg_inv_value, 0) AS avg_inventory_value,
    ROUND(c.total_cogs / a.avg_inv_value, 2) AS inventory_turnover_ratio,
    ROUND(365.0 / (c.total_cogs / a.avg_inv_value), 1) AS days_inventory_outstanding
FROM cogs c
JOIN avg_inventory_value a ON a.velocity_tier = c.velocity_tier
ORDER BY inventory_turnover_ratio DESC;


-- =============================================================================
-- QUERY 5: WAREHOUSE CAPACITY UTILIZATION, RANKED
-- Techniques: aggregate, window function (RANK), JOIN
-- =============================================================================
-- BUSINESS OBJECTIVE: Identify which warehouses are running closest to (or
-- over) their stated capacity.
-- WHY LEADERSHIP REQUESTED IT: A warehouse running near capacity has less
-- flexibility to absorb seasonal demand spikes and may need capacity
-- investment or inventory rebalancing across the network.
-- BUSINESS INTERPRETATION: A warehouse running well below capacity while
-- another runs near it signals a rebalancing opportunity before a new
-- capital investment is justified.
-- OPERATIONAL IMPACT: A concrete utilization ranking, not just "we might be
-- getting full somewhere."
-- =============================================================================
SELECT
    w.warehouse_name,
    w.capacity_units,
    ROUND(AVG(i.on_hand_qty), 0) AS avg_units_on_hand_per_sku_snapshot,
    ROUND(SUM(i.on_hand_qty) * 1.0 / COUNT(DISTINCT i.snapshot_date) / w.capacity_units * 100, 1) AS avg_capacity_utilization_pct,
    RANK() OVER (ORDER BY SUM(i.on_hand_qty) * 1.0 / COUNT(DISTINCT i.snapshot_date) / w.capacity_units DESC) AS utilization_rank
FROM fact_inventory i
JOIN dim_warehouses w ON w.warehouse_id = i.warehouse_id
GROUP BY w.warehouse_name, w.capacity_units
ORDER BY avg_capacity_utilization_pct DESC;


-- =============================================================================
-- QUERY 6: ORDER CYCLE TIME BY CHANNEL AND REGION
-- Techniques: aggregate, CASE, multi-dimensional grouping
-- =============================================================================
-- BUSINESS OBJECTIVE: Measure how long orders take to process, split by
-- sales channel and region, to spot fulfillment bottlenecks.
-- WHY LEADERSHIP REQUESTED IT: Slow fulfillment directly hurts customer
-- satisfaction and is often fixable operationally (staffing, routing) without
-- new capital investment.
-- BUSINESS INTERPRETATION: If one region's Online channel runs
-- disproportionately slower, that specific region's fulfillment operation
-- needs review before a network-wide policy change is considered.
-- OPERATIONAL IMPACT: Targets the fulfillment-improvement investment to the
-- specific channel/region combination actually underperforming.
-- =============================================================================
SELECT
    region,
    channel,
    COUNT(*) AS order_count,
    ROUND(AVG(order_cycle_days), 2) AS avg_order_cycle_days
FROM fact_orders
GROUP BY region, channel
ORDER BY avg_order_cycle_days DESC
LIMIT 12;


-- =============================================================================
-- QUERY 7: OVERSTOCK FLAGGING — ON-HAND INVENTORY VS. RECENT DEMAND
-- Techniques: CTE, CASE, subquery
-- =============================================================================
-- BUSINESS OBJECTIVE: Flag products holding inventory far in excess of their
-- recent actual demand — the overstock counterpart to the stockout analysis.
-- WHY LEADERSHIP REQUESTED IT: Excess inventory ties up capital and warehouse
-- space just as stockouts cost lost sales — both sides of the same problem
-- need visibility.
-- BUSINESS INTERPRETATION: Products flagged as heavily overstocked, especially
-- lower-velocity ones, are strong candidates for a markdown or reorder-
-- quantity reduction.
-- OPERATIONAL IMPACT: A specific, actionable overstock worklist rather than a
-- vague "we might have too much inventory somewhere" concern.
-- =============================================================================
WITH recent_demand AS (
    SELECT product_id, SUM(quantity_fulfilled) AS units_sold_last_90d
    FROM fact_orders
    WHERE order_date >= '2025-10-01'
    GROUP BY product_id
),
latest_inventory AS (
    SELECT product_id, SUM(on_hand_qty) AS total_on_hand
    FROM fact_inventory
    WHERE snapshot_date = (SELECT MAX(snapshot_date) FROM fact_inventory)
    GROUP BY product_id
)
SELECT
    p.product_name, p.velocity_tier,
    li.total_on_hand,
    COALESCE(rd.units_sold_last_90d, 0) AS units_sold_last_90d,
    ROUND(li.total_on_hand * 1.0 / (COALESCE(rd.units_sold_last_90d, 0) + 1), 1) AS months_of_supply_proxy,
    CASE WHEN li.total_on_hand > (COALESCE(rd.units_sold_last_90d,0) + 1) * 3 THEN 'Overstock Risk' ELSE 'Normal' END AS flag
FROM latest_inventory li
JOIN dim_products p ON p.product_id = li.product_id
LEFT JOIN recent_demand rd ON rd.product_id = li.product_id
ORDER BY months_of_supply_proxy DESC
LIMIT 15;


-- =============================================================================
-- QUERY 8: PERFECT ORDER RATE PROXY BY CHANNEL
-- Techniques: CASE, aggregate
-- =============================================================================
-- BUSINESS OBJECTIVE: Approximate the "perfect order rate" (fulfilled
-- complete, and within a reasonable cycle time) — a standard supply chain
-- composite KPI.
-- WHY LEADERSHIP REQUESTED IT: A single composite metric is easier for
-- executives to track over time than several separate sub-metrics.
-- BUSINESS INTERPRETATION: A channel with a meaningfully lower perfect order
-- rate needs a focused operational review, not just a general "improve
-- fulfillment" initiative.
-- OPERATIONAL IMPACT: A single number that can sit on the executive dashboard
-- and be tracked quarter over quarter.
-- =============================================================================
SELECT
    channel,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'Fulfilled' AND order_cycle_days <= 3 THEN 1 ELSE 0 END) AS perfect_orders,
    ROUND(SUM(CASE WHEN status = 'Fulfilled' AND order_cycle_days <= 3 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS perfect_order_rate_pct
FROM fact_orders
GROUP BY channel
ORDER BY perfect_order_rate_pct DESC;


-- =============================================================================
-- QUERY 9: MONTHLY DEMAND TREND WITH 3-MONTH ROLLING AVERAGE
-- Techniques: CTE, window function (rolling AVG), time series analysis
-- =============================================================================
-- BUSINESS OBJECTIVE: Track overall order demand trend, smoothed to separate
-- real growth from month-to-month noise and seasonal spikes.
-- WHY LEADERSHIP REQUESTED IT: Purchasing and staffing decisions should be
-- based on the underlying trend, not a single unusually high or low month.
-- BUSINESS INTERPRETATION: A rising rolling average alongside known seasonal
-- spikes (Nov-Dec) confirms real underlying growth, not just holiday timing.
-- OPERATIONAL IMPACT: Directly informs forward purchasing volume decisions
-- (see the Python forecasting notebook for a quantified projection).
-- =============================================================================
WITH monthly_demand AS (
    SELECT strftime('%Y-%m', order_date) AS year_month, SUM(quantity_ordered) AS units_ordered
    FROM fact_orders
    GROUP BY year_month
)
SELECT
    year_month,
    units_ordered,
    ROUND(AVG(units_ordered) OVER (ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS rolling_3mo_avg
FROM monthly_demand
ORDER BY year_month;


-- =============================================================================
-- QUERY 10: COMPOUND SUPPLIER RISK SCORE
-- Techniques: CTE, CASE, multi-factor scoring
-- =============================================================================
-- BUSINESS OBJECTIVE: Combine on-time delivery performance and fill accuracy
-- (quantity received vs. ordered) into one transparent supplier risk score.
-- WHY LEADERSHIP REQUESTED IT: Procurement needs a single prioritized list
-- for supplier review meetings, not two separate unranked metrics to
-- cross-reference manually.
-- BUSINESS INTERPRETATION: Suppliers scoring highest risk on both dimensions
-- simultaneously are the most urgent renegotiation or dual-sourcing
-- candidates — worse than a supplier that's merely slow but always sends the
-- full quantity ordered.
-- OPERATIONAL IMPACT: A ready-made prioritized supplier review list for the
-- next procurement business review.
-- =============================================================================
WITH supplier_metrics AS (
    SELECT
        s.supplier_name,
        AVG(CASE WHEN julianday(po.actual_delivery_date) <= julianday(po.promised_delivery_date) THEN 1.0 ELSE 0.0 END) AS on_time_rate,
        AVG(po.quantity_received * 1.0 / po.quantity_ordered) AS fill_accuracy_rate
    FROM fact_purchase_orders po
    JOIN dim_suppliers s ON s.supplier_id = po.supplier_id
    GROUP BY s.supplier_name
)
SELECT
    supplier_name,
    ROUND(on_time_rate*100,1) AS on_time_pct,
    ROUND(fill_accuracy_rate*100,1) AS fill_accuracy_pct,
    (CASE WHEN on_time_rate < 0.75 THEN 2 WHEN on_time_rate < 0.85 THEN 1 ELSE 0 END) +
    (CASE WHEN fill_accuracy_rate < 0.92 THEN 2 WHEN fill_accuracy_rate < 0.96 THEN 1 ELSE 0 END) AS supplier_risk_score
FROM supplier_metrics
ORDER BY supplier_risk_score DESC, on_time_pct ASC
LIMIT 10;
