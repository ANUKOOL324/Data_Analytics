/*
Banking Customer Lending Risk Analytics
File 1 - Schema and validation checks

Expected imported tables:
- public.banking_customer_profiles_clean
- public.banking_customer_loan_analytics_clean

These queries only read data. Run each numbered section separately in PostgreSQL.
*/

-- 1. Check that both expected tables exist.
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'banking_customer_profiles_clean',
      'banking_customer_loan_analytics_clean'
  )
ORDER BY table_name;


-- 2. Check customer profile table columns and data types.
SELECT
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'banking_customer_profiles_clean'
ORDER BY ordinal_position;


-- 3. Check loan analytics table columns and data types.
SELECT
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'banking_customer_loan_analytics_clean'
ORDER BY ordinal_position;


-- 4. Check expected row counts after importing the processed CSV files.
SELECT
    'customer_profiles' AS table_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM public.banking_customer_profiles_clean
UNION ALL
SELECT
    'loan_analytics' AS table_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM public.banking_customer_loan_analytics_clean;


-- 5. Check duplicate customer IDs in the customer profile table.
SELECT
    customer_id,
    COUNT(*) AS record_count
FROM public.banking_customer_profiles_clean
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, customer_id;


-- 6. Check duplicate loan IDs in the loan analytics table.
SELECT
    loan_id,
    COUNT(*) AS record_count
FROM public.banking_customer_loan_analytics_clean
GROUP BY loan_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, loan_id;


-- 7. Check if any loan rows do not match a customer profile row.
SELECT
    COUNT(*) AS loans_without_customer_profile
FROM public.banking_customer_loan_analytics_clean AS loan
LEFT JOIN public.banking_customer_profiles_clean AS customer
    ON loan.customer_id = customer.customer_id
WHERE customer.customer_id IS NULL;


-- 8. Check missing values in important customer fields.
SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL OR BTRIM(customer_id) = '') AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_name IS NULL OR BTRIM(customer_name) = '') AS missing_customer_name,
    COUNT(*) FILTER (WHERE age IS NULL) AS missing_age,
    COUNT(*) FILTER (WHERE gender IS NULL OR BTRIM(gender) = '') AS missing_gender,
    COUNT(*) FILTER (WHERE annual_income IS NULL) AS missing_annual_income,
    COUNT(*) FILTER (WHERE occupation IS NULL OR BTRIM(occupation) = '') AS missing_occupation,
    COUNT(*) FILTER (WHERE employment_status IS NULL OR BTRIM(employment_status) = '') AS missing_employment_status,
    COUNT(*) FILTER (WHERE customer_segment IS NULL OR BTRIM(customer_segment) = '') AS missing_customer_segment,
    COUNT(*) FILTER (WHERE total_deposit_balance IS NULL) AS missing_total_deposit_balance,
    COUNT(*) FILTER (WHERE credit_utilization_ratio IS NULL) AS missing_credit_utilization_ratio
FROM public.banking_customer_profiles_clean;


-- 9. Check missing values in important loan and risk fields.
SELECT
    COUNT(*) FILTER (WHERE loan_id IS NULL OR BTRIM(loan_id) = '') AS missing_loan_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL OR BTRIM(customer_id) = '') AS missing_customer_id,
    COUNT(*) FILTER (WHERE loan_type IS NULL OR BTRIM(loan_type) = '') AS missing_loan_type,
    COUNT(*) FILTER (WHERE loan_amount IS NULL) AS missing_loan_amount,
    COUNT(*) FILTER (WHERE credit_score IS NULL) AS missing_credit_score,
    COUNT(*) FILTER (WHERE debt_to_income_ratio IS NULL) AS missing_dti,
    COUNT(*) FILTER (WHERE loan_to_value_ratio IS NULL) AS missing_ltv,
    COUNT(*) FILTER (WHERE repayment_status IS NULL OR BTRIM(repayment_status) = '') AS missing_repayment_status,
    COUNT(*) FILTER (WHERE default_flag IS NULL) AS missing_default_flag,
    COUNT(*) FILTER (WHERE risk_band IS NULL OR BTRIM(risk_band) = '') AS missing_risk_band
FROM public.banking_customer_loan_analytics_clean;


-- 10. Check impossible or suspicious numeric values.
SELECT
    COUNT(*) FILTER (WHERE age < 18 OR age > 80) AS invalid_age,
    COUNT(*) FILTER (WHERE annual_income <= 0) AS invalid_annual_income,
    COUNT(*) FILTER (WHERE total_deposit_balance < 0) AS negative_total_deposits,
    COUNT(*) FILTER (WHERE credit_card_balance < 0) AS negative_credit_card_balance,
    COUNT(*) FILTER (WHERE credit_utilization_ratio < 0) AS negative_credit_utilization,
    COUNT(*) FILTER (WHERE credit_utilization_ratio > 1.5) AS very_high_credit_utilization
FROM public.banking_customer_profiles_clean;


-- 11. Check impossible or suspicious loan-risk values.
SELECT
    COUNT(*) FILTER (WHERE loan_amount <= 0) AS invalid_loan_amount,
    COUNT(*) FILTER (WHERE loan_term_months <= 0) AS invalid_loan_term,
    COUNT(*) FILTER (WHERE interest_rate <= 0) AS invalid_interest_rate,
    COUNT(*) FILTER (WHERE credit_score < 300 OR credit_score > 850) AS invalid_credit_score,
    COUNT(*) FILTER (WHERE debt_to_income_ratio < 0) AS negative_dti,
    COUNT(*) FILTER (WHERE loan_to_value_ratio < 0) AS negative_ltv,
    COUNT(*) FILTER (WHERE missed_payments_12m < 0) AS negative_missed_payments,
    COUNT(*) FILTER (WHERE days_past_due < 0) AS negative_days_past_due,
    COUNT(*) FILTER (WHERE default_flag NOT IN (0, 1)) AS invalid_default_flag
FROM public.banking_customer_loan_analytics_clean;


-- 12. Check the loan-level default distribution.
SELECT
    default_flag,
    COUNT(*) AS loan_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS loan_percentage
FROM public.banking_customer_loan_analytics_clean
GROUP BY default_flag
ORDER BY default_flag;


-- 13. Check customer-level loan/default coverage.
WITH customer_default_status AS (
    SELECT
        customer_id,
        MAX(default_flag) AS has_defaulted_loan
    FROM public.banking_customer_loan_analytics_clean
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS customers_with_loans,
    COUNT(*) FILTER (WHERE has_defaulted_loan = 1) AS customers_with_defaulted_loan,
    COUNT(*) FILTER (WHERE has_defaulted_loan = 0) AS customers_without_defaulted_loan,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE has_defaulted_loan = 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS customer_default_rate_percentage
FROM customer_default_status;


-- 14. Check customers with no loan record.
SELECT
    COUNT(*) AS customers_without_loans
FROM public.banking_customer_profiles_clean AS customer
LEFT JOIN public.banking_customer_loan_analytics_clean AS loan
    ON customer.customer_id = loan.customer_id
WHERE loan.customer_id IS NULL;


-- 15. Validate the individual-customer service segments.
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_percentage
FROM public.banking_customer_profiles_clean
GROUP BY customer_segment
ORDER BY
    CASE customer_segment
        WHEN 'Retail' THEN 1
        WHEN 'Priority' THEN 2
        WHEN 'Private Banking' THEN 3
        ELSE 4
    END;


-- 16. Confirm only the three allowed segments are present.
SELECT
    COUNT(*) FILTER (
        WHERE customer_segment NOT IN ('Retail', 'Priority', 'Private Banking')
           OR customer_segment IS NULL
    ) AS invalid_customer_segment_rows,
    COUNT(*) FILTER (WHERE customer_segment = 'Commercial') AS commercial_rows,
    COUNT(*) FILTER (WHERE customer_segment = 'Institutional') AS institutional_rows
FROM public.banking_customer_profiles_clean;


-- 17. Confirm the legacy banking_relationship column is absent.
SELECT
    COUNT(*) AS legacy_column_count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
      'banking_customer_profiles_clean',
      'banking_customer_loan_analytics_clean'
  )
  AND column_name = 'banking_relationship';
