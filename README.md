# Prism+ Loyalty Scheme — Strategic Review

## Introduction

Prism+ is a loyalty programme offered by Prism, a simulated e-commerce company. Launched on 1 January 2024, the scheme was designed with three goals in mind: increasing revenue by motivating customers to spend more to reach the next tier, improving customer loyalty through tiered discounts and free shipping, and driving word-of-mouth growth through a personalised referral code system.

This project analyses the results of a live A/B test run throughout 2024, comparing enrolled Prism+ members against a matched control group of eligible non-members. The analysis produces four data-grounded recommendations for the future of the scheme, along with a full financial impact assessment.

SQL Queries: [SQL folder](/SQL/)



## Scheme Design

Prism+ operates a four-tier progressive rewards structure. Tier assignment was based on the number of purchases made in the two years prior to launch (January 2022 – December 2023):

| Tier | Purchases Required | Discount | Free Shipping |
|---|---|---|---|
| Bronze | 1 | 5% | ✓ | 
| Silver | 2 | 10% | ✓ |
| Gold | 3 | 15% | ✓ |
| Platinum | 4+ | 20% | ✓ | 

Each member received a personalised referral code in the format `PRSMFRND-{user_crm_id}`, designed to encourage existing members to bring in new customers organically. Free shipping was applied across all tiers.

### Original scheme rationale
The scheme was built on three intended benefits:
- **Increased revenue** — tiered discounts motivate customers to spend more to reach the next tier, with the 20% Platinum discount designed to encourage repeat purchases
- **Improved customer loyalty** — free shipping across all tiers and continuous discount value keeps customers engaged
- **Word of mouth** — the PRSMFRND referral code encourages existing customers to expand the customer base organically



## Data

- **Platform:** Google BigQuery
- **Database:** `prism-insights.warehouse`
- **Tables:** `warehouse.users`, `warehouse.transactions`
- **Date range:** 1 January 2022 - 31 December 2024 
- **Pilot launch:** 1 January 2024
- **Tier assignment window:** 1 January 2022 – 31 December 2023
- **Analysis date range:** 1 January 2024 - 31 December 2024 

### Users table
`user_crm_id`, `city`, `user_gender`, `registration_date`, `latest_login_date`, `first_purchase_date`, `latest_purchase_date`, `opt_in_status`, `transaction_count`, `total_revenue`, `prism_plus_status`, `prism_plus_tier`

### Transactions table
`date`, `user_cookie_id`, `user_crm_id`, `session_id`, `transaction_id`, `transaction_coupon`, `transaction_revenue`, `transaction_shipping`, `transaction_total`



## A/B Test Methodology

### Eligibility criteria
Users were eligible for the A/B test if they:
- Registered before 2024
- Opted in to email marketing
- Made at least 1 purchase between January 2022 and December 2023

### Group assignment
- **Treatment group:** enrolled Prism+ members, assigned to a tier based on their 2022–2023 purchase history
- **Control group:** eligible non-members who met all criteria but were not enrolled

Groups were balanced at 11,319 users each, with equal numbers per tier. `ORDER BY user_crm_id` was used (not `RAND()`) to ensure consistent, reproducible group assignment across every query run.

### Balanced group sizes

| Tier | Treatment | Control | Total |
|---|---|---|---|
| Bronze | 7,512 | 7,512 | 15,024 |
| Silver | 2,192 | 2,192 | 4,384 |
| Gold | 797 | 797 | 1,594 |
| Platinum | 818 | 818 | 1,636 |
| **Total** | **11,319** | **11,319** | **22,638** |

### Tier naming convention
- Treatment: `Bronze`, `Silver`, `Gold`, `Platinum`
- Control: `bronze_control`, `silver_control`, `gold_control`, `platinum_control`


## Key Findings

### Segmentation
The two groups were well matched geographically — London (~42%), Birmingham (~15%), and Leeds (~8–9%) were near-identical across treatment and control, validating the integrity of the test groups. The treatment group skewed slightly more male (56.7% vs 47.7%), and 2,534 control users had unknown gender compared to zero in the treatment group, suggesting Prism+ members tend to have more complete profiles.

### Engagement and Behaviour (Jan–Dec 2024)

Prism+ members returned to purchase at up to 1.7× the rate of equivalent non-members across all tiers. Treatment AOV is lower than control across all tiers, reflecting the discount being applied — this is expected behaviour, not a negative signal.

| Group | Tier | Users | Purchase Rate | AOV | Net Revenue / User |
|---|---|---|---|---|---|
| Treatment | Bronze | 7,512 | 31.9% | £30.00 | £17.22 |
| Control | Bronze | 7,512 | 18.8% | £36.81 | £11.60 |
| Treatment | Silver | 2,192 | 43.5% | £29.50 | £29.81 |
| Control | Silver | 2,192 | 29.1% | £35.04 | £20.68 |
| Treatment | Gold | 797 | 52.7% | £29.90 | £41.94 |
| Control | Gold | 797 | 34.9% | £36.19 | £30.00 |
| Treatment | Platinum | 818 | 67.1% | £28.14 | £74.66 |
| Control | Platinum | 818 | 45.2% | £42.30 | £60.76 |

### Profitability (Jan–Dec 2024)

| Tier | Treatment Revenue | Control Revenue | Gross Uplift | Discount Cost | Net Uplift |
|---|---|---|---|---|---|
| Bronze | £129,411 | £87,103 | £42,308 | £6,811 | +£35,497 |
| Silver | £65,379 | £45,325 | £20,054 | £7,264 | +£12,790 |
| Gold | £33,421 | £23,911 | £9,510 | £5,898 | +£3,612 |
| Platinum | £61,068 | £49,700 | £11,368 | £15,267 | −£3,899 |
| **Total** | **£289,279** | **£206,039** | **£83,240** | **£35,240** | **+£48,000** |

> **Definitions:** Gross revenue uplift = Treatment revenue − Control revenue. Net revenue uplift = Gross revenue uplift − Discount cost. Free shipping costs could not be calculated from the available data — true costs are higher than shown.

> **Note on Platinum:** The negative net uplift requires careful interpretation. It could reflect a discount rate that is simply too generous, or it could reflect the fact that Platinum members are naturally high spenders who would have bought regardless of scheme membership. The A/B test design isolates the scheme effect, but the margin is thin enough that both interpretations remain plausible. This should be monitored closely in year two.

### Coupon Usage (Treatment Group, Jan–Dec 2024)

Between 7% and 17% of treatment transactions used PRSMFRND referral codes organically, with no incentive offered to the referrer:

| Tier | No Coupon | PRSMFRND Referral | Other |
|---|---|---|---|
| Bronze | 71.7% | 17.0% | 11.3% |
| Silver | 73.6% | 13.8% | 12.7% |
| Gold | 74.7% | 13.3% | 12.1% |
| Platinum | 80.1% | 7.4% | 12.6% |



## Extrapolation

There are 11,787 eligible non-members — control group users who meet all Prism+ eligibility criteria but are not yet enrolled. If enrolled, and they behave the same way as the treatment group, the projected net revenue uplift is:

| Tier | Eligible Users | Net Revenue Uplift / User | Projected Uplift |
|---|---|---|---|
| Bronze | 7,980 | +£4.7255 | +£37,709 |
| Silver | 2,192 | +£5.8346 | +£12,789 |
| Gold | 797 | +£4.5315 | +£3,612 |
| Platinum | 818 | −£4.7663 | −£3,899 |
| **Total** | **11,787** | | **+£50,211** |

### What cannot be reliably extrapolated
- **New customers:** the scheme was tested on pre-2024 registrants only — uplift may not apply to newly acquired customers
- **Non opted-in users:** the test covered opted-in users only — non opted-in users may respond differently
- **Future years:** 2024 covers year one only — loyalty effects may compound or diminish over time



## Recommendations

### 01 — Fix Platinum · Zane (CFO)
**Why:** Platinum is the only tier with a negative net uplift (−£3,899). The 20% discount cost (£15,267) wipes out the purchase frequency benefit entirely.

**Action:** Reduce the Platinum discount from 20% to 15% — the same rate as Gold, but differentiated by exclusive non-monetary perks (see recommendation 04). This reduces the discount cost from £15,267 to approximately £10,800, turning the net position from −£3,899 to approximately +£466.



### 02 — Enrol Eligible Non-Members · Zane (CFO)
**Why:** 11,787 opted-in eligible customers are not yet enrolled. They meet every eligibility criterion and are behaviourally identical to the treatment group.

**Action:** Run a targeted email campaign to eligible non-members by tier. Prioritise Bronze (7,980 users at the lowest discount cost of 5%). If enrolled, these users project a net revenue uplift of +£50,211, or +£54,110 with the Platinum fix applied.



### 03 — Incentivise Referrals · Asmee (CMO)
**Why:** Between 7% and 17% of treatment transactions already use PRSMFRND codes organically with no incentive to do so — the referral behaviour exists without being rewarded.

**Action:** Introduce a referral reward for the referrer — for example, a tier upgrade credit after 3 successful referrals, or a one-time discount on their next purchase.



### 04 — Redesign Upper-Tier Perks · Asmee (CMO)
**Why:** Gold and Platinum members are already high-frequency buyers. They don't need bigger discounts — they need perks that make membership feel genuinely premium and exclusive.

**Action:** Introduce non-monetary perks alongside the discount structure:
- **Gold:** free returns, early sale access
- **Platinum:** priority customer service, exclusive member events, birthday reward
- **Bronze / Silver:** retain existing discount structure



## Financial Impact

The financial impact assessment focuses on the non-member enrolment recommendation (recommendation 02), as it represents the clearest and most directly measurable opportunity. All figures are projected from observed A/B test behaviour.

### Definitions
- **Gross revenue uplift:** incremental revenue above the no-scheme baseline, before deducting discount costs. Calculated by applying the observed gross revenue uplift per user from the A/B test to each tier of eligible non-members: `(tier gross uplift ÷ treatment users) × eligible non-members`
- **Net revenue uplift:** gross revenue uplift minus discount cost
- **Discount cost:** derived from actual per-user discount costs observed in the A/B test (not AOV estimates), with Platinum adjusted to 15%

### ① Investment — Estimated Discount Cost

| Tier | Eligible Users | Per-User Discount Cost (from A/B data) | Projected Discount Cost |
|---|---|---|---|
| Bronze | 7,980 | £0.9066 | £7,235 |
| Silver | 2,192 | £3.3139 | £7,264 |
| Gold | 797 | £7.4003 | £5,898 |
| Platinum | 818 | £13.9978 (adjusted to 15%) | £11,450 |
| **Total** | | | **£31,847** |

### ② Incremental Gross Revenue

| Tier | Gross Uplift / User (from A/B data) | Eligible Users | Projected Gross Uplift |
|---|---|---|---|
| Bronze | £5.6322 | 7,980 | £44,945 |
| Silver | £9.1507 | 2,192 | £20,054 |
| Gold | £11.9322 | 797 | £9,510 |
| Platinum | £13.8972 | 818 | £11,368 |
| **Total** | | | **£85,877** |

**Net position: £85,877 − £31,847 = £54,030**

### ③ Payback Period
**Base case: ~4.4 months** (£31,847 ÷ £85,877 × 12)

### ④ Fragile Assumptions
1. The non-member control group will respond to enrolment the same way the A/B treatment group did
2. Platinum members will maintain their purchase frequency despite a 5pp discount reduction, with exclusive perks compensating — this cannot be confirmed from the existing A/B test data

### ⑤ Scenarios

| Scenario | Gross Uplift | Discount Cost | Net Position | Payback |
|---|---|---|---|---|
| Pessimistic | £42,939 | £31,847 | £11,092 | ~8.9 months |
| Base Case | £85,877 | £31,847 | £54,030 | ~4.4 months |
| Optimistic | £104,809 | £31,847 | £72,962 | ~3.6 months |

**Pessimistic:** 50% of forecast gross uplift materialises, Platinum fix not adopted, Bronze tier only enrolled. Discount cost held at full £31,847 as it is largely committed on enrolment.

**Optimistic:** Base case plus an additional £18,932 in incremental gross revenue from a referral reward that doubles the organic PRSMFRND usage rate (7–17%) already observed in the A/B data. The doubling assumption is supported by ReferralCandy's 2025 benchmark data, which shows that programmes with structured referral rewards and multiple visibility touchpoints consistently lift share rates meaningfully above organic baseline levels.

> **Note:** Free shipping costs are excluded from all figures — actual returns are understated. Net revenue uplift figures assume 2024 behavioural patterns hold — this cannot be guaranteed for future periods.


## Tools

| Tool | Purpose |
|---|---|
| Google BigQuery | Data warehousing and SQL querying |
| SQL | All data extraction, transformation, and analysis |
| PowerPoint | Presentation of findings to stakeholders |



## Limitations

- **Free shipping costs** cannot be quantified from the available data — true net revenue figures are overstated
- **Scope of test population:** the A/B test was conducted on pre-2024 opted-in registrants only — findings may not generalise to new customers or non opted-in users
- **Single year of data:** only one year is available — it is unknown whether loyalty effects compound or diminish over time
- **Platinum causality:** the negative net uplift may reflect a discount that is too generous, or it may reflect naturally high spending behaviour independent of the scheme — both remain plausible
- **Extrapolation assumption:** projected uplift figures assume non-members behave identically to the treatment group, which is untested
- **Optimistic scenario assumption:** the referral reward doubling organic usage is a reasoned projection, not an observed outcome
