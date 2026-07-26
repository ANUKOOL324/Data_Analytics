/*
Banking Customer Lending Risk Analytics
File 3 - Financial exposure, repayment and default-risk analysis

Main table:
- public.banking_customer_loan_analytics_clean

This table already includes customer profile fields joined with loan and risk fields.
Run each numbered section separately in PostgreSQL.
*/

-- 1. Overall loan portfolio summary.
SELECT
    COUNT(*) AS total_loans,
    COUNT(DISTINCT customer_id) AS customers_with_loans,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS total_exposure_crore,
    ROUND(AVG(loan_amount)::numeric, 2) AS average_loan_amount,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY loan_amount)::numeric, 2) AS median_loan_amount,
    ROUND(AVG(interest_rate)::numeric, 2) AS average_interest_rate,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(SUM(expected_loss_amount)::numeric / 10000000, 2) AS expected_loss_crore
FROM public.banking_customer_loan_analytics_clean;


-- 2. Repayment status distribution.
SELECT
    repayment_status,
    COUNT(*) AS loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS loan_percentage,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore,
    ROUND(SUM(expected_loss_amount)::numeric / 10000000, 2) AS expected_loss_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY repayment_status
ORDER BY loans DESC;


-- 3. Default and non-default loan counts.
SELECT
    default_flag,
    CASE WHEN default_flag = 1 THEN 'Default' ELSE 'Not Default' END AS default_status,
    COUNT(*) AS loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS loan_percentage,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY default_flag
ORDER BY default_flag DESC;


-- 4. Exposure and default rate by loan type.
SELECT
    loan_type,
    COUNT(*) AS loans,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY loan_amount)::numeric, 2) AS median_loan_amount,
    ROUND(AVG(interest_rate)::numeric, 2) AS average_interest_rate,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(SUM(expected_loss_amount)::numeric / 10000000, 2) AS expected_loss_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY loan_type
ORDER BY exposure_crore DESC;


-- 5. Risk band summary.
SELECT
    risk_band,
    COUNT(*) AS loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS loan_percentage,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(AVG(credit_score)::numeric, 2) AS average_credit_score,
    ROUND(AVG(debt_to_income_ratio)::numeric, 2) AS average_dti,
    ROUND(AVG(loan_to_value_ratio)::numeric, 2) AS average_ltv,
    ROUND(SUM(expected_loss_amount)::numeric / 10000000, 2) AS expected_loss_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY risk_band
ORDER BY
    CASE risk_band
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END;


-- 6. Default rate by debt-to-income band.
SELECT
    dti_band,
    COUNT(*) AS loans,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(AVG(credit_score)::numeric, 2) AS average_credit_score,
    ROUND(AVG(loan_amount)::numeric, 2) AS average_loan_amount,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY dti_band
ORDER BY
    CASE dti_band
        WHEN '<= 30%' THEN 1
        WHEN '30% - 45%' THEN 2
        WHEN '45% - 60%' THEN 3
        WHEN '> 60%' THEN 4
        ELSE 5
    END;


-- 7. Default rate by credit score band.
SELECT
    credit_score_band,
    COUNT(*) AS loans,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(AVG(debt_to_income_ratio)::numeric, 2) AS average_dti,
    ROUND(AVG(loan_to_value_ratio)::numeric, 2) AS average_ltv,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY credit_score_band
ORDER BY
    CASE credit_score_band
        WHEN 'Poor' THEN 1
        WHEN 'Fair' THEN 2
        WHEN 'Good' THEN 3
        WHEN 'Very Good' THEN 4
        WHEN 'Excellent' THEN 5
        ELSE 6
    END;


-- 8. Default rate by loan-to-value band.
SELECT
    ltv_band,
    COUNT(*) AS loans,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(AVG(credit_score)::numeric, 2) AS average_credit_score,
    ROUND(AVG(debt_to_income_ratio)::numeric, 2) AS average_dti,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY ltv_band
ORDER BY
    CASE ltv_band
        WHEN '<= 50%' THEN 1
        WHEN '50% - 70%' THEN 2
        WHEN '70% - 90%' THEN 3
        WHEN '> 90%' THEN 4
        ELSE 5
    END;


-- 9. Recent delinquency versus default.
SELECT
    has_recent_delinquency,
    COUNT(*) AS loans,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS loan_percentage,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(AVG(missed_payments_12m)::numeric, 2) AS average_missed_payments_12m,
    ROUND(AVG(days_past_due)::numeric, 2) AS average_days_past_due,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY has_recent_delinquency
ORDER BY has_recent_delinquency DESC;


-- 10. Exposure and risk by individual customer service segment.
SELECT
    customer_segment,
    COUNT(*) AS loans,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(AVG(credit_score)::numeric, 2) AS average_credit_score,
    ROUND(AVG(debt_to_income_ratio)::numeric, 2) AS average_dti,
    ROUND(SUM(expected_loss_amount)::numeric / 10000000, 2) AS expected_loss_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY customer_segment
ORDER BY
    CASE customer_segment
        WHEN 'Retail' THEN 1
        WHEN 'Priority' THEN 2
        WHEN 'Private Banking' THEN 3
        ELSE 4
    END;


-- 11. Income band and risk band matrix.
SELECT
    income_band,
    risk_band,
    COUNT(*) AS loans,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(SUM(loan_amount)::numeric / 10000000, 2) AS exposure_crore
FROM public.banking_customer_loan_analytics_clean
GROUP BY income_band, risk_band
ORDER BY
    CASE income_band
        WHEN 'Low Income' THEN 1
        WHEN 'Lower Middle Income' THEN 2
        WHEN 'Middle Income' THEN 3
        WHEN 'Upper Middle Income' THEN 4
        WHEN 'High Income' THEN 5
        ELSE 6
    END,
    CASE risk_band
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END;


-- 12. Top high-risk default-monitoring cases.
SELECT
    loan_id,
    customer_id,
    customer_name,
    loan_type,
    ROUND(loan_amount::numeric, 2) AS loan_amount,
    ROUND(annual_income::numeric, 2) AS annual_income,
    credit_score,
    ROUND(debt_to_income_ratio::numeric, 2) AS dti,
    ROUND(loan_to_value_ratio::numeric, 2) AS ltv,
    missed_payments_12m,
    days_past_due,
    risk_band,
    repayment_status,
    default_flag,
    ROUND(expected_loss_amount::numeric, 2) AS expected_loss_amount
FROM public.banking_customer_loan_analytics_clean
ORDER BY
    default_flag DESC,
    expected_loss_amount DESC,
    days_past_due DESC,
    debt_to_income_ratio DESC
LIMIT 25;


-- 13. Model target readiness check.
SELECT
    COUNT(*) AS total_model_rows,
    COUNT(*) FILTER (WHERE default_flag = 1) AS default_rows,
    COUNT(*) FILTER (WHERE default_flag = 0) AS not_default_rows,
    ROUND(100.0 * AVG(default_flag::numeric), 2) AS default_rate_percentage,
    ROUND(
        COUNT(*) FILTER (WHERE default_flag = 0)::numeric
        / NULLIF(COUNT(*) FILTER (WHERE default_flag = 1), 0),
        2
    ) AS not_default_to_default_ratio
FROM public.banking_customer_loan_analytics_clean;