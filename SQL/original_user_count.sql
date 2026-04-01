-- User count for treatment and control group within each tier

WITH prism_plus_experiment_user_setup AS
(SELECT
   u.user_crm_id,
   u.city,
   u.user_gender,
   u.registration_date,
   u.latest_login_date,
   u.first_purchase_date,
   u.latest_purchase_date,
   u.opt_in_status,
   u.transaction_count,
   u.total_revenue,
   u.prism_plus_status,
 
 
   # Where prism_plus_status is not true, assign control tier based on transaction_count
   CASE
       WHEN u.prism_plus_status IS TRUE THEN u.prism_plus_tier
       WHEN COALESCE(t.transaction_count_past_2_years, 0) = 1  THEN 'bronze_control'
       WHEN COALESCE(t.transaction_count_past_2_years, 0) = 2  THEN 'silver_control'
       WHEN COALESCE(t.transaction_count_past_2_years, 0) = 3  THEN 'gold_control'
       WHEN COALESCE(t.transaction_count_past_2_years, 0) >= 4 THEN 'platinum_control'
   END AS prism_plus_tier,
 
 
   # Count of transactions in the last two years per user
   COALESCE(t.transaction_count_past_2_years, 0) AS transaction_count_past_2_years
 
 
FROM prism-insights.warehouse.users AS u
LEFT JOIN (
   SELECT
       user_crm_id,
       COUNT(DISTINCT transaction_id) AS transaction_count_past_2_years
   FROM prism-insights.warehouse.transactions
   WHERE date BETWEEN '2022-01-01' AND '2023-12-31'
   GROUP BY user_crm_id
) AS t
   ON u.user_crm_id = t.user_crm_id
WHERE registration_date < '2024-01-01'AND opt_in_status = TRUE AND t.transaction_count_past_2_years > 0)
 
 
SELECT prism_plus_tier, COUNT(*) as count_users
FROM prism_plus_experiment_user_setup
GROUP BY prism_plus_tier
ORDER BY count_users