/*
Banking Customer Portfolio & Exposure Analytics
File 1 - Table checks

I use public.banking_customers in this file.
I run each numbered query separately to check the imported table.
These queries only read data.
*/

-- 1. I check the table columns and data types.
SELECT
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'banking_customers'
ORDER BY ordinal_position;


-- 2. I count all rows.
SELECT COUNT(*) AS total_rows
FROM public.banking_customers;


-- 3. I count unique customer IDs.
SELECT COUNT(DISTINCT client_id) AS total_unique_customers
FROM public.banking_customers;


-- 4. I find client IDs that appear more than once.
SELECT
    client_id,
    COUNT(*) AS record_count
FROM public.banking_customers
WHERE client_id IS NOT NULL
  AND BTRIM(client_id) <> ''
GROUP BY client_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, client_id;


-- 5. I count missing values in the important columns.
SELECT
    COUNT(*) FILTER (
        WHERE client_id IS NULL OR BTRIM(client_id) = ''
    ) AS missing_client_id,
    COUNT(*) FILTER (WHERE age IS NULL) AS missing_age,
    COUNT(*) FILTER (WHERE joined_bank IS NULL) AS missing_joined_bank,
    COUNT(*) FILTER (WHERE estimated_income IS NULL) AS missing_estimated_income,
    COUNT(*) FILTER (WHERE income_band IS NULL) AS missing_income_band,
    COUNT(*) FILTER (WHERE loyalty_classification IS NULL) AS missing_loyalty,
    COUNT(*) FILTER (WHERE bank_deposits IS NULL) AS missing_bank_deposits,
    COUNT(*) FILTER (WHERE bank_loans IS NULL) AS missing_bank_loans,
    COUNT(*) FILTER (WHERE risk_weighting IS NULL) AS missing_risk_weighting
FROM public.banking_customers;


-- 6. I check the earliest and latest joining dates.
SELECT
    MIN(joined_bank) AS minimum_joining_date,
    MAX(joined_bank) AS maximum_joining_date
FROM public.banking_customers;


-- 7. I check the minimum, maximum and average age.
SELECT
    MIN(age) AS minimum_age,
    MAX(age) AS maximum_age,
    ROUND(AVG(age)::numeric, 2) AS average_age
FROM public.banking_customers;


-- 8. I count negative values in the financial columns.
SELECT
    COUNT(*) FILTER (WHERE estimated_income < 0) AS negative_estimated_income,
    COUNT(*) FILTER (WHERE superannuation_savings < 0) AS negative_superannuation_savings,
    COUNT(*) FILTER (WHERE credit_card_balance < 0) AS negative_credit_card_balance,
    COUNT(*) FILTER (WHERE bank_loans < 0) AS negative_bank_loans,
    COUNT(*) FILTER (WHERE bank_deposits < 0) AS negative_bank_deposits,
    COUNT(*) FILTER (WHERE checking_accounts < 0) AS negative_checking_accounts,
    COUNT(*) FILTER (WHERE saving_accounts < 0) AS negative_saving_accounts,
    COUNT(*) FILTER (WHERE foreign_currency_account < 0) AS negative_foreign_currency_account,
    COUNT(*) FILTER (WHERE business_lending < 0) AS negative_business_lending
FROM public.banking_customers;


-- 9. I count zero deposits and loans.
SELECT
    COUNT(*) FILTER (WHERE bank_deposits = 0) AS zero_bank_deposits,
    COUNT(*) FILTER (WHERE bank_loans = 0) AS zero_bank_loans
FROM public.banking_customers;


-- 10a. I check the income-band values and counts.
SELECT
    income_band,
    COUNT(*) AS record_count
FROM public.banking_customers
GROUP BY income_band
ORDER BY
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 10b. I check the loyalty values and counts.
SELECT
    loyalty_classification,
    COUNT(*) AS record_count
FROM public.banking_customers
GROUP BY loyalty_classification
ORDER BY record_count DESC, loyalty_classification;


-- 10c. I check the fee-structure values and counts.
SELECT
    fee_structure,
    COUNT(*) AS record_count
FROM public.banking_customers
GROUP BY fee_structure
ORDER BY
    CASE fee_structure
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 10d. I check the risk-weight values and counts.
SELECT
    risk_weighting,
    COUNT(*) AS record_count
FROM public.banking_customers
GROUP BY risk_weighting
ORDER BY risk_weighting;


-- 10e. I check the BRId values and counts.
-- I leave BRId unlabelled because its real mapping is not provided.
SELECT
    brid,
    COUNT(*) AS record_count
FROM public.banking_customers
GROUP BY brid
ORDER BY brid;


-- 11. I combine the main checks into one summary.
-- I flag ages outside 18 to 100 for review; I do not remove them.
WITH base_validation AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(DISTINCT client_id) AS unique_clients,
        COUNT(*) FILTER (
            WHERE client_id IS NULL OR BTRIM(client_id) = ''
        ) AS missing_client_ids,
        COUNT(*) FILTER (
            WHERE age < 18 OR age > 100
        ) AS invalid_ages,
        COUNT(*) FILTER (WHERE estimated_income < 0)
            + COUNT(*) FILTER (WHERE superannuation_savings < 0)
            + COUNT(*) FILTER (WHERE credit_card_balance < 0)
            + COUNT(*) FILTER (WHERE bank_loans < 0)
            + COUNT(*) FILTER (WHERE bank_deposits < 0)
            + COUNT(*) FILTER (WHERE checking_accounts < 0)
            + COUNT(*) FILTER (WHERE saving_accounts < 0)
            + COUNT(*) FILTER (WHERE foreign_currency_account < 0)
            + COUNT(*) FILTER (WHERE business_lending < 0)
            AS negative_financial_values
    FROM public.banking_customers
),
duplicate_validation AS (
    SELECT COUNT(*) AS duplicate_clients
    FROM (
        SELECT client_id
        FROM public.banking_customers
        WHERE client_id IS NOT NULL
          AND BTRIM(client_id) <> ''
        GROUP BY client_id
        HAVING COUNT(*) > 1
    ) AS repeated_client_ids
)
SELECT
    base_validation.total_rows,
    base_validation.unique_clients,
    duplicate_validation.duplicate_clients,
    base_validation.missing_client_ids,
    base_validation.invalid_ages,
    base_validation.negative_financial_values
FROM base_validation
CROSS JOIN duplicate_validation;
