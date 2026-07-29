-- 1. Annual total sales across all product categories.
SELECT
    year,
    ROUND(SUM(m01ab + m01ae + n02ba + n02be + n05b + n05c + r03 + r06), 2) AS total_sales
FROM sales_daily
GROUP BY year
ORDER BY year;

-- 2. Average total sales by weekday.
SELECT
    weekday_name,
    ROUND(AVG(m01ab + m01ae + n02ba + n02be + n05b + n05c + r03 + r06), 2) AS avg_daily_sales
FROM sales_daily
GROUP BY weekday_name
ORDER BY avg_daily_sales DESC;

-- 3. Average total sales by hour of day.
SELECT
    hour,
    ROUND(AVG(m01ab + m01ae + n02ba + n02be + n05b + n05c + r03 + r06), 2) AS avg_hourly_sales
FROM sales_hourly
GROUP BY hour
ORDER BY hour;

-- 4. Monthly category mix in a long format suitable for BI tools.
SELECT month_end_date, 'M01AB' AS category, m01ab AS sales FROM sales_monthly
UNION ALL SELECT month_end_date, 'M01AE', m01ae FROM sales_monthly
UNION ALL SELECT month_end_date, 'N02BA', n02ba FROM sales_monthly
UNION ALL SELECT month_end_date, 'N02BE', n02be FROM sales_monthly
UNION ALL SELECT month_end_date, 'N05B',  n05b  FROM sales_monthly
UNION ALL SELECT month_end_date, 'N05C',  n05c  FROM sales_monthly
UNION ALL SELECT month_end_date, 'R03',   r03   FROM sales_monthly
UNION ALL SELECT month_end_date, 'R06',   r06   FROM sales_monthly;

