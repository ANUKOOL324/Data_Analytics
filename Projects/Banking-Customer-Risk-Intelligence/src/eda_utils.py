from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


def clean_text_label(series):
    """Standardize repeated text labels without changing their business meaning."""
    return (
        series.astype("string")
        .str.strip()
        .str.replace(r"\s+", " ", regex=True)
        .str.title()
    )


def summarize_raw_files(tables, business_levels):
    """Return row and column counts for each raw input table."""
    return pd.DataFrame(
        [
            {
                "file_name": f"{table_name}.csv",
                "business_level": business_levels[table_name],
                "rows": len(table),
                "columns": table.shape[1],
            }
            for table_name, table in tables.items()
        ]
    )


def calculate_iqr_outliers(data, column):
    """Calculate IQR-based outlier limits and counts for one numeric column."""
    values = data[column].dropna()
    q1 = values.quantile(0.25)
    q3 = values.quantile(0.75)
    iqr = q3 - q1
    lower_limit = q1 - 1.5 * iqr
    upper_limit = q3 + 1.5 * iqr
    outlier_count = ((values < lower_limit) | (values > upper_limit)).sum()

    return {
        "column": column,
        "q1": round(q1, 2),
        "median": round(values.median(), 2),
        "q3": round(q3, 2),
        "lower_limit": round(lower_limit, 2),
        "upper_limit": round(upper_limit, 2),
        "min_value": round(values.min(), 2),
        "max_value": round(values.max(), 2),
        "outlier_count": int(outlier_count),
        "outlier_pct": round(outlier_count / len(values) * 100, 2),
    }


def build_data_dictionary(data, column_descriptions):
    """Create a simple data dictionary for the final analysis table."""
    return pd.DataFrame(
        {
            "column": data.columns,
            "dtype": [str(data[column].dtype) for column in data.columns],
            "missing_count": [int(data[column].isna().sum()) for column in data.columns],
            "description": [
                column_descriptions.get(
                    column,
                    "Engineered or supporting analysis field.",
                )
                for column in data.columns
            ],
        }
    )


def export_tables(table_map, output_dir):
    """Export named DataFrames as CSV files into one folder."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for file_name, table in table_map.items():
        table.to_csv(output_dir / file_name, index=False)


def add_percentage_column(data, count_column, denominator, output_column="customer_pct"):
    """Add a percentage column based on a count column and total denominator."""
    result = data.copy()
    result[output_column] = (result[count_column] / denominator * 100).round(2)
    return result


def plot_donut_chart(ax, labels, values, title):
    """Draw a simple donut chart on a Matplotlib axis."""
    ax.pie(
        values,
        labels=labels,
        autopct="%1.1f%%",
        startangle=90,
        pctdistance=0.78,
        textprops={"fontsize": 8},
    )
    circle = plt.Circle((0, 0), 0.55, fc="white")
    ax.add_artist(circle)
    ax.set_title(title)
    ax.axis("equal")

