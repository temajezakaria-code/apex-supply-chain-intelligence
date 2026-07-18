-- =============================================================================
-- Apex Distribution Group — Supply Chain Analytics Database Schema
-- =============================================================================
-- Business scenario: a global consumer goods distributor with 6 regional
-- distribution centers, 15 suppliers, ~200 SKUs, and Store + Online order
-- channels, experiencing stockouts, overstock, and supplier delivery delays.
-- =============================================================================

CREATE TABLE dim_warehouses (
    warehouse_id     INTEGER PRIMARY KEY,
    warehouse_name   VARCHAR(40) NOT NULL,
    region           VARCHAR(20) NOT NULL,
    capacity_units   INTEGER NOT NULL
);

CREATE TABLE dim_suppliers (
    supplier_id          INTEGER PRIMARY KEY,
    supplier_name        VARCHAR(40) NOT NULL,
    region               VARCHAR(20) NOT NULL,
    reliability_factor   DECIMAL(4,3) NOT NULL,   -- underlying tendency, not directly exposed in analysis
    base_lead_time_days  INTEGER NOT NULL
);

CREATE TABLE dim_products (
    product_id      INTEGER PRIMARY KEY,
    product_name    VARCHAR(60) NOT NULL,
    category        VARCHAR(30) NOT NULL,
    supplier_id     INTEGER NOT NULL REFERENCES dim_suppliers(supplier_id),
    unit_cost       DECIMAL(10,2) NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    velocity_tier   VARCHAR(1) NOT NULL   -- A (fast), B (medium), C (slow) -- ground truth, ABC classification is re-derived from revenue in analysis, not just read off this column
);

-- Grain: one row per supplier purchase order (replenishment)
CREATE TABLE fact_purchase_orders (
    po_id                    INTEGER PRIMARY KEY,
    supplier_id              INTEGER NOT NULL REFERENCES dim_suppliers(supplier_id),
    product_id               INTEGER NOT NULL REFERENCES dim_products(product_id),
    warehouse_id             INTEGER NOT NULL REFERENCES dim_warehouses(warehouse_id),
    order_date               DATE NOT NULL,
    promised_delivery_date   DATE NOT NULL,
    actual_delivery_date     DATE NOT NULL,
    quantity_ordered         INTEGER NOT NULL,
    quantity_received        INTEGER NOT NULL
);

-- Grain: one row per customer order (Store or Online)
CREATE TABLE fact_orders (
    order_id             INTEGER PRIMARY KEY,
    product_id           INTEGER NOT NULL REFERENCES dim_products(product_id),
    channel              VARCHAR(10) NOT NULL,   -- Store / Online
    region               VARCHAR(20) NOT NULL,
    order_date           DATE NOT NULL,
    quantity_ordered     INTEGER NOT NULL,
    quantity_fulfilled   INTEGER NOT NULL,
    status               VARCHAR(15) NOT NULL,   -- Fulfilled / Backordered / Cancelled
    order_cycle_days     INTEGER NOT NULL
);

-- Grain: one row per product-warehouse-week snapshot
CREATE TABLE fact_inventory (
    inventory_id       INTEGER PRIMARY KEY,
    product_id         INTEGER NOT NULL REFERENCES dim_products(product_id),
    warehouse_id       INTEGER NOT NULL REFERENCES dim_warehouses(warehouse_id),
    snapshot_date      DATE NOT NULL,
    on_hand_qty        INTEGER NOT NULL,
    safety_stock_qty   INTEGER NOT NULL,
    on_order_qty       INTEGER NOT NULL,
    unit_cost          DECIMAL(10,2) NOT NULL
);

CREATE INDEX idx_po_supplier ON fact_purchase_orders(supplier_id);
CREATE INDEX idx_po_product ON fact_purchase_orders(product_id);
CREATE INDEX idx_orders_product ON fact_orders(product_id);
CREATE INDEX idx_orders_date ON fact_orders(order_date);
CREATE INDEX idx_inv_product_wh ON fact_inventory(product_id, warehouse_id);

-- =============================================================================
-- Note: this dataset is entirely synthetic. Real combined supplier/warehouse/
-- order-level supply chain data at this granularity is not available as a
-- public dataset — this generator (see data/generate_data.py) builds
-- realistic, documented operational patterns (chronically late suppliers,
-- ABC-skewed product velocity, seasonal demand spikes) so the analysis has
-- genuine signal to uncover.
-- =============================================================================
