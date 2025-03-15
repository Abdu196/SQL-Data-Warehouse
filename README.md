# SQL-Data-Warehouse
SQL Data Warehouse for [*****] Telecom Designed for Customer Segmentation and Sales Analysis


# Customer Segmentation and Analysis Data Warehouse - Ethio Telecom

This project contains a Data Warehouse for [*****] Telecom, designed for customer segmentation and sales analysis using a Star Schema model. It includes features like churn prediction, network performance tracking, and support ticket analysis.

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [Stored Procedures](#stored-procedures)
- [How to Use](#how-to-use)
- [SQL Techniques](#sql-techniques)
- [Security & Privacy](#security--privacy)
- [Contributing](#contributing)
- [License](#license)

## Overview

The data warehouse provides insights into:

- Sales analysis by customer and product.
- Churn analysis and retention metrics.
- Network performance tracking.
- Customer support metrics.

The project uses **SQL Server** with advanced SQL features like stored procedures, views, aggregations, indexes, and window functions.

## Project Structure

- **Schemas**: 
  - Sales
  - Customer
  - Product
  - Time
  - Network
  - Support
  - Billing
- **Fact Table**: SalesFact
- **Dimension Tables**: CustomerDimension, ProductDimension, etc.
- **Stored Procedures**: For querying sales, churn, support metrics, and more.
- **Views**: For simplified querying and data privacy.
- **Indexes**: For query optimization.

## Stored Procedures

Some key stored procedures:

- `GetTotalSalesByCustomerProduct`: Retrieves total sales by customer and product.
- `GetChurnRateByPeriod`: Calculates churn rate for a given time period.
- `GetSalesByRegionAndTime`: Provides sales breakdown by region and time.
- `GetTopNProductsBySales`: Returns the top N products based on sales.

## How to Use

1. **Set up Database**: Import SQL scripts to create tables and schemas.
2. **Run Stored Procedures**: Execute stored procedures for dynamic data analysis.

### Example:

```sql
EXEC GetTotalSalesByCustomerProduct 
    @CustomerID = 101, 
    @StartDate = '2023-01-01', 
    @EndDate = '2023-12-31', 
    @ProductCategory = 'Mobile';

