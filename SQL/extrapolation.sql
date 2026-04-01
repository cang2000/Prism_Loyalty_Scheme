-- Extrapolation

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
  FROM `prism-insights.warehouse.users` AS u
  LEFT JOIN (
    SELECT
      user_crm_id,
      COUNT(DISTINCT transaction_id)                            AS transaction_count_past_2_years
    FROM `prism-insights.warehouse.transactions`
    WHERE date BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY user_crm_id
  ) AS t
    ON u.user_crm_id = t.user_crm_id
  WHERE u.registration_date < '2024-01-01'
    AND u.opt_in_status = TRUE
    AND t.transaction_count_past_2_years > 0
),
tier_mapping AS (
  SELECT 'bronze_control'   AS control_tier, 'Bronze'   AS treatment_tier UNION ALL
  SELECT 'silver_control'   AS control_tier, 'Silver'   AS treatment_tier UNION ALL
  SELECT 'gold_control'     AS control_tier, 'Gold'     AS treatment_tier UNION ALL
  SELECT 'platinum_control' AS control_tier, 'Platinum' AS treatment_tier
),
-- Full eligible population = treatment + control per tier
full_eligible AS (
  SELECT
    CASE
      WHEN prism_plus_status IS TRUE THEN prism_plus_tier
      ELSE tm.treatment_tier
    END                                                         AS tier,
    COUNT(*)                                                    AS eligible_users
  FROM prism_plus_experiment_user_setup p
  LEFT JOIN tier_mapping tm ON p.prism_plus_tier = tm.control_tier
  GROUP BY 1
),
-- Net uplift per user from the balanced A/B test
ab_test_results AS (
  SELECT 'Bronze'   AS tier, 7512  AS test_users, 35497.61  AS net_uplift UNION ALL
  SELECT 'Silver'   AS tier, 2192  AS test_users, 12789.42  AS net_uplift UNION ALL
  SELECT 'Gold'     AS tier, 797   AS test_users, 3611.59   AS net_uplift UNION ALL
  SELECT 'Platinum' AS tier, 818   AS test_users, -3898.83  AS net_uplift
)
SELECT
  ab.tier,
  fe.eligible_users                                             AS full_eligible_users,
  ROUND(ab.net_uplift, 0)                                       AS ab_net_uplift,
  ROUND(ab.net_uplift / ab.test_users, 2)                       AS net_uplift_per_user,
  -- Full rollout projection
  ROUND((ab.net_uplift / ab.test_users) * fe.eligible_users, 0) AS projected_net_uplift,
FROM ab_test_results ab
JOIN full_eligible fe ON ab.tier = fe.tier
ORDER BY
  CASE ab.tier
    WHEN 'Bronze'   THEN 1
    WHEN 'Silver'   THEN 2
    WHEN 'Gold'     THEN 3
    WHEN 'Platinum' THEN 4
  END