CUSTOMER SEGMENTS -- Recency calculation 
WITH recency_data AS ( 
SELECT 
user_crm_id, 
latest_purchase_date, 
DATE_DIFF((SELECT MAX(latest_purchase_date) FROM 
`prism-insights.warehouse_PT.users`), latest_purchase_date, MONTH) AS Recency 
FROM `prism-insights.warehouse_PT.users` 
), 
recency_score_data AS ( 
SELECT 
user_crm_id, 
latest_purchase_date, 
CASE 
WHEN Recency BETWEEN 0 AND 2 THEN 1  -- Score 1 for 0 to 2 months --when Recency > PERCENTILE_CONT(Recency, 0.80) OVER() then 1 
WHEN Recency BETWEEN 3 AND 6 THEN 2  -- Score 2 for 3 to 6 months --when Recency > PERCENTILE_CONT(Recency, 0.50) OVER() then 2 
ELSE 3                               
END AS recency_score 
FROM recency_data 
), -- Frequency calculation 
frequency_data AS ( 
SELECT 
user_crm_id, -- Score 3 for more than 6 months 
COUNT(DISTINCT transaction_id) AS purchase_count 
FROM `prism-insights.warehouse_PT.transactions` 
WHERE user_crm_id IS NOT NULL 
GROUP BY user_crm_id 
), 
frequency_score_data AS ( 
SELECT 
user_crm_id, 
CASE --WHEN purchase_count >= 10 THEN 1  -- High frequency users 
when purchase_count > PERCENTILE_CONT(purchase_count, 0.90) OVER() then 
1 --WHEN purchase_count BETWEEN 5 AND 9 THEN 2  -- Medium frequency 
when purchase_count > PERCENTILE_CONT(purchase_count, 0.7) OVER() then 2 
ELSE 3  -- Low frequency 
END AS frequency_score 
FROM frequency_data 
), -- Monetary value calculation (rule based) 
monetary_data AS ( 
SELECT 
user_crm_id, 
ROUND(SUM(transaction_total), 0) AS total_spent 
FROM `prism-insights.warehouse_PT.transactions` 
WHERE user_crm_id IS NOT NULL 
GROUP BY user_crm_id 
), 
monetary_score_data AS ( 
SELECT 
user_crm_id, 
total_spent, 
CASE --WHEN total_spent > 100 THEN 1  -- High spenders 
when total_spent > PERCENTILE_CONT(total_spent, 0.80) OVER() then 1 --WHEN total_spent > 30 THEN 2   -- Medium spenders 
when total_spent > PERCENTILE_CONT(total_spent, 0.50) OVER() then 2 
ELSE 3                         
END AS monetary_score 
FROM monetary_data 
), --  Combined RFM segments 
combined_rfm AS ( 
SELECT 
r.user_crm_id, 
r.recency_score, 
f.frequency_score, 
m.monetary_score, -- Low spenders 
(r.recency_score + f.frequency_score + m.monetary_score) AS total_score 
FROM recency_score_data r 
LEFT JOIN frequency_score_data f ON r.user_crm_id = f.user_crm_id 
LEFT JOIN monetary_score_data m ON r.user_crm_id = m.user_crm_id 
), -- Segment classification 
segment_data AS ( 
SELECT 
user_crm_id, 
CASE 
WHEN total_score = 3 THEN '1 - Trendy' 
WHEN total_score = 4 THEN '2 - Regular Loyalist' 
WHEN total_score = 5 THEN '3 - Engaged Shoppers' 
WHEN total_score = 6 THEN '4 - Casual Buyers' 
WHEN total_score = 7 THEN '5 - Lapsed Customers' 
WHEN total_score = 8 THEN '6 - At-Risk Buyers' 
ELSE '7 - Lost Causes' 
END AS segment 
FROM combined_rfm 
LEFT JOIN monetary_data 
USING (user_crm_id) 
), 
main as( 
SELECT 
u.user_crm_id, 
s.total_spent, 
u.city, 
u.user_gender, 
freq.purchase_count, 
u.latest_purchase_date, 
seg.segment 
FROM `prism-insights.warehouse_PT.users` u 
LEFT JOIN monetary_data s ON u.user_crm_id = s.user_crm_id 
LEFT JOIN segment_data seg ON u.user_crm_id = seg.user_crm_id 
LEFT JOIN frequency_data freq ON u.user_crm_id = freq.user_crm_id 
ORDER BY user_crm_id 
) 
select segment, count(*) 
from main 
group by 1 
order by 1 
Cust_segments_1.1 -- Recency calculation 
WITH recency_data AS ( 
SELECT 
user_crm_id, 
latest_purchase_date, 
DATE_DIFF((SELECT MAX(latest_purchase_date) FROM 
`prism-insights.warehouse_PT.users`), latest_purchase_date, MONTH) AS Recency 
FROM `prism-insights.warehouse_PT.users` 
), 
recency_score_data AS ( 
SELECT 
user_crm_id, 
latest_purchase_date, 
CASE 
WHEN Recency BETWEEN 0 AND 2 THEN 1  -- Score 1 for 0 to 2 months --when Recency > PERCENTILE_CONT(Recency, 0.80) OVER() then 1 
WHEN Recency BETWEEN 3 AND 6 THEN 2  -- Score 2 for 3 to 6 months --when Recency > PERCENTILE_CONT(Recency, 0.50) OVER() then 2 
ELSE 3                               
END AS recency_score 
FROM recency_data 
), -- Frequency calculation 
frequency_data AS ( 
SELECT 
user_crm_id, -- Score 3 for more than 6 months 
COUNT(DISTINCT transaction_id) AS purchase_count 
FROM `prism-insights.warehouse_PT.transactions` 
WHERE user_crm_id IS NOT NULL 
GROUP BY user_crm_id 
), 
frequency_score_data AS ( 
SELECT 
user_crm_id, 
CASE --WHEN purchase_count >= 10 THEN 1  -- High frequency users 
when purchase_count > PERCENTILE_CONT(purchase_count, 0.90) OVER() then 
1 
), --WHEN purchase_count BETWEEN 5 AND 9 THEN 2  -- Medium frequency 
when purchase_count > PERCENTILE_CONT(purchase_count, 0.7) OVER() then 2 
ELSE 3  -- Low frequency 
END AS frequency_score 
FROM frequency_data -- Monetary value calculation (rule based) 
monetary_data AS ( 
SELECT 
user_crm_id, 
ROUND(SUM(transaction_total), 0) AS total_spent 
FROM `prism-insights.warehouse_PT.transactions` 
WHERE user_crm_id IS NOT NULL 
GROUP BY user_crm_id 
), 
monetary_score_data AS ( 
SELECT 
user_crm_id, 
total_spent, 
CASE --WHEN total_spent > 100 THEN 1  -- High spenders 
when total_spent > PERCENTILE_CONT(total_spent, 0.80) OVER() then 1 --WHEN total_spent > 30 THEN 2   -- Medium spenders 
when total_spent > PERCENTILE_CONT(total_spent, 0.50) OVER() then 2 
ELSE 3                         -- Low spenders 
END AS monetary_score 
FROM monetary_data 
), --  Combined RFM segments 
combined_rfm AS ( 
SELECT 
r.user_crm_id, 
r.recency_score, 
f.frequency_score, 
m.monetary_score, 
(r.recency_score + f.frequency_score + m.monetary_score) AS total_score 
FROM recency_score_data r 
LEFT JOIN frequency_score_data f ON r.user_crm_id = f.user_crm_id 
LEFT JOIN monetary_score_data m ON r.user_crm_id = m.user_crm_id 
), -- Segment classification 
segment_data AS ( 
SELECT 
user_crm_id, 
CASE 
WHEN total_score = 3 THEN '1 - Trendy' 
WHEN total_score = 4 THEN '2 - Regular Loyalist' 
WHEN total_score = 5 THEN '3 - Engaged Shoppers' 
WHEN total_score = 6 THEN '4 - Casual Buyers' 
WHEN total_score = 7 THEN '5 - Lapsed Customers' 
WHEN total_score = 8 THEN '6 - At-Risk Buyers' 
ELSE '7 - Lost Causes' 
END AS segment 
FROM combined_rfm 
LEFT JOIN monetary_data 
USING (user_crm_id) 
), 
main as( 
SELECT 
u.user_crm_id, 
s.total_spent, 
u.city, 
u.user_gender, 
freq.purchase_count, 
u.latest_purchase_date, 
seg.segment 
FROM `prism-insights.warehouse_PT.users` u 
LEFT JOIN monetary_data s ON u.user_crm_id = s.user_crm_id 
LEFT JOIN segment_data seg ON u.user_crm_id = seg.user_crm_id 
LEFT JOIN frequency_data freq ON u.user_crm_id = freq.user_crm_id 
ORDER BY user_crm_id 
) 
SELECT 
user_crm_id, 
total_spent, 
city, 
user_gender, 
purchase_count, 
latest_purchase_date, 
segment 
FROM main 
ORDER BY user_crm_id 
Demographics 
SELECT user_crm_id,city, user_gender, registration_date, prism_plus_tier FROM 
`prism-insights.warehouse_PT.users`   
Sessions: 
SELECT user_crm_id,session_id, traffic_source FROM 
`prism-insights.warehouse_PT.sessions`  where user_crm_id is not null 
