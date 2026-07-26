# Power BI Dashboard

The PBIP report definitions use **Customer Segment** for the individual service
tiers Retail, Priority, and Private Banking. The unused legacy relationship
dimension was removed from the text-based semantic model, and report slicers
now reference `Customer_Segment`.

The binary `.pbix` file and screenshots are not modified by the data-preparation
notebooks. To refresh the dashboard in Power BI Desktop:

1. Open `banking analysis_completed.pbix` or the PBIP project.
2. Connect or rebind the model to
   `banking_customer_profiles_clean` and
   `banking_customer_loan_analytics_clean`.
3. Confirm the segment field is `customer_segment`.
4. Refresh all queries and verify the values are Retail, Priority, and Private
   Banking.
5. Check relationships, slicers, measures, and visual totals before saving.
6. Replace the screenshots only after the refreshed report is verified.
