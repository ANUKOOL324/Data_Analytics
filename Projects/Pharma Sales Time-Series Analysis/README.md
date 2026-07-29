# Pharma Sales Analysis

## Project overview

This portfolio project analyzes six years of point-of-sale data from a pharmacy. It focuses on preparing reliable sales data, exploring performance across eight pharmaceutical product categories, identifying time-based patterns, and translating the findings into practical business insights.

The project is designed around a Data Analyst workflow: Python for data preparation and exploratory analysis, SQL for business queries, and Power BI for dashboard reporting. Predictive modeling and sales forecasting are outside the scope of this version.

## Business questions

- Which product categories contribute the most to sales volume?
- How do sales patterns change by hour, weekday, month, and year?
- Which categories show clear trends, seasonality, or unusual spikes?
- When are the strongest and weakest sales periods?
- What inventory and staffing decisions can be supported by the observed patterns?

## Dataset

The raw data is available at four time grains: hourly, daily, weekly, and monthly. Each file contains sales quantities for eight product groups identified by ATC codes:

`M01AB`, `M01AE`, `N02BA`, `N02BE`, `N05B`, `N05C`, `R03`, and `R06`.

The hourly and daily files also include calendar fields such as year, month, hour, and weekday name. Raw source files are preserved unchanged in [`data/raw`](data/raw).

## Analysis workflow

1. Understand the data structure, coverage, granularity, and quality.
2. Clean dates, validate values, and create reusable calendar features.
3. Explore category performance and sales distributions.
4. Analyze trends, seasonality, rolling metrics, and period-over-period changes.
5. Answer business questions with SQL and build a Power BI dashboard.
6. Summarize the most actionable findings and recommendations.

## Repository structure

```text
data/          Raw source data and generated processed datasets
notebooks/     Original reference notebook and staged analysis notebooks
src/           Reusable cleaning, analysis, and visualization code
sql/           Table definitions and business analysis queries
dashboard/     Power BI dashboard screenshots
outputs/       Exported figures and tables
reports/       Original README and final insight summary
```

## Getting started

```bash
python -m venv .venv
```

Activate the environment, then install the dependencies:

```bash
pip install -r requirements.txt
jupyter notebook
```

Run the notebooks in numerical order, beginning with `01_data_understanding.ipynb`. The original repository notebook is retained unchanged as `00_original_reference_notebook.ipynb` for reference only.

## Planned deliverables

- Reproducible cleaned datasets in `data/processed/`
- Exploratory and time-series charts in `outputs/figures/`
- Summary tables in `outputs/tables/`
- SQL analysis for common commercial questions
- Power BI dashboard covering KPIs, category mix, and time-based patterns
- Final business findings in `reports/final_insights_summary.md`

## Tools

Python, pandas, NumPy, Matplotlib, Seaborn, Plotly, SQL, Jupyter Notebook, and Power BI.

