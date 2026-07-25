# Reports

This folder contains the reusable outputs generated from the banking customer analytics notebooks.

## Current Dataset

| Item | Value |
|---|---:|
| Customer profiles | 15,000 |
| Customers with at least one loan | 10,279 |
| Loan records | 11,911 |
| Default loans | 1,478 |
| Not default loans | 10,433 |
| Loan default rate | 12.41% |
| Total loan exposure | Rs 2460.72 crore |
| Expected loss | Rs 199.17 crore |

## Folder Layout

| Folder | Purpose |
|---|---|
| `tables/` | CSV summaries used in the notebooks, SQL comparison, README, and interview explanation. |
| `figures/data_quality/` | Data quality and outlier visuals from the first notebook. |
| `figures/customer_segments/` | Customer profile, relationship, loyalty, and segment visuals. |
| `figures/financial_exposure/` | Loan exposure, repayment, default-risk, DTI, LTV, and risk-band visuals. |
| `figures/modeling/` | Logistic Regression and Random Forest model evaluation charts. |

## Main Tables To Read First

| File | What it explains |
|---|---|
| `tables/data_quality_summary.csv` | Main data quality findings after cleaning and validation. |
| `tables/customer_kpis.csv` | Customer-level summary KPIs. |
| `tables/customer_segment_insights.csv` | Key customer segment observations. |
| `tables/portfolio_kpis_readable.csv` | Main lending portfolio KPIs in readable business format. |
| `tables/lending_risk_insights.csv` | Short business insights from the lending risk analysis. |
| `tables/model_performance_metrics.csv` | Logistic Regression and Random Forest comparison for both feature sets. |
| `tables/random_forest_feature_importance.csv` | Features that influenced the final model most. |
| `tables/high_risk_loan_predictions.csv` | Highest-risk loans identified by the model. |

## Main Figures To Read First

| File | What it shows |
|---|---|
| `figures/customer_segments/customer_segment_donut_charts.png` | Customer mix across key categories. |
| `figures/customer_segments/customer_value_boxplots.png` | Outliers and spread in income, deposits, and credit utilization. |
| `figures/financial_exposure/loan_type_exposure_and_default_rate.png` | Exposure and default rate by loan product. |
| `figures/financial_exposure/risk_band_default_and_expected_loss.png` | How default risk changes across risk bands. |
| `figures/financial_exposure/loan_risk_boxplots.png` | Loan amount and DTI differences across risk groups. |
| `figures/financial_exposure/risk_field_correlation_heatmap.png` | Relationships between credit score, DTI, delinquency, expected loss, and default. |
| `figures/modeling/best_model_confusion_matrix.png` | Correct and incorrect Random Forest classifications. |
| `figures/modeling/model_comparison_metrics.png` | Precision, recall, F1-score and ROC-AUC across all model combinations. |
| `figures/modeling/random_forest_feature_importance.png` | Most important model drivers for the selected Random Forest model. |
| `figures/modeling/roc_curves.png` | Overall classification separation strength. |

## Model Snapshot

The model notebook uses a customer-wise split with zero overlapping customers between training and testing.

| Split check | Value |
|---|---:|
| Training loan rows | 8,937 |
| Testing loan rows | 2,974 |
| Unique training customers | 7,709 |
| Unique testing customers | 2,570 |
| Overlapping customers | 0 |

| Feature set | Model | Accuracy | Precision | Recall | F1 | ROC-AUC | False negatives | False positives |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Approval-style | Logistic Regression | 0.7431 | 0.2860 | 0.6933 | 0.4050 | 0.7949 | 115 | 649 |
| Approval-style | Random Forest | 0.7966 | 0.3333 | 0.6133 | 0.4319 | 0.8004 | 145 | 460 |
| Monitoring | Logistic Regression | 0.9677 | 0.8252 | 0.9440 | 0.8806 | 0.9950 | 21 | 75 |
| Monitoring | Random Forest | 0.9475 | 0.7160 | 0.9680 | 0.8231 | 0.9855 | 12 | 144 |

Final selected model: **Monitoring Random Forest**.

It was selected because default-risk monitoring prioritizes recall and fewer false negatives. Logistic Regression is a strong baseline, but it missed more actual default loans on the customer-wise test set.

## Strong Business Findings

| Finding | Result |
|---|---|
| Highest exposure product | Home Loan |
| Highest default-rate product | Business Loan at 30.79% |
| Highest risk band default rate | High at 53.82% |
| Highest DTI band default rate | >60% at 21.78% |

## Notes

- These reports are generated outputs, not raw data.
- The project now uses customer profile, financial profile, loan, and loan-risk fields.
- Legacy single-table outputs from the earlier dataset were removed.
