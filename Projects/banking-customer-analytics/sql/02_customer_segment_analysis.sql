/*
Banking Customer Portfolio & Exposure Analytics
File 2 - Customer and segment analysis

I use public.banking_customers in this file.
I count records because repeated client IDs have different details.
I keep BR labels neutral because their meanings are not provided.
I run each numbered query separately. These queries only read data.
*/

-- 1. I count records in each income band.
WITH income_band_counts AS (
    SELECT
        income_band,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY income_band
)
SELECT
    income_band,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(SUM(customer_records) OVER (), 0),
        2
    ) AS portfolio_percentage
FROM income_band_counts
ORDER BY
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 2. I count records in each age group.
WITH customer_age_groups AS (
    SELECT
        CASE
            WHEN age < 25 THEN 'Under 25'
            WHEN age BETWEEN 25 AND 34 THEN '25-34'
            WHEN age BETWEEN 35 AND 44 THEN '35-44'
            WHEN age BETWEEN 45 AND 54 THEN '45-54'
            WHEN age BETWEEN 55 AND 64 THEN '55-64'
            WHEN age >= 65 THEN '65 and above'
            ELSE 'Unknown'
        END AS age_group,
        CASE
            WHEN age < 25 THEN 1
            WHEN age BETWEEN 25 AND 34 THEN 2
            WHEN age BETWEEN 35 AND 44 THEN 3
            WHEN age BETWEEN 45 AND 54 THEN 4
            WHEN age BETWEEN 55 AND 64 THEN 5
            WHEN age >= 65 THEN 6
            ELSE 7
        END AS age_group_order
    FROM public.banking_customers
),
age_group_counts AS (
    SELECT
        age_group,
        age_group_order,
        COUNT(*) AS customer_records
    FROM customer_age_groups
    GROUP BY age_group, age_group_order
)
SELECT
    age_group,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(SUM(customer_records) OVER (), 0),
        2
    ) AS portfolio_percentage
FROM age_group_counts
ORDER BY age_group_order;


-- 3. I count records by nationality.
WITH nationality_counts AS (
    SELECT
        nationality,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY nationality
)
SELECT
    nationality,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(SUM(customer_records) OVER (), 0),
        2
    ) AS portfolio_percentage
FROM nationality_counts
ORDER BY customer_records DESC, nationality;


-- 4. I find the 10 most common occupations.
WITH occupation_counts AS (
    SELECT
        occupation,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY occupation
),
ranked_occupations AS (
    SELECT
        occupation,
        customer_records,
        ROUND(
            100.0 * customer_records
            / NULLIF(SUM(customer_records) OVER (), 0),
            2
        ) AS portfolio_percentage,
        ROW_NUMBER() OVER (
            ORDER BY customer_records DESC, occupation
        ) AS occupation_rank
    FROM occupation_counts
)
SELECT
    occupation_rank,
    occupation,
    customer_records,
    portfolio_percentage
FROM ranked_occupations
WHERE occupation_rank <= 10
ORDER BY occupation_rank;


-- 5. I count records in each loyalty group.
WITH loyalty_counts AS (
    SELECT
        loyalty_classification,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY loyalty_classification
)
SELECT
    loyalty_classification,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(SUM(customer_records) OVER (), 0),
        2
    ) AS portfolio_percentage
FROM loyalty_counts
ORDER BY customer_records DESC, loyalty_classification;


-- 6. I count records in each fee structure.
WITH fee_counts AS (
    SELECT
        fee_structure,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY fee_structure
)
SELECT
    fee_structure,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(SUM(customer_records) OVER (), 0),
        2
    ) AS portfolio_percentage
FROM fee_counts
ORDER BY
    CASE fee_structure
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 7. I count records in each BR group.
WITH relationship_counts AS (
    SELECT
        CONCAT('BR ', brid) AS banking_relationship,
        brid AS relationship_order,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY brid
)
SELECT
    banking_relationship,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(SUM(customer_records) OVER (), 0),
        2
    ) AS portfolio_percentage
FROM relationship_counts
ORDER BY relationship_order;


-- 8a. I compare credit-card holdings across income bands.
WITH card_counts AS (
    SELECT
        income_band,
        amount_of_credit_cards,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY income_band, amount_of_credit_cards
)
SELECT
    income_band,
    amount_of_credit_cards AS credit_cards,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(
            SUM(customer_records) OVER (PARTITION BY income_band),
            0
        ),
        2
    ) AS income_band_percentage
FROM card_counts
ORDER BY
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END,
    credit_cards;


-- 8b. I compare property holdings across income bands.
WITH property_counts AS (
    SELECT
        income_band,
        properties_owned,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY income_band, properties_owned
)
SELECT
    income_band,
    properties_owned,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(
            SUM(customer_records) OVER (PARTITION BY income_band),
            0
        ),
        2
    ) AS income_band_percentage
FROM property_counts
ORDER BY
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END,
    properties_owned;


-- 9. I calculate median income, deposits and loans by income band.
SELECT
    income_band,
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
    ) AS median_bank_loans
FROM public.banking_customers
GROUP BY income_band
ORDER BY
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 10. I compare income bands inside each loyalty group.
WITH loyalty_income_counts AS (
    SELECT
        loyalty_classification,
        income_band,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY loyalty_classification, income_band
)
SELECT
    loyalty_classification,
    income_band,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(
            SUM(customer_records) OVER (
                PARTITION BY loyalty_classification
            ),
            0
        ),
        2
    ) AS loyalty_group_percentage
FROM loyalty_income_counts
ORDER BY
    loyalty_classification,
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 11. I compare fee structures inside each income band.
WITH income_fee_counts AS (
    SELECT
        income_band,
        fee_structure,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY income_band, fee_structure
)
SELECT
    income_band,
    fee_structure,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(
            SUM(customer_records) OVER (
                PARTITION BY income_band
            ),
            0
        ),
        2
    ) AS income_band_percentage
FROM income_fee_counts
ORDER BY
    CASE income_band
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END,
    CASE fee_structure
        WHEN 'Low' THEN 1
        WHEN 'Mid' THEN 2
        WHEN 'High' THEN 3
        ELSE 4
    END;


-- 12. I count joining records by year and decade.
WITH joining_counts AS (
    SELECT
        join_year,
        join_decade,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY join_year, join_decade
)
SELECT
    join_year,
    join_decade,
    customer_records,
    ROUND(
        100.0 * customer_records
        / NULLIF(SUM(customer_records) OVER (), 0),
        2
    ) AS portfolio_percentage
FROM joining_counts
ORDER BY join_year;


-- 13. I rank banking contacts by unique customers managed.
WITH contact_counts AS (
    SELECT
        banking_contact,
        COUNT(DISTINCT client_id) AS unique_customers_managed,
        COUNT(*) AS customer_records_managed
    FROM public.banking_customers
    GROUP BY banking_contact
),
ranked_contacts AS (
    SELECT
        banking_contact,
        unique_customers_managed,
        customer_records_managed,
        DENSE_RANK() OVER (
            ORDER BY unique_customers_managed DESC
        ) AS contact_rank
    FROM contact_counts
)
SELECT
    contact_rank,
    banking_contact,
    unique_customers_managed,
    customer_records_managed
FROM ranked_contacts
ORDER BY contact_rank, banking_contact;


-- 14. I find the largest income band in each BR group.
WITH relationship_segment_counts AS (
    SELECT
        CONCAT('BR ', brid) AS banking_relationship,
        brid AS relationship_order,
        income_band,
        COUNT(*) AS customer_records
    FROM public.banking_customers
    GROUP BY brid, income_band
),
relationship_segment_percentages AS (
    SELECT
        banking_relationship,
        relationship_order,
        income_band,
        customer_records,
        ROUND(
            100.0 * customer_records
            / NULLIF(
                SUM(customer_records) OVER (
                    PARTITION BY banking_relationship
                ),
                0
            ),
            2
        ) AS relationship_percentage
    FROM relationship_segment_counts
),
ranked_relationship_segments AS (
    SELECT
        banking_relationship,
        relationship_order,
        income_band,
        customer_records,
        relationship_percentage,
        ROW_NUMBER() OVER (
            PARTITION BY banking_relationship
            ORDER BY customer_records DESC, income_band
        ) AS segment_rank
    FROM relationship_segment_percentages
)
SELECT
    banking_relationship,
    income_band AS top_income_band,
    customer_records,
    relationship_percentage
FROM ranked_relationship_segments
WHERE segment_rank = 1
ORDER BY relationship_order;
