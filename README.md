# Amazon E-Commerce Sales Dashboard
### AWS + Power BI End-to-End Analytics Solution

![Dashboard Preview](dashboard_preview.png)

## Project Overview

An end-to-end business intelligence solution analyzing Amazon e-commerce sales data across 5,000 orders from 2021 to 2024. Built on AWS cloud infrastructure with Power BI for visualization, this project demonstrates a complete data analytics pipeline from raw data ingestion to executive-level dashboards.

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Storage | AWS S3 | Raw data storage with partitioning |
| ETL | AWS Glue | Schema discovery and auto-partitioning |
| Query Engine | AWS Athena | SQL queries on S3 data |
| Visualization | Power BI | Interactive dashboards and DAX |
| Language | PySpark | Glue ETL job scripting |
| Query Language | SQL + DAX | Data transformation and measures |

---

## Architecture

```
Raw CSV Upload
      ↓
AWS S3 (ecommerce-order-details/)
      ↓
AWS Glue Crawler (Schema Discovery)
      ↓
AWS Glue ETL Job (Auto-Partitioning by snapshot_day)
      ↓
AWS Athena (SQL Query Layer)
      ↓
Power BI via ODBC Driver (Visualization)
```

---

## Dataset

| Column | Type | Description |
|---|---|---|
| Order ID | String | Unique order identifier |
| Order Date | Date | Date order was placed |
| Ship Date | Date | Date order was shipped |
| Customer Name | String | Customer identifier |
| Segment | String | Consumer, Corporate, Home Office |
| City | String | Order city |
| State | String | Order state |
| Region | String | East, West, Central, South |
| Category | String | Furniture, Technology, Office Supplies |
| Sub-Category | String | 13 sub-categories |
| Product Name | String | Product identifier |
| Sales | Decimal | Gross sales amount |
| Quantity | Integer | Units ordered |
| Discount | Decimal | Discount percentage applied |
| Profit | Decimal | Net profit per order |

**Data Range:** January 2021 — October 2024
**Total Orders:** 5,000
**Partitioning:** By snapshot_day (yyyy-MM-dd)

---

## Dashboard Pages

### Page 1 — Executive Sales Overview
Answers: *"How is the business performing overall?"*

- 5 KPI cards: Total Orders, Profit, Sales, Revenue, Profit Margin %
- Revenue & Profit dual trend chart (2021-2024)
- Top 5 Sub-Category by Revenue
- Sales by Region map
- Key Analysis narrative box

### Page 2 — Profitability & Operations Analysis
Answers: *"Where are we losing money and why?"*

- 4 KPI cards: Shipping Days, Loss Orders Count, Avg Discount %, Loss Orders %
- Discount vs Profit Margin scatter plot with quadrant coloring
- Shipping Days by Region bar chart with reference line
- Revenue vs Profit clustered bar by Sub-Category
- Region × Segment shipping heatmap matrix

### Page 3 — Growth & Segment Analysis
Answers: *"Are we growing and who drives our best margins?"*

- 5 KPI cards: YTD Revenue, Revenue YoY%, YTD Profit, MTD Revenue, Profit YoY%
- Monthly revenue trend comparison 2021-2024
- Quarterly revenue clustered bar chart
- Segment Profitability matrix with conditional formatting
- Revenue by Day of Week bar chart

---

## DAX Measures

### Core Measures
```dax
Total Revenue = 
    SUMX(
        orders_partitioned,
        orders_partitioned[Sales] * (1 - orders_partitioned[Discount])
    )

Total Profit = SUM(orders_partitioned[profit])

Profit Margin % = DIVIDE([Total Profit], [Total Revenue], 0)

Total Orders = COUNTROWS(orders_partitioned)
```

### Operations Measures
```dax
Shipping Days = 
    AVERAGEX(
        orders_partitioned,
        DATEDIFF(
            orders_partitioned[order_date],
            orders_partitioned[ship_date],
            DAY
        )
    )

Loss Orders Count = 
    CALCULATE(
        COUNTROWS(orders_partitioned),
        FILTER(orders_partitioned, orders_partitioned[profit] < 0)
    )

Loss Orders % = DIVIDE([Loss Orders Count], [Total Orders], 0)

Avg Discount % = AVERAGE(orders_partitioned[Discount])
```

### Time Intelligence Measures
```dax
Revenue LY = 
    CALCULATE(
        [Total Revenue],
        SAMEPERIODLASTYEAR('Date Table'[Date])
    )

Revenue YoY % = 
    DIVIDE([Total Revenue] - [Revenue LY], [Revenue LY], 0)

YTD Revenue = 
    TOTALYTD([Total Revenue], 'Date Table'[Date])

MTD Revenue = 
    TOTALMTD([Total Revenue], 'Date Table'[Date])

Revenue MoM = 
    CALCULATE(
        [Total Revenue],
        DATEADD('Date Table'[Date], -1, MONTH)
    )
```

---

## AWS Glue ETL Script (Key Section)

```python
from pyspark.sql.functions import to_date, date_format, col
from awsglue.dynamicframe import DynamicFrame

# Convert and partition by snapshot_day
DerivedColumn = SelectFields.toDF()
DerivedColumn = DerivedColumn.withColumn(
    "snapshot_day",
    date_format(
        to_date(col("Order Date"), "MM-dd-yyyy"),
        "yyyy-MM-dd"
    )
)
DerivedColumn = DynamicFrame.fromDF(
    DerivedColumn, glueContext, "DerivedColumn"
)

# Write partitioned output
sink = glueContext.getSink(
    path="s3://ecommerce-order-details/orders-partitioned/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["snapshot_day"],
    enableUpdateCatalog=True
)
sink.setCatalogInfo(
    catalogDatabase="db_orders",
    catalogTableName="orders_partitioned"
)
sink.setFormat("glueparquet", compression="snappy")
sink.writeFrame(DerivedColumn)
```

---

## Key Business Insights Discovered

- **15.7%** of all orders generate losses — 0.30 discount is the breaking point
- **Corporate segment** leads profit margin at 13.5% consistently across all years
- **Consumer segment** shows strongest growth — 12.7% in 2021 to 14.0% in 2024
- **Home Office margin declining** — from 13.0% (2021) to 12.7% (2024)
- **Central region** averages 3.55 shipping days — slowest across all regions
- **Saturday** drives peak revenue at $154K — 20% above Tuesday's $128K
- **2023** was peak revenue year at $615K — driven by lowest average discount

---

## Business Problem Statements Solved

| BPS | Description | Page |
|---|---|---|
| BPS 1 | Overall business health KPIs | Page 1 |
| BPS 2 | Category and sub-category revenue analysis | Page 1 & 2 |
| BPS 3 | Shipping pattern visibility across regions | Page 2 |
| BPS 4 | Discount vs profitability relationship | Page 2 |
| BPS 6 | Customer segment profit margin analysis | Page 3 |
| BPS 7 | High-revenue low-profit product identification | Page 2 |
| BPS 8 | YoY and MoM sales trend analysis | Page 3 |
| BPS 9 | Shipping time vs segment correlation | Page 2 |

---

## Setup Instructions

### AWS Setup
1. Create S3 bucket with `orders/` and `athena_logs/` folders
2. Upload dataset to `orders/` with partition structure `snapshot_day=yyyy-MM-dd/`
3. Create IAM user with S3 and Glue permissions
4. Run Glue Crawler on `orders/` folder
5. Run Glue ETL job for auto-partitioning
6. Configure Athena output to `athena_logs/` folder
7. Test SQL queries in Athena

### Power BI Setup
1. Install Simba Athena ODBC Driver
2. Configure DSN with AWS region and credentials
3. Connect Power BI via ODBC
4. Import `orders_partitioned` table
5. Create Date Table using DAX CALENDAR function
6. Build relationships between Date Table and orders
7. Create Measure Table and add all DAX measures

---

## Project Structure

```
amazon-ecommerce-powerbi-dashboard/
│
├── README.md
├── dashboard/
│   └── Amazon_Sales_Analysis.pbix
├── data/
│   └── sample_data.csv
├── glue_scripts/
│   └── orders_auto_partition.py
├── sql_queries/
│   ├── data_quality_check.sql
│   └── analysis_queries.sql
├── dax_measures/
│   └── all_measures.dax
└── screenshots/
    ├── page1_overview.png
    ├── page2_profitability.png
    └── page3_growth.png
```

---

## Future Improvements

- Automated pipeline using S3 event triggers and AWS Lambda
- Real-time data refresh using AWS Kinesis
- Predictive analytics using AWS SageMaker
- Data warehouse migration to AWS Redshift
- Row-level security in Power BI for multi-user access

---

## Author

**Arghyajyoti Samui**
[LinkedIn Profile](https://www.linkedin.com/in/arghyajyoti-samui)

---

## License

MIT License — free to use for learning and portfolio purposes.
