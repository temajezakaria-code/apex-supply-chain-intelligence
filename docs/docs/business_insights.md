# Apex Distribution Group — Executive Insights & Recommendations

All figures below are pulled directly from the SQL analysis and Python notebooks in
this repository (189,562 orders, 14,970 purchase orders, 185,328 inventory
snapshots, 198 SKUs, 15 suppliers, 6 warehouses, 2023-2025). This project uses
fictional data — where a figure is a relative comparison rather than a real
absolute benchmark, that is stated explicitly.

---

## 15 Executive Insights

1. **Revenue is genuinely concentrated (ABC/Pareto confirmed)**: the top 26 SKUs
   (13% of the catalog) generate 46.3% of revenue, while the bottom 103 SKUs (52%
   of the catalog) generate only 17.0%.
2. **Stockout rate rises sharply and predictably by product tier**: A=3.9%,
   B=7.8%, C=14.4% — statistically confirmed (chi-square, p<0.001, n=189,562).
3. **Supplier on-time delivery does NOT significantly explain product-level
   stockout rate** (r=-0.118, p=0.097) — an honest near-null result. Demand
   volatility (the tier itself) appears to be the dominant stockout driver, not
   supplier delivery performance.
4. **Supplier reliability varies dramatically**: the worst supplier (Falcon Ridge
   Mfg) delivers on-time only 57.0% of the time; even the *best* supplier
   (Redwood Industries) only reaches 79.0% — the entire network runs below what
   most operations would consider an acceptable on-time threshold.
5. **A striking fulfillment gap exists between channels**: Store orders hit a
   91.4% perfect-order rate vs. just 68.9% for Online — a 22.5 percentage point
   gap on the exact same product catalog.
6. **Furniture is the single largest revenue category** ($53.7M), nearly 8x
   Home Decor ($7.2M), the smallest category.
7. **Network-wide on-time delivery sits at 70.7%** — meaning roughly 3 in 10
   purchase orders arrive late, a systemic issue rather than a few problem
   suppliers.
8. **Order processing time varies by region**: Northeast processes fastest
   (~2.3-2.4 days) while Pacific NW runs slowest (~2.7-2.8 days) — a ~20%
   spread across the network.
9. **Demand shows a strong, recurring Nov-Dec seasonal surge** (roughly double
   baseline monthly volume), confirmed across all 3 years of historical data.
10. **The 6-month forecast projects demand in the 8,000-10,200 units/month
    range**, giving purchasing a concrete forward volume target.
11. **Domestic and Asia-Pacific suppliers make up 13 of the network's 15
    suppliers** — Europe and Latin America are each represented by just one
    supplier, a potential concentration/diversification gap.
12. **A-tier products turn over meaningfully faster than C-tier** (relative
    comparison only — see Critical Assessment on why absolute turnover figures
    aren't reported as real-world benchmarks).
13. **The current overstock-detection threshold flagged all 198 products** as
    "at risk" — this is a signal the *threshold*, not the products, needs
    recalibration, not a finding that literally 100% of the catalog is
    overstocked. Reported honestly rather than presented as a real insight.
14. **Relative warehouse capacity pressure is highest at Pacific NW and lowest
    at Northeast** — a cross-warehouse comparison, not an absolute occupancy
    benchmark (see Critical Assessment).
15. **No single fix addresses both major problems identified** — stockouts trace
    to demand volatility (an inventory/forecasting problem) while the
    channel fulfillment gap traces to Online-specific operations (a process
    problem) — two different root causes requiring two different initiatives.

---

## 10 Operational Risks

1. **A 70.7% network-wide supplier on-time rate is a systemic exposure**, not a
   few problem vendors — a market disruption affecting even "reliable" suppliers
   could compound quickly.
2. **The Online channel's 68.9% perfect-order rate risks customer churn** if
   competitors offer more reliable e-commerce fulfillment.
3. **C-tier stockouts, while individually low-revenue, collectively represent a
   customer-experience risk** if the same customers repeatedly encounter
   unavailable low-velocity products.
4. **Supplier concentration in Domestic/Asia-Pacific regions (13 of 15
   suppliers) creates geopolitical and shipping-disruption risk** with limited
   alternative sourcing regions.
5. **The Nov-Dec demand surge, if under-forecasted, risks stockouts at the exact
   moment of peak revenue opportunity.**
6. **An overstock-detection threshold that flags 100% of products provides
   zero decision-making value** — leadership relying on this metric as-is
   would have no way to actually prioritize markdown or discontinuation
   decisions.
7. **Regional order-processing time variance (2.3 to 2.8 days) risks inconsistent
   customer experience** depending purely on which region a customer orders
   from.
8. **Furniture's outsized revenue concentration (36% of total) means any
   category-specific disruption** (a key supplier issue, a demand shift) would
   have an outsized network-wide impact.
9. **Relying on the "best" supplier's 79% on-time rate as a benchmark is itself
   a risk** — it suggests the achievable ceiling for this supplier base may be
   structurally limited without a broader supplier-development program.
10. **Without addressing the Online fulfillment gap specifically, general
    "improve fulfillment" initiatives risk under-investing in Store (already
    strong) and under-investing in Online (where the real gap is).**

---

## 15 Strategic Recommendations

1. **Launch a dedicated Online fulfillment process review** — the single most
   concrete, highest-confidence gap identified (22.5-point perfect-order-rate
   deficit vs. Store).
2. **Prioritize demand-forecasting and safety-stock investment for C-tier
   products** over supplier-focused fixes, since the root-cause analysis shows
   demand volatility — not supplier delay — is the dominant stockout driver.
3. **Recalibrate the overstock-detection threshold** before using it for any
   markdown or discontinuation decision — the current version provides no
   differentiation.
4. **Open a supplier-development conversation with the bottom 5 suppliers**
   (all below 68% on-time), starting with Falcon Ridge Mfg and TerraLink
   Distribution.
5. **Investigate why even the best-performing supplier caps out around 79%
   on-time** — this may point to a systemic issue (unrealistic promised lead
   times, inadequate buffer) rather than individual supplier fault.
6. **Build a regional order-processing benchmarking initiative**, using
   Northeast's faster processing time as the internal best-practice model for
   Pacific NW and other slower regions.
7. **Diversify supplier sourcing regions** — with 13 of 15 suppliers concentrated
   in Domestic/Asia-Pacific, consider qualifying at least one additional
   European or Latin American supplier for key categories.
8. **Pre-build Nov-Dec inventory using the demand forecast**, not last year's
   raw numbers alone, to reduce peak-season stockout risk.
9. **Apply the ABC classification operationally**: tighten safety stock and
   reorder frequency for the 26 A-tier SKUs; relax it for C-tier SKUs to free
   up working capital.
10. **Review Furniture category supplier and demand risk specifically**, given
    its outsized 36% revenue concentration.
11. **Separate the stockout root-cause narrative from the supplier-performance
    narrative in leadership reporting** — conflating them (as an initial
    intuition might) would misallocate fix effort.
12. **Track the Online vs. Store perfect-order-rate gap as a standing KPI**
    until it closes, not just as a one-time finding.
13. **Re-run the supplier reliability analysis quarterly** to catch a
    deteriorating supplier trend before it becomes a stockout problem.
14. **Use the regional order-processing time data to inform warehouse staffing
    allocation**, not just as a reporting metric.
15. **Prioritize Recommendations 1 and 2 as the two highest-confidence,
    highest-leverage initiatives** — both are backed by the strongest, most
    differentiated evidence in this analysis.

---

## 10 Quick Wins (Low Cost / Fast to Implement)

1. Share the Online vs. Store perfect-order-rate gap with e-commerce
   operations leadership as a standalone finding — the gap essentially makes
   the case for investigation on its own.
2. Add the ABC classification (Query 1) as a permanent column in the product
   master data system — a one-time analytical exercise turned into an ongoing
   operational tool.
3. Flag the "100% overstock flagged" threshold issue to whoever owns that
   report today, before any business decision gets made on flawed output.
4. Publish the supplier on-time ranking internally ahead of the next
   procurement review meeting.
5. Add the demand forecast's Nov-Dec figures directly into the purchasing
   team's planning worksheet for the upcoming season.
6. Start a pilot investigation into Online order processing at a single
   region before committing to a network-wide process change.
7. Share the "supplier lead time doesn't significantly predict stockouts"
   finding with whoever currently owns supplier-performance-focused stockout
   initiatives, to help redirect effort.
8. Add a simple "days since last order" flag to the C-tier product report to
   support faster discontinuation decisions.
9. Benchmark Northeast's order processing time against Pacific NW's
   internally, as a template before any process redesign.
10. Present the ABC revenue-concentration chart in the next leadership
    meeting as a simple, visual case for differentiated inventory policy.

---

## 10 Long-Term Improvement Opportunities

1. Build a proper overstock/excess-inventory model once real inventory-aging
   data (not just a single snapshot comparison) is available.
2. Develop a formal supplier scorecard program combining on-time delivery,
   fill accuracy, and (with more data) quality/defect rates into a
   standardized quarterly review.
3. Invest in warehouse management system integration to replace the current
   relative capacity index with real, benchmarkable utilization data.
4. Build a proper causal analysis (e.g., a controlled pilot) of *why* Online
   fulfillment underperforms Store, rather than only measuring the gap.
5. Develop category-specific demand forecasting models instead of one
   network-wide seasonal model, given Furniture's outsized influence on the
   aggregate pattern.
6. Explore supplier diversification into underrepresented sourcing regions
   as a multi-year strategic sourcing initiative.
7. Build a proper safety-stock optimization model (not a flat 25% of base
   stock) informed by each product's actual demand variability.
8. Establish a formal quarterly supply chain KPI review cadence tying this
   dashboard's metrics to procurement and operations performance reviews.
9. Investigate whether promised delivery dates themselves are set
   realistically — if suppliers are promised unrealistic lead times
   industry-wide, that's a planning fix, not just a supplier performance issue.
10. Revisit this analysis annually as real data accumulates, tracking whether
    the Online fulfillment and stockout initiatives above actually moved the
    metrics.

---

## Critical Assessment & Next Steps

A supply chain analysis that stops at "here are the dashboards" isn't finished —
here's what I'd flag before this reaches executive leadership, and what I'd do
differently with more time or access.

**Limitations of this analysis:**
- **This dataset is entirely synthetic.** Real combined supplier/warehouse/
  order-level supply chain data at this granularity isn't available as a public
  dataset. The generator was built with deliberate, documented realistic
  patterns (ABC-skewed velocity, variable supplier reliability, seasonal demand)
  — but every number here is illustrative, not a real distribution network's
  actual performance.
- **Three calibration artifacts were identified and reported honestly rather
  than hidden:** (1) absolute inventory turnover figures run unrealistically
  low because synthetic on-hand inventory levels weren't calibrated against
  real demand throughput — only the relative A-vs-C comparison is treated as
  meaningful; (2) warehouse capacity utilization is reported as a relative
  index only, for the same reason; (3) the overstock-detection threshold
  flagged literally all 198 products, meaning that specific analysis needs
  recalibration before it has any decision-making value — this is stated
  plainly rather than presented as a real finding.
- **The supplier lead-time root-cause test came back non-significant**
  (p=0.097). This was tested directly, not assumed, and the honest result
  redirects the recommendation priority toward inventory/forecasting fixes
  over supplier-focused fixes for the stockout problem specifically.
- **No dollar-cost figures are attached to the recommendations** in this
  version — quantifying the financial impact of, say, closing the Online
  fulfillment gap would require real network cost/margin data this project
  doesn't have access to, similar to the Meridian Health project's approach.

**What I'd do with more time or access:**
- Fix the overstock-detection threshold using a proper statistical method
  (e.g., comparing on-hand inventory to a demand-variability-adjusted
  reorder point) rather than a flat multiplier that flags everything.
- Investigate the Online fulfillment gap with real process data (order
  routing logs, warehouse pick-time data) rather than only the aggregate
  cycle-time metric available here.
- Replace the relative turnover and utilization indices with real inventory
  management system data, and validate the synthetic generator's calibration
  against published industry benchmarks.
- Build a proper safety-stock optimization model informed by each SKU's
  actual demand variability, rather than the flat 25%-of-base-stock rule
  used in this synthetic dataset.

I'd rather state these limitations plainly — including the analysis
techniques that didn't work as cleanly as hoped on the first pass — than let
a polished dashboard imply more certainty than a synthetic dataset, and an
imperfect first analytical pass, can actually support.
