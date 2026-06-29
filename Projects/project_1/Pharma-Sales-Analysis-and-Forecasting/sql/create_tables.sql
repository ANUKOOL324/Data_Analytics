-- Portfolio schema for cleaned pharma sales data.
-- Adjust numeric precision and date types if required by the target database.

CREATE TABLE sales_daily (
    sales_date DATE PRIMARY KEY,
    m01ab NUMERIC(12, 2),
    m01ae NUMERIC(12, 2),
    n02ba NUMERIC(12, 2),
    n02be NUMERIC(12, 2),
    n05b  NUMERIC(12, 2),
    n05c  NUMERIC(12, 2),
    r03   NUMERIC(12, 2),
    r06   NUMERIC(12, 2),
    year  INTEGER,
    month INTEGER,
    weekday_name VARCHAR(10)
);

CREATE TABLE sales_hourly (
    sales_datetime TIMESTAMP PRIMARY KEY,
    m01ab NUMERIC(12, 2),
    m01ae NUMERIC(12, 2),
    n02ba NUMERIC(12, 2),
    n02be NUMERIC(12, 2),
    n05b  NUMERIC(12, 2),
    n05c  NUMERIC(12, 2),
    r03   NUMERIC(12, 2),
    r06   NUMERIC(12, 2),
    year  INTEGER,
    month INTEGER,
    hour  INTEGER,
    weekday_name VARCHAR(10)
);

CREATE TABLE sales_weekly (
    week_end_date DATE PRIMARY KEY,
    m01ab NUMERIC(12, 2),
    m01ae NUMERIC(12, 2),
    n02ba NUMERIC(12, 2),
    n02be NUMERIC(12, 2),
    n05b  NUMERIC(12, 2),
    n05c  NUMERIC(12, 2),
    r03   NUMERIC(12, 2),
    r06   NUMERIC(12, 2)
);

CREATE TABLE sales_monthly (
    month_end_date DATE PRIMARY KEY,
    m01ab NUMERIC(12, 2),
    m01ae NUMERIC(12, 2),
    n02ba NUMERIC(12, 2),
    n02be NUMERIC(12, 2),
    n05b  NUMERIC(12, 2),
    n05c  NUMERIC(12, 2),
    r03   NUMERIC(12, 2),
    r06   NUMERIC(12, 2)
);

