/*
Banking Customer Lending Risk Analytics
File 2 - Customer and segment analysis

Main table:
- public.banking_customer_profiles_clean

These queries explain who the customers are before looking at loan risk.
Run each numbered section separately in PostgreSQL.
*/

-- 1. Overall customer profile summary.
SELECT
    COUNT(*) AS total_customers,
    ROUND(AVG(age)::numeric, 2) AS average_age,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY age)::numeric, 2) AS median_age,
    ROUND(AVG(annual_income)::numeric, 2) AS average_annual_income,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)::numeric, 2) AS median_annual_income,
    ROUND(AVG(total_deposit_balance)::numeric, 2) AS average_total_deposits,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_deposit_balance)::numeric, 2) AS median_total_deposits,
    ROUND(AVG(customer_tenure_years)::numeric, 2) AS average_tenure_years
FROM public.banking_customer_profiles_clean;


-- 2. Customer count by age group.
SELECT
    age_group,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(annual_income)::numeric, 2) AS average_income,
    ROUND(AVG(total_deposit_balance)::numeric, 2) AS average_deposits
FROM public.banking_customer_profiles_clean
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN '18-24' THEN 1
        WHEN '25-34' THEN 2
        WHEN '35-44' THEN 3
        WHEN '45-54' THEN 4
        WHEN '55-64' THEN 5
        WHEN '65+' THEN 6
        ELSE 7
    END;


-- 3. Customer count by gender.
SELECT
    gender,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)::numeric, 2) AS median_income,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_deposit_balance)::numeric, 2) AS median_deposits
FROM public.banking_customer_profiles_clean
GROUP BY gender
ORDER BY customers DESC;


-- 4. Customer count and balances by banking relationship.
SELECT
    banking_relationship,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(customer_tenure_years)::numeric, 2) AS average_tenure_years,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)::numeric, 2) AS median_income,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_deposit_balance)::numeric, 2) AS median_deposits,
    ROUND(SUM(total_deposit_balance)::numeric, 2) AS total_deposits
FROM public.banking_customer_profiles_clean
GROUP BY banking_relationship
ORDER BY total_deposits DESC;


-- 5. Customer count and balances by loyalty classification.
SELECT
    loyalty_classification,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(customer_tenure_years)::numeric, 2) AS average_tenure_years,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_deposit_balance)::numeric, 2) AS median_deposits,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)::numeric, 2) AS median_income
FROM public.banking_customer_profiles_clean
GROUP BY loyalty_classification
ORDER BY customers DESC;


-- 6. Income band profile.
SELECT
    income_band,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)::numeric, 2) AS median_income,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_deposit_balance)::numeric, 2) AS median_deposits,
    ROUND(AVG(credit_utilization_ratio)::numeric, 4) AS average_credit_utilization
FROM public.banking_customer_profiles_clean
GROUP BY income_band
ORDER BY
    CASE income_band
        WHEN 'Low Income' THEN 1
        WHEN 'Lower Middle Income' THEN 2
        WHEN 'Middle Income' THEN 3
        WHEN 'Upper Middle Income' THEN 4
        WHEN 'High Income' THEN 5
        ELSE 6
    END;


-- 7. Employment status profile.
SELECT
    employment_status,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)::numeric, 2) AS median_income,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_deposit_balance)::numeric, 2) AS median_deposits
FROM public.banking_customer_profiles_clean
GROUP BY employment_status
ORDER BY customers DESC;


-- 8. Top occupations by customer count and deposits.
SELECT
    occupation,
    COUNT(*) AS customers,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)::numeric, 2) AS median_income,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_deposit_balance)::numeric, 2) AS median_deposits,
    ROUND(SUM(total_deposit_balance)::numeric, 2) AS total_deposits
FROM public.banking_customer_profiles_clean
GROUP BY occupation
ORDER BY customers DESC, total_deposits DESC
LIMIT 15;


-- 9. Credit utilization profile.
SELECT
    credit_utilization_band,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(credit_utilization_ratio)::numeric, 4) AS average_credit_utilization,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY credit_card_balance)::numeric, 2) AS median_credit_card_balance,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_deposit_balance)::numeric, 2) AS median_deposits
FROM public.banking_customer_profiles_clean
GROUP BY credit_utilization_band
ORDER BY
    CASE credit_utilization_band
        WHEN 'Low' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 10. Relationship and loyalty cross-tab.
SELECT
    banking_relationship,
    loyalty_classification,
    COUNT(*) AS customers,
    ROUND(AVG(total_deposit_balance)::numeric, 2) AS average_deposits,
    ROUND(AVG(annual_income)::numeric, 2) AS average_income
FROM public.banking_customer_profiles_clean
GROUP BY banking_relationship, loyalty_classification
ORDER BY banking_relationship, customers DESC;


-- 11. Advisor portfolio size and average customer value.
SELECT
    investment_advisor,
    COUNT(*) AS assigned_customers,
    ROUND(SUM(total_deposit_balance)::numeric, 2) AS managed_deposits,
    ROUND(AVG(total_deposit_balance)::numeric, 2) AS average_customer_deposits,
    ROUND(AVG(annual_income)::numeric, 2) AS average_customer_income
FROM public.banking_customer_profiles_clean
GROUP BY investment_advisor
ORDER BY managed_deposits DESC;