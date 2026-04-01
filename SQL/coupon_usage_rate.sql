-- Post-launch coupon usage rate

WITH prism_plus_experiment_user_setup AS (
  SELECT
    u.user_crm_id,
    u.prism_plus_status,
    CASE
      WHEN u.prism_plus_status IS TRUE THEN u.prism_plus_tier
      WHEN COALESCE(t.transaction_count_past_2_years, 0) = 1  THEN 'bronze_control'
      WHEN COALESCE(t.transaction_count_past_2_years, 0) = 2  THEN 'silver_control'
      WHEN COALESCE(t.transaction_count_past_2_years, 0) = 3  THEN 'gold_control'
      WHEN COALESCE(t.transaction_count_past_2_years, 0) >= 4 THEN 'platinum_control'
    END                                                         AS prism_plus_tier,
    COALESCE(t.transaction_count_past_2_years, 0)               AS transaction_count_past_2_years
  FROM `prism-insights.warehouse.users` u
  LEFT JOIN (
    SELECT
      user_crm_id,
      COUNT(DISTINCT transaction_id)                            AS transaction_count_past_2_years
    FROM `prism-insights.warehouse.transactions`
    WHERE date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY user_crm_id
  ) t
    ON u.user_crm_id = t.user_crm_id
  WHERE u.registration_date < '2024-01-01'
    AND u.opt_in_status = TRUE
    AND t.transaction_count_past_2_years > 0
),
treatment AS (
  SELECT * FROM prism_plus_experiment_user_setup
  WHERE prism_plus_status IS TRUE
),
control AS (
  SELECT * FROM prism_plus_experiment_user_setup
  WHERE prism_plus_status IS FALSE
),
tier_mapping AS (
  SELECT 'bronze_control'   AS control_tier, 'Bronze'   AS treatment_tier UNION ALL
  SELECT 'silver_control'   AS control_tier, 'Silver'   AS treatment_tier UNION ALL
  SELECT 'gold_control'     AS control_tier, 'Gold'     AS treatment_tier UNION ALL
  SELECT 'platinum_control' AS control_tier, 'Platinum' AS treatment_tier
),
treatment_counts AS (
  SELECT prism_plus_tier, COUNT(*) AS n
  FROM treatment
  GROUP BY prism_plus_tier
),
control_counts AS (
  SELECT tm.treatment_tier AS prism_plus_tier, COUNT(*) AS n
  FROM control c
  JOIN tier_mapping tm ON c.prism_plus_tier = tm.control_tier
  GROUP BY 1
),
target_counts AS (
  SELECT
    t.prism_plus_tier,
    LEAST(t.n, c.n)                                             AS target_n
  FROM treatment_counts t
  JOIN control_counts c ON t.prism_plus_tier = c.prism_plus_tier
),
treatment_ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY prism_plus_tier
      ORDER BY user_crm_id
    )                                                           AS rn
  FROM treatment
),
control_ranked AS (
  SELECT
    c.*,
    tm.treatment_tier                                           AS treatment_tier_key,
    ROW_NUMBER() OVER (
      PARTITION BY c.prism_plus_tier
      ORDER BY c.user_crm_id
    )                                                           AS rn
  FROM control c
  JOIN tier_mapping tm ON c.prism_plus_tier = tm.control_tier
),
balanced_treatment AS (
  SELECT
    tr.user_crm_id, tr.prism_plus_status, tr.prism_plus_tier,
    tr.transaction_count_past_2_years
  FROM treatment_ranked tr
  JOIN target_counts tc ON tr.prism_plus_tier = tc.prism_plus_tier
  WHERE tr.rn <= tc.target_n
),
balanced_control AS (
  SELECT
    cr.user_crm_id, cr.prism_plus_status, cr.prism_plus_tier,
    cr.transaction_count_past_2_years
  FROM control_ranked cr
  JOIN target_counts tc ON cr.treatment_tier_key = tc.prism_plus_tier
  WHERE cr.rn <= tc.target_n
),
final AS (
  SELECT * FROM balanced_treatment
  UNION ALL
  SELECT * FROM balanced_control
),
post_launch_transactions AS (
  SELECT *
  FROM `prism-insights.warehouse.transactions`
  WHERE date BETWEEN '2024-01-01' AND '2024-12-31'
),
classified_transactions AS (
  SELECT
    t.user_crm_id,
    t.transaction_id,
    f.prism_plus_tier,
    CASE
      WHEN t.transaction_coupon LIKE 'PRSMFRND%'             THEN 'PRSMFRND'
      WHEN t.transaction_coupon IS NOT NULL
        AND t.transaction_coupon != ''                        THEN 'Other Coupon'
      ELSE                                                         'No Coupon'
    END                                                       AS coupon_type
  FROM post_launch_transactions t
  JOIN final f ON t.user_crm_id = f.user_crm_id
  WHERE f.prism_plus_status IS TRUE
),
aggregated AS (
  SELECT
    CASE prism_plus_tier
      WHEN 'Bronze'   THEN 'Bronze'
      WHEN 'Silver'   THEN 'Silver'
      WHEN 'Gold'     THEN 'Gold'
      WHEN 'Platinum' THEN 'Platinum'
    END                                                       AS tier,
    coupon_type,
    COUNT(DISTINCT transaction_id)                            AS transactions
  FROM classified_transactions
  GROUP BY 1, 2
)
SELECT
  tier,
  coupon_type,
  transactions,
  ROUND(
    transactions * 100.0 /
    SUM(transactions) OVER (PARTITION BY tier), 2)            AS pct_of_transactions
FROM aggregated
ORDER BY
  CASE tier
    WHEN 'Bronze'   THEN 1
    WHEN 'Silver'   THEN 2
    WHEN 'Gold'     THEN 3
    WHEN 'Platinum' THEN 4
  END,
  coupon_type