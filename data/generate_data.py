"""
Apex Distribution Group — Synthetic Supply Chain Data Generator
==================================================================
Business scenario: a global consumer goods distributor with 6 regional
distribution centers, 15 suppliers, ~200 SKUs, and both retail-store and
online order channels, across 3 years (2023-2025). Real combined supplier/
warehouse/order-level supply chain data at this granularity isn't available
as a public dataset — this generator builds realistic, documented
operational patterns (chronically late suppliers, seasonal demand spikes,
ABC-skewed product velocity, warehouse capacity strain) so the analysis has
genuine signal to uncover, exactly like a real distribution network's data.
"""
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import random

random.seed(42)
np.random.seed(42)

OUT_DIR = "/home/claude/apex-supply-chain/data"
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2025, 12, 31)
N_DAYS = (END_DATE - START_DATE).days + 1

# ---------------------------------------------------------------------------
# DIMENSION: WAREHOUSES (regional distribution centers)
# ---------------------------------------------------------------------------
warehouses = pd.DataFrame([
    {"warehouse_id": 1, "warehouse_name": "Apex DC - Northeast", "region": "Northeast", "capacity_units": 480000},
    {"warehouse_id": 2, "warehouse_name": "Apex DC - Southeast", "region": "Southeast", "capacity_units": 360000},
    {"warehouse_id": 3, "warehouse_name": "Apex DC - Midwest",   "region": "Midwest",   "capacity_units": 420000},
    {"warehouse_id": 4, "warehouse_name": "Apex DC - Southwest", "region": "Southwest", "capacity_units": 300000},
    {"warehouse_id": 5, "warehouse_name": "Apex DC - West",      "region": "West",      "capacity_units": 390000},
    {"warehouse_id": 6, "warehouse_name": "Apex DC - Pacific NW","region": "Pacific NW", "capacity_units": 240000},
])

# ---------------------------------------------------------------------------
# DIMENSION: SUPPLIERS (15, deliberately varied reliability)
# ---------------------------------------------------------------------------
supplier_names = ["Coastal Goods Co","Summit Manufacturing","BlueRiver Supply","Redwood Industries",
                   "Harbor Point Traders","Granite Peak Mfg","Cedar Valley Supply","Pioneer Logistics Group",
                   "Silverline Distributors","Crestwood Manufacturing","Meridian Fabricators","NorthStar Sourcing",
                   "Ashford Global Supply","Falcon Ridge Mfg","TerraLink Distribution"]
supplier_reliability = np.clip(np.random.normal(0.87, 0.09, len(supplier_names)), 0.60, 0.99)  # on-time delivery tendency
supplier_lead_time_base = np.random.randint(7, 35, len(supplier_names))  # base lead time in days

suppliers = pd.DataFrame({
    "supplier_id": range(1, len(supplier_names)+1),
    "supplier_name": supplier_names,
    "region": np.random.choice(["Domestic","Asia-Pacific","Europe","Latin America"], len(supplier_names), p=[0.35,0.35,0.2,0.1]),
    "reliability_factor": supplier_reliability.round(3),
    "base_lead_time_days": supplier_lead_time_base,
})

# ---------------------------------------------------------------------------
# DIMENSION: PRODUCTS (~200 SKUs, ABC-skewed velocity built in)
# ---------------------------------------------------------------------------
categories = {
    "Home Appliances": (60, 320), "Electronics": (80, 900), "Furniture": (100, 700),
    "Kitchenware": (15, 140), "Home Decor": (12, 180), "Outdoor & Garden": (30, 400),
}
brands = ["Aurora","Vantek","HomeCraft","Nexa","PrimeLiving","Urbanox","CoreHome","Lumeo"]

product_rows = []
pid = 1
for category, (low, high) in categories.items():
    for _ in range(200 // len(categories)):
        cost = round(random.uniform(low, high), 2)
        price = round(cost / 0.55, 2)
        # velocity_tier drives both order demand AND how many SKUs are "A" (fast) vs "C" (slow)
        velocity_tier = np.random.choice(["A","B","C"], p=[0.20, 0.30, 0.50])
        product_rows.append({
            "product_id": pid, "product_name": f"{random.choice(brands)} {category.split()[0]} {random.choice(['Pro','Classic','X','Lite','Max'])}",
            "category": category, "supplier_id": random.randint(1, len(supplier_names)),
            "unit_cost": cost, "unit_price": price, "velocity_tier": velocity_tier,
        })
        pid += 1
products = pd.DataFrame(product_rows)
velocity_weight = products["velocity_tier"].map({"A": 8.0, "B": 3.0, "C": 1.0}).values
velocity_weight = velocity_weight / velocity_weight.sum()

def seasonal_factor(date):
    m = date.month
    if m in (11, 12):
        return 2.1
    if m in (1,):
        return 0.75
    return 1.0

YEAR_GROWTH = {2023: 1.0, 2024: 1.06, 2025: 1.13}

# ---------------------------------------------------------------------------
# FACT: PURCHASE ORDERS (replenishment from suppliers to warehouses)
# ---------------------------------------------------------------------------
print("Generating purchase orders...")
po_rows = []
po_id = 1
for d in range(0, N_DAYS, 1):
    date = START_DATE + timedelta(days=d)
    n_pos = np.random.poisson(22 * seasonal_factor(date) * YEAR_GROWTH[date.year] * 0.5)
    for _ in range(n_pos):
        pid_chosen = np.random.choice(products["product_id"], p=velocity_weight)
        prod = products[products["product_id"] == pid_chosen].iloc[0]
        sup = suppliers[suppliers["supplier_id"] == prod["supplier_id"]].iloc[0]
        wh_id = random.randint(1, 6)
        qty_ordered = int(np.random.choice([50,100,150,200,300,500], p=[0.25,0.25,0.2,0.15,0.1,0.05]))
        promised_lead = max(3, int(np.random.normal(sup["base_lead_time_days"], 3)))
        promised_delivery = date + timedelta(days=promised_lead)
        # Actual delivery varies by supplier reliability — unreliable suppliers run late more often & by more days
        on_time_roll = np.random.random()
        if on_time_roll < sup["reliability_factor"]:
            delay_days = max(0, int(np.random.normal(0, 1.2)))
        else:
            delay_days = int(np.random.gamma(shape=2.5, scale=4))  # meaningfully late
        actual_delivery = promised_delivery + timedelta(days=delay_days)
        # Quality defects slightly more common from lower-reliability suppliers too
        defect_rate = 0.02 + (1 - sup["reliability_factor"]) * 0.08
        qty_received = qty_ordered - int(qty_ordered * defect_rate * random.random())
        po_rows.append({
            "po_id": po_id, "supplier_id": int(sup["supplier_id"]), "product_id": int(pid_chosen),
            "warehouse_id": wh_id, "order_date": date.date().isoformat(),
            "promised_delivery_date": promised_delivery.date().isoformat(),
            "actual_delivery_date": actual_delivery.date().isoformat(),
            "quantity_ordered": qty_ordered, "quantity_received": qty_received,
        })
        po_id += 1
purchase_orders = pd.DataFrame(po_rows)
print(f"  Purchase orders: {len(purchase_orders):,} rows")

# ---------------------------------------------------------------------------
# FACT: CUSTOMER ORDERS (store + online channels)
# ---------------------------------------------------------------------------
print("Generating customer orders...")
order_rows = []
order_id = 1
channels = ["Store", "Online"]
regions = warehouses["region"].tolist()

for d in range(N_DAYS):
    date = START_DATE + timedelta(days=d)
    n_orders = np.random.poisson(140 * seasonal_factor(date) * YEAR_GROWTH[date.year])
    for _ in range(n_orders):
        pid_chosen = np.random.choice(products["product_id"], p=velocity_weight)
        prod = products[products["product_id"] == pid_chosen].iloc[0]
        channel = np.random.choice(channels, p=[0.42, 0.58])
        region = random.choice(regions)
        qty_ordered = int(np.random.choice([1,2,3,4,5], p=[0.55,0.22,0.12,0.07,0.04]))
        # Stockout risk higher for low-velocity (C) products ordered in demand spikes, and generally elevated in Nov-Dec
        stockout_base = {"A": 0.03, "B": 0.06, "C": 0.11}[prod["velocity_tier"]]
        stockout_risk = stockout_base * seasonal_factor(date)
        is_stockout = np.random.random() < stockout_risk
        if is_stockout:
            qty_fulfilled = max(0, qty_ordered - random.randint(1, qty_ordered))
            status = "Backordered" if qty_fulfilled > 0 else "Cancelled" if random.random() < 0.3 else "Backordered"
        else:
            qty_fulfilled = qty_ordered
            status = "Fulfilled"
        order_cycle_days = max(1, int(np.random.gamma(shape=2, scale=1.5))) if channel=="Online" else max(0, int(np.random.gamma(shape=1.2, scale=0.8)))
        order_rows.append({
            "order_id": order_id, "product_id": int(pid_chosen), "channel": channel, "region": region,
            "order_date": date.date().isoformat(), "quantity_ordered": qty_ordered,
            "quantity_fulfilled": qty_fulfilled, "status": status, "order_cycle_days": order_cycle_days,
        })
        order_id += 1
orders = pd.DataFrame(order_rows)
print(f"  Customer orders: {len(orders):,} rows")

# ---------------------------------------------------------------------------
# FACT: WEEKLY INVENTORY SNAPSHOTS
# ---------------------------------------------------------------------------
print("Generating weekly inventory snapshots...")
inv_rows = []
inv_id = 1
n_weeks = N_DAYS // 7

for w in range(n_weeks):
    week_date = START_DATE + timedelta(days=w*7)
    for _, prod in products.iterrows():
        for wh_id in range(1, 7):
            base_stock = {"A": 800, "B": 350, "C": 150}[prod["velocity_tier"]]
            seasonal_adj = 1.3 if week_date.month in (10,11) else (0.85 if week_date.month==1 else 1.0)
            on_hand = max(0, int(np.random.normal(base_stock * seasonal_adj, base_stock*0.3)))
            safety_stock = int(base_stock * 0.25)
            on_order = int(np.random.choice([0,50,100,150,200], p=[0.4,0.2,0.2,0.1,0.1]))
            inv_rows.append({
                "inventory_id": inv_id, "product_id": int(prod["product_id"]), "warehouse_id": wh_id,
                "snapshot_date": week_date.date().isoformat(), "on_hand_qty": on_hand,
                "safety_stock_qty": safety_stock, "on_order_qty": on_order,
                "unit_cost": prod["unit_cost"],
            })
            inv_id += 1
inventory = pd.DataFrame(inv_rows)
print(f"  Inventory snapshots: {len(inventory):,} rows")

# ---------------------------------------------------------------------------
# SAVE
# ---------------------------------------------------------------------------
warehouses.to_csv(f"{OUT_DIR}/dim_warehouses.csv", index=False)
suppliers.to_csv(f"{OUT_DIR}/dim_suppliers.csv", index=False)
products.to_csv(f"{OUT_DIR}/dim_products.csv", index=False)
purchase_orders.to_csv(f"{OUT_DIR}/fact_purchase_orders.csv", index=False)
orders.to_csv(f"{OUT_DIR}/fact_orders.csv", index=False)
inventory.to_csv(f"{OUT_DIR}/fact_inventory.csv", index=False)

total = len(warehouses)+len(suppliers)+len(products)+len(purchase_orders)+len(orders)+len(inventory)
print(f"\nTOTAL ROWS ACROSS ALL TABLES: {total:,}")
