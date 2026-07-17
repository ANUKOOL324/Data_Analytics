/*
Banking Customer Portfolio & Exposure Analytics
File 3 - Financial and recorded risk analysis

I use public.banking_customers in this file.
I count records because repeated client IDs have different details.
I treat risk_weighting only as an ordered field, not default probability.
I run each numbered query separately. These queries only read data.
*/

-- 1. I calculate the main totals, averages and medians.
SELECT
    ROUND(SUM(bank_deposits)::numeric, 2) AS total_bank_deposits,
    ROUND(AVG(bank_deposits)::numeric, 2) AS average_bank_deposits,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_deposits
        )::numeric,
        2
    ) AS median_bank_deposits,
    ROUND(SUM(bank_loans)::numeric, 2) AS total_bank_loans,
    ROUND(AVG(bank_loans)::numeric, 2) AS average_bank_loans,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_loans
        )::numeric,
        2
    ) AS median_bank_loans,
    ROUND(SUM(business_lending)::numeric, 2) AS total_business_lending,
    ROUND(AVG(business_lending)::numeric, 2) AS average_business_lending,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY business_lending
        )::numeric,
        2
    ) AS median_business_lending,
    ROUND(SUM(credit_card_balance)::numeric, 2) AS total_credit_card_balance,
    ROUND(AVG(credit_card_balance)::numeric, 2) AS average_credit_card_balance,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY credit_card_balance
        )::numeric,
        2
    ) AS median_credit_card_balance,
    ROUND(SUM(checking_accounts)::numeric, 2) AS total_checking_accounts,
    ROUND(AVG(checking_accounts)::numeric, 2) AS average_checking_accounts,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY checking_accounts
        )::numeric,
        2
    ) AS median_checking_accounts,
    ROUND(SUM(saving_accounts)::numeric, 2) AS total_saving_accounts,
    ROUND(AVG(saving_accounts)::numeric, 2) AS average_saving_accounts,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY saving_accounts
        )::numeric,
        2
    ) AS median_saving_accounts
FROM public.banking_customers;


-- 2. I compare financial values across income bands.
SELECT
    income_band,
    COUNT(*) AS customer_records,
    ROUND(SUM(bank_deposits)::numeric, 2) AS total_bank_deposits,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_deposits
        )::numeric,
        2
    ) AS median_bank_deposits,
    ROUND(SUM(bank_loans)::numeric, 2) AS total_bank_loans,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_loans
        )::numeric,
        2
    ) AS median_bank_loans,
    ROUND(SUM(business_lending)::numeric, 2) AS total_business_lending,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY business_lending
        )::numeric,
        2
    ) AS median_business_lending
FROM public.banking_customers
GROUP BY income_band
ORDER BY
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 3. I compare financial values across loyalty groups.
SELECT
    loyalty_classification,
    COUNT(*) AS customer_records,
    ROUND(SUM(bank_deposits)::numeric, 2) AS total_bank_deposits,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_deposits
        )::numeric,
        2
    ) AS median_bank_deposits,
    ROUND(SUM(bank_loans)::numeric, 2) AS total_bank_loans,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_loans
        )::numeric,
        2
    ) AS median_bank_loans,
    ROUND(SUM(business_lending)::numeric, 2) AS total_business_lending,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY business_lending
        )::numeric,
        2
    ) AS median_business_lending
FROM public.banking_customers
GROUP BY loyalty_classification
ORDER BY customer_records DESC, loyalty_classification;


-- 4. I compare financial values across BR groups.
SELECT
    CONCAT('BR ', brid) AS banking_relationship,
    COUNT(*) AS customer_records,
    ROUND(SUM(bank_deposits)::numeric, 2) AS total_bank_deposits,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_deposits
        )::numeric,
        2
    ) AS median_bank_deposits,
    ROUND(SUM(bank_loans)::numeric, 2) AS total_bank_loans,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_loans
        )::numeric,
        2
    ) AS median_bank_loans,
    ROUND(SUM(business_lending)::numeric, 2) AS total_business_lending,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY business_lending
        )::numeric,
        2
    ) AS median_business_lending
FROM public.banking_customers
GROUP BY brid
ORDER BY brid;


-- 5. I calculate the deposit-to-loan ratio for each record.
SELECT
    client_id,
    name AS customer_name,
    ROUND(bank_deposits::numeric, 2) AS bank_deposits,
    ROUND(bank_loans::numeric, 2) AS bank_loans,
    ROUND(
        (
            bank_deposits
            / NULLIF(bank_loans, 0)
        )::numeric,
        2
    ) AS deposit_to_loan_ratio
FROM public.banking_customers
ORDER BY deposit_to_loan_ratio DESC NULLS LAST, client_id;


-- 6. I calculate the loan-to-income ratio for each record.
SELECT
    client_id,
    name AS customer_name,
    ROUND(estimated_income::numeric, 2) AS estimated_income,
    ROUND(bank_loans::numeric, 2) AS bank_loans,
    ROUND(
        (
            bank_loans
            / NULLIF(estimated_income, 0)
        )::numeric,
        2
    ) AS bank_loan_to_income_ratio
FROM public.banking_customers
ORDER BY bank_loan_to_income_ratio DESC NULLS LAST, client_id;


-- 7. I calculate a simple lending-exposure proxy.
-- I use this only for this project; it is not a regulatory measure.
SELECT
    client_id,
    name AS customer_name,
    ROUND(bank_loans::numeric, 2) AS bank_loans,
    ROUND(business_lending::numeric, 2) AS business_lending,
    ROUND(credit_card_balance::numeric, 2) AS credit_card_balance,
    ROUND(
        (
            bank_loans
            + business_lending
            + credit_card_balance
        )::numeric,
        2
    ) AS recorded_lending_exposure
FROM public.banking_customers
ORDER BY recorded_lending_exposure DESC, client_id;


-- 8a. I find the top 10 records by bank deposits.
WITH ranked_deposits AS (
    SELECT
        client_id,
        name AS customer_name,
        bank_deposits,
        ROW_NUMBER() OVER (
            ORDER BY bank_deposits DESC, client_id
        ) AS deposit_rank
    FROM public.banking_customers
)
SELECT
    deposit_rank,
    client_id,
    customer_name,
    ROUND(bank_deposits::numeric, 2) AS bank_deposits
FROM ranked_deposits
WHERE deposit_rank <= 10
ORDER BY deposit_rank;


-- 8b. I find the top 10 records by bank loans.
WITH ranked_loans AS (
    SELECT
        client_id,
        name AS customer_name,
        bank_loans,
        ROW_NUMBER() OVER (
            ORDER BY bank_loans DESC, client_id
        ) AS loan_rank
    FROM public.banking_customers
)
SELECT
    loan_rank,
    client_id,
    customer_name,
    ROUND(bank_loans::numeric, 2) AS bank_loans
FROM ranked_loans
WHERE loan_rank <= 10
ORDER BY loan_rank;


-- 8c. I find the top 10 records by lending exposure.
WITH customer_exposure AS (
    SELECT
        client_id,
        name AS customer_name,
        bank_loans
            + business_lending
            + credit_card_balance AS recorded_lending_exposure
    FROM public.banking_customers
),
ranked_exposure AS (
    SELECT
        client_id,
        customer_name,
        recorded_lending_exposure,
        ROW_NUMBER() OVER (
            ORDER BY recorded_lending_exposure DESC, client_id
        ) AS exposure_rank
    FROM customer_exposure
)
SELECT
    exposure_rank,
    client_id,
    customer_name,
    ROUND(
        recorded_lending_exposure::numeric,
        2
    ) AS recorded_lending_exposure
FROM ranked_exposure
WHERE exposure_rank <= 10
ORDER BY exposure_rank;


-- 9. I divide deposit and loan values into four groups.
WITH customer_quartiles AS (
    SELECT
        client_id,
        name AS customer_name,
        bank_deposits,
        bank_loans,
        NTILE(4) OVER (
            ORDER BY bank_deposits
        ) AS deposit_quartile,
        NTILE(4) OVER (
            ORDER BY bank_loans
        ) AS loan_quartile
    FROM public.banking_customers
)
SELECT
    client_id,
    customer_name,
    ROUND(bank_deposits::numeric, 2) AS bank_deposits,
    deposit_quartile,
    ROUND(bank_loans::numeric, 2) AS bank_loans,
    loan_quartile
FROM customer_quartiles
ORDER BY deposit_quartile DESC, bank_deposits DESC, client_id;


-- 10. I calculate the top 1%, 5%, 10% and 20% financial shares.
WITH ranked_financials AS (
    SELECT
        bank_deposits,
        bank_loans,
        business_lending,
        ROW_NUMBER() OVER (
            ORDER BY bank_deposits DESC
        ) AS deposit_rank,
        ROW_NUMBER() OVER (
            ORDER BY bank_loans DESC
        ) AS loan_rank,
        ROW_NUMBER() OVER (
            ORDER BY business_lending DESC
        ) AS business_lending_rank,
        COUNT(*) OVER () AS total_customer_records,
        SUM(bank_deposits) OVER () AS total_bank_deposits,
        SUM(bank_loans) OVER () AS total_bank_loans,
        SUM(business_lending) OVER () AS total_business_lending
    FROM public.banking_customers
),
share_thresholds AS (
    SELECT cutoff_percentage
    FROM (
        VALUES (1), (5), (10), (20)
    ) AS thresholds(cutoff_percentage)
)
SELECT
    share_thresholds.cutoff_percentage AS top_customer_percentage,
    ROUND(
        (
            100.0
            * SUM(bank_deposits) FILTER (
                WHERE deposit_rank <= CEIL(
                    total_customer_records
                    * share_thresholds.cutoff_percentage
                    / 100.0
                )
            )
            / NULLIF(MAX(total_bank_deposits), 0)
        )::numeric,
        2
    ) AS bank_deposit_share_percentage,
    ROUND(
        (
            100.0
            * SUM(bank_loans) FILTER (
                WHERE loan_rank <= CEIL(
                    total_customer_records
                    * share_thresholds.cutoff_percentage
                    / 100.0
                )
            )
            / NULLIF(MAX(total_bank_loans), 0)
        )::numeric,
        2
    ) AS bank_loan_share_percentage,
    ROUND(
        (
            100.0
            * SUM(business_lending) FILTER (
                WHERE business_lending_rank <= CEIL(
                    total_customer_records
                    * share_thresholds.cutoff_percentage
                    / 100.0
                )
            )
            / NULLIF(MAX(total_business_lending), 0)
        )::numeric,
        2
    ) AS business_lending_share_percentage
FROM ranked_financials
CROSS JOIN share_thresholds
GROUP BY share_thresholds.cutoff_percentage
ORDER BY share_thresholds.cutoff_percentage;


-- 11. I calculate running and cumulative bank deposits.
WITH deposit_order AS (
    SELECT
        client_id,
        name AS customer_name,
        bank_deposits,
        ROW_NUMBER() OVER (
            ORDER BY bank_deposits DESC, client_id
        ) AS deposit_rank,
        SUM(bank_deposits) OVER (
            ORDER BY bank_deposits DESC, client_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_bank_deposits,
        SUM(bank_deposits) OVER () AS total_bank_deposits
    FROM public.banking_customers
)
SELECT
    deposit_rank,
    client_id,
    customer_name,
    ROUND(bank_deposits::numeric, 2) AS bank_deposits,
    ROUND(running_bank_deposits::numeric, 2) AS running_bank_deposits,
    ROUND(
        (
            100.0 * running_bank_deposits
            / NULLIF(total_bank_deposits, 0)
        )::numeric,
        2
    ) AS cumulative_deposit_percentage
FROM deposit_order
ORDER BY deposit_rank;


-- 12. I count records in each risk-weight value.
WITH risk_weight_counts AS (
    SELECT
        risk_weighting,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY risk_weighting
)
SELECT
    risk_weighting,
    customer_records,
    ROUND(
        (
            100.0 * customer_records
            / NULLIF(SUM(customer_records) OVER (), 0)
        )::numeric,
        2
    ) AS portfolio_percentage
FROM risk_weight_counts
ORDER BY risk_weighting;


-- 13. I compare financial medians by risk weight.
SELECT
    risk_weighting,
    COUNT(*) AS customer_records,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY estimated_income
        )::numeric,
        2
    ) AS median_estimated_income,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_deposits
        )::numeric,
        2
    ) AS median_bank_deposits,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY bank_loans
        )::numeric,
        2
    ) AS median_bank_loans,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY business_lending
        )::numeric,
        2
    ) AS median_business_lending
FROM public.banking_customers
GROUP BY risk_weighting
ORDER BY risk_weighting;


-- 14. I compare risk-weight values inside each income band.
WITH income_risk_counts AS (
    SELECT
        income_band,
        risk_weighting,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY income_band, risk_weighting
)
SELECT
    income_band,
    risk_weighting,
    customer_records,
    ROUND(
        (
            100.0 * customer_records
            / NULLIF(
                SUM(customer_records) OVER (
                    PARTITION BY income_band
                ),
                0
            )
        )::numeric,
        2
    ) AS income_band_percentage
FROM income_risk_counts
ORDER BY
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END,
    risk_weighting;


-- 15. I rank banking contacts by deposits, loans and exposure.
WITH contact_financials AS (
    SELECT
        banking_contact,
        COUNT(*) AS customer_records_managed,
        SUM(bank_deposits) AS total_bank_deposits,
        SUM(bank_loans) AS total_bank_loans,
        SUM(
            bank_loans
            + business_lending
            + credit_card_balance
        ) AS total_recorded_lending_exposure
    FROM public.banking_customers
    GROUP BY banking_contact
),
ranked_contacts AS (
    SELECT
        banking_contact,
        customer_records_managed,
        total_bank_deposits,
        total_bank_loans,
        total_recorded_lending_exposure,
        DENSE_RANK() OVER (
            ORDER BY total_bank_deposits DESC
        ) AS deposit_rank,
        DENSE_RANK() OVER (
            ORDER BY total_bank_loans DESC
        ) AS loan_rank,
        DENSE_RANK() OVER (
            ORDER BY total_recorded_lending_exposure DESC
        ) AS lending_exposure_rank
    FROM contact_financials
)
SELECT
    banking_contact,
    customer_records_managed,
    ROUND(total_bank_deposits::numeric, 2) AS total_bank_deposits,
    deposit_rank,
    ROUND(total_bank_loans::numeric, 2) AS total_bank_loans,
    loan_rank,
    ROUND(
        total_recorded_lending_exposure::numeric,
        2
    ) AS total_recorded_lending_exposure,
    lending_exposure_rank
FROM ranked_contacts
ORDER BY lending_exposure_rank, banking_contact;


-- 16. I find high-exposure records with relatively low deposits.
-- I use the top 10% for exposure and bottom 25% for deposits.
WITH customer_financials AS (
    SELECT
        client_id,
        name AS customer_name,
        bank_deposits,
        bank_loans,
        business_lending,
        credit_card_balance,
        bank_loans
            + business_lending
            + credit_card_balance AS recorded_lending_exposure
    FROM public.banking_customers
),
calculated_thresholds AS (
    SELECT
        PERCENTILE_CONT(0.90) WITHIN GROUP (
            ORDER BY recorded_lending_exposure
        ) AS high_exposure_threshold,
        PERCENTILE_CONT(0.25) WITHIN GROUP (
            ORDER BY bank_deposits
        ) AS low_deposit_threshold
    FROM customer_financials
)
SELECT
    customer_financials.client_id,
    customer_financials.customer_name,
    ROUND(customer_financials.bank_deposits::numeric, 2) AS bank_deposits,
    ROUND(
        customer_financials.recorded_lending_exposure::numeric,
        2
    ) AS recorded_lending_exposure,
    ROUND(
        (
            customer_financials.recorded_lending_exposure
            / NULLIF(customer_financials.bank_deposits, 0)
        )::numeric,
        2
    ) AS exposure_to_deposit_ratio,
    ROUND(
        calculated_thresholds.high_exposure_threshold::numeric,
        2
    ) AS high_exposure_threshold,
    ROUND(
        calculated_thresholds.low_deposit_threshold::numeric,
        2
    ) AS low_deposit_threshold
FROM customer_financials
CROSS JOIN calculated_thresholds
WHERE customer_financials.recorded_lending_exposure
        >= calculated_thresholds.high_exposure_threshold
  AND customer_financials.bank_deposits
        <= calculated_thresholds.low_deposit_threshold
ORDER BY recorded_lending_exposure DESC, client_id;

