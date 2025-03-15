This structure represents how the fact table (SalesFact) is at the center, 
surrounded by dimension tables that describe customer, product, time, network, support, and billing.


Step 2: Schema Design and Table Creation
Let’s start with creating schemas for different domains and fact and dimension tables.

Create Schema Design
1.Sales Schema – Stores fact data and transactional information.
2.Customer Schema – Stores customer demographic information.
3.Product Schema – Stores product and service details.
4.Time Schema – Stores time-based data for reporting.
5.Network Schema – Stores network-related metrics and performance.
6.Support Schema – Stores customer support interactions and tickets.
7.Billing Schema – Stores billing information.


CREATE SCHEMA Sales;
CREATE SCHEMA Customer;
CREATE SCHEMA Product;
CREATE SCHEMA Time;
CREATE SCHEMA Network;
CREATE SCHEMA Support;
CREATE SCHEMA Billing;



Step 3: Table Creation
1. Fact Table: SalesFact
This table stores transactional data related to sales, customer interactions, and network activity.


CREATE TABLE Sales.SalesFact (
    SalesFact_ID INT IDENTITY(1,1) PRIMARY KEY,
    Customer_ID INT,
    Product_ID INT,
    Time_ID INT,
    Network_ID INT,
    Support_ID INT,
    Billing_ID INT,
    Sales_Amount DECIMAL(18,2),
    Quantity_Sold INT,
    Discount DECIMAL(18,2),
    Service_Interactions INT
);


2. Customer Dimension Table
This table stores customer-specific information.



CREATE TABLE Customer.CustomerDimension (
    Customer_ID INT PRIMARY KEY,
    Name VARCHAR(255),
    Age INT,
    Gender CHAR(1),
    Location VARCHAR(255),
    Customer_Type VARCHAR(50),
    Start_Date DATE,
    End_Date DATE,
    Current_Flag CHAR(1) DEFAULT 'Y'
);


3. Product Dimension Table
Stores data about products and services.

CREATE TABLE Product.ProductDimension (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(255),
    Product_Category VARCHAR(255),
    Price DECIMAL(18,2)
);



4. Time Dimension Table
Stores time-based attributes.


CREATE TABLE Time.TimeDimension (
    Time_ID INT PRIMARY KEY,
    Date DATE,
    Month VARCHAR(20),
    Quarter VARCHAR(20),
    Year INT
);


5. Network Dimension Table
Stores network-related data.

CREATE TABLE Network.NetworkDimension (
    Network_ID INT PRIMARY KEY,
    Network_Node VARCHAR(255),
    Latency DECIMAL(18,2),
    Uptime DECIMAL(18,2),
    Network_Status VARCHAR(50)
);


6. Support Dimension Table
Contains customer service and ticket details.

CREATE TABLE Support.SupportDimension (
    Support_ID INT PRIMARY KEY,
    Ticket_ID INT,
    Customer_ID INT,
    Issue_Type VARCHAR(255),
    Ticket_Status VARCHAR(50),
    Resolution VARCHAR(255),
    Created_Date DATE,
    Resolved_Date DATE
);


7. Billing Dimension Table
Stores customer billing data.

CREATE TABLE Billing.BillingDimension (
    Billing_ID INT PRIMARY KEY,
    Customer_ID INT,
    Billing_Amount DECIMAL(18,2),
    Billing_Date DATE,
    Payment_Status VARCHAR(50)
);


Step 4: Constraints for Data Integrity
We need to add primary keys, foreign keys, and other constraints to ensure referential integrity.

-- Adding Foreign Keys for the Fact Table
ALTER TABLE Sales.SalesFact
    ADD CONSTRAINT FK_SalesFact_Customer FOREIGN KEY (Customer_ID) REFERENCES Customer.CustomerDimension (Customer_ID),
    ADD CONSTRAINT FK_SalesFact_Product FOREIGN KEY (Product_ID) REFERENCES Product.ProductDimension (Product_ID),
    ADD CONSTRAINT FK_SalesFact_Time FOREIGN KEY (Time_ID) REFERENCES Time.TimeDimension (Time_ID),
    ADD CONSTRAINT FK_SalesFact_Network FOREIGN KEY (Network_ID) REFERENCES Network.NetworkDimension (Network_ID),
    ADD CONSTRAINT FK_SalesFact_Support FOREIGN KEY (Support_ID) REFERENCES Support.SupportDimension (Support_ID),
    ADD CONSTRAINT FK_SalesFact_Billing FOREIGN KEY (Billing_ID) REFERENCES Billing.BillingDimension (Billing_ID);


Step 5: Views
1. Sales Summary View
This view aggregates sales data by customer and region.

CREATE VIEW Sales.SalesSummary AS
SELECT
    c.Customer_ID,
    c.Name AS Customer_Name,
    SUM(sf.Sales_Amount) AS Total_Sales,
    COUNT(sf.SalesFact_ID) AS Transactions_Count
FROM Sales.SalesFact sf
JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
GROUP BY c.Customer_ID, c.Name;


2. Anonymized Customer View
This view masks sensitive customer data for privacy compliance.

CREATE VIEW Customer.AnonymizedCustomerView AS
SELECT
    c.Customer_ID,
    LEFT(c.Name, 1) + '*****' AS Anonymized_Name,
    c.Age,
    c.Location
FROM Customer.CustomerDimension c;


Stored Procedures
1. Get Total Sales by Customer and Product
This procedure will allow you to get total sales by customer and product, with the option to filter by date and product category.

CREATE PROCEDURE GetTotalSalesByCustomerProduct
    @CustomerID INT,
    @StartDate DATE,
    @EndDate DATE,
    @ProductCategory VARCHAR(255)
AS
BEGIN
    SELECT
        c.Name AS Customer_Name,
        p.Product_Name,
        SUM(sf.Sales_Amount) AS Total_Sales,
        COUNT(sf.SalesFact_ID) AS Transactions_Count
    FROM Sales.SalesFact sf
    JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
    JOIN Product.ProductDimension p ON sf.Product_ID = p.Product_ID
    WHERE c.Customer_ID = @CustomerID
      AND sf.Transaction_Date BETWEEN @StartDate AND @EndDate
      AND p.Product_Category = @ProductCategory
    GROUP BY c.Name, p.Product_Name;
END;



2. Get Churn Rate by Time Period (Year/Quarter)
This stored procedure calculates the churn rate based on a specific time period (year or quarter).


CREATE PROCEDURE GetChurnRateByPeriod
    @TimePeriod VARCHAR(10),   -- 'Year' or 'Quarter'
    @Year INT,
    @Quarter INT = NULL        -- Optional for Quarter, defaults to NULL
AS
BEGIN
    IF @TimePeriod = 'Year'
    BEGIN
        SELECT
            COUNT(DISTINCT c.Customer_ID) AS Churned_Customers
        FROM Sales.SalesFact sf
        JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
        JOIN Time.TimeDimension t ON sf.Time_ID = t.Time_ID
        WHERE t.Year = @Year
          AND sf.Sales_Amount = 0;  -- No sales = churned customer
    END
    ELSE IF @TimePeriod = 'Quarter'
    BEGIN
        SELECT
            COUNT(DISTINCT c.Customer_ID) AS Churned_Customers
        FROM Sales.SalesFact sf
        JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
        JOIN Time.TimeDimension t ON sf.Time_ID = t.Time_ID
        WHERE t.Year = @Year
          AND t.Quarter = @Quarter
          AND sf.Sales_Amount = 0;  -- No sales = churned customer
    END
    ELSE
    BEGIN
        PRINT 'Invalid Time Period';
    END
END;


3. Get Sales Breakdown by Region and Time
This stored procedure allows you to analyze sales performance by region (customer location) and time (monthly, quarterly, or yearly).


CREATE PROCEDURE GetSalesByRegionAndTime
    @Region VARCHAR(255),       -- Customer region (location)
    @TimePeriod VARCHAR(10),    -- 'Year', 'Quarter', or 'Month'
    @Year INT,
    @Quarter INT = NULL,        -- Optional for Quarter, defaults to NULL
    @Month INT = NULL           -- Optional for Month, defaults to NULL
AS
BEGIN
    IF @TimePeriod = 'Year'
    BEGIN
        SELECT
            c.Location AS Region,
            SUM(sf.Sales_Amount) AS Total_Sales,
            COUNT(sf.SalesFact_ID) AS Transactions_Count
        FROM Sales.SalesFact sf
        JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
        JOIN Time.TimeDimension t ON sf.Time_ID = t.Time_ID
        WHERE c.Location = @Region
          AND t.Year = @Year
        GROUP BY c.Location;
    END
    ELSE IF @TimePeriod = 'Quarter'
    BEGIN
        SELECT
            c.Location AS Region,
            SUM(sf.Sales_Amount) AS Total_Sales,
            COUNT(sf.SalesFact_ID) AS Transactions_Count
        FROM Sales.SalesFact sf
        JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
        JOIN Time.TimeDimension t ON sf.Time_ID = t.Time_ID
        WHERE c.Location = @Region
          AND t.Year = @Year
          AND t.Quarter = @Quarter
        GROUP BY c.Location;
    END
    ELSE IF @TimePeriod = 'Month'
    BEGIN
        SELECT
            c.Location AS Region,
            SUM(sf.Sales_Amount) AS Total_Sales,
            COUNT(sf.SalesFact_ID) AS Transactions_Count
        FROM Sales.SalesFact sf
        JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
        JOIN Time.TimeDimension t ON sf.Time_ID = t.Time_ID
        WHERE c.Location = @Region
          AND t.Year = @Year
          AND t.Month = @Month
        GROUP BY c.Location;
    END
    ELSE
    BEGIN
        PRINT 'Invalid Time Period';
    END
END;


4.Get Network Performance by Region and Date Range
This procedure fetches network performance data for a specific region over a given date range. It will help assess performance across different regions.

CREATE PROCEDURE GetNetworkPerformanceByRegion
    @Region VARCHAR(255),
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT
        n.Network_Node,
        n.Latency,
        n.Uptime,
        n.Network_Status
    FROM Network.NetworkDimension n
    JOIN Sales.SalesFact sf ON n.Network_ID = sf.Network_ID
    JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
    WHERE c.Location = @Region
      AND sf.Transaction_Date BETWEEN @StartDate AND @EndDate;
END;


5. Get Top N Products Based on Sales
This stored procedure returns the top N products based on total sales within a specified time period.

CREATE PROCEDURE GetTopNProductsBySales
    @TopN INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT
        p.Product_Name,
        SUM(sf.Sales_Amount) AS Total_Sales
    FROM Sales.SalesFact sf
    JOIN Product.ProductDimension p ON sf.Product_ID = p.Product_ID
    WHERE sf.Transaction_Date BETWEEN @StartDate AND @EndDate
    GROUP BY p.Product_Name
    ORDER BY Total_Sales DESC
    LIMIT @TopN;
END;


6. Get Total Sales and Quantity by Product and Customer
This procedure retrieves the total sales amount and quantity sold for each product by customer.

CREATE PROCEDURE GetSalesQuantityByProductCustomer
    @CustomerID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT
        p.Product_Name,
        SUM(sf.Sales_Amount) AS Total_Sales,
        SUM(sf.Quantity_Sold) AS Total_Quantity
    FROM Sales.SalesFact sf
    JOIN Product.ProductDimension p ON sf.Product_ID = p.Product_ID
    WHERE sf.Customer_ID = @CustomerID
      AND sf.Transaction_Date BETWEEN @StartDate AND @EndDate
    GROUP BY p.Product_Name;
END;


7. Get Customer Support Metrics
This procedure calculates metrics like the number of support tickets and average resolution time for a customer.

CREATE PROCEDURE GetCustomerSupportMetrics
    @CustomerID INT
AS
BEGIN
    SELECT
        COUNT(s.Support_ID) AS Total_Support_Tickets,
        AVG(DATEDIFF(DAY, s.Created_Date, s.Resolved_Date)) AS Avg_Resolution_Time_Days
    FROM Support.SupportDimension s
    WHERE s.Customer_ID = @CustomerID;
END;


Step 13: Using These Stored Procedures
Once you have these stored procedures in place, you can call them in your applications or querying interfaces by passing the relevant parameters.

Example Usage of Stored Procedures
Get Total Sales by Customer and Product:


EXEC GetTotalSalesByCustomerProduct 
    @CustomerID = 101,
    @StartDate = '2023-01-01',
    @EndDate = '2023-12-31',
    @ProductCategory = 'Mobile';


Get Churn Rate by Year:

EXEC GetChurnRateByPeriod 
    @TimePeriod = 'Year',
    @Year = 2023;


Get Sales Breakdown by Region and Time:

EXEC GetSalesByRegionAndTime 
    @Region = 'Addis Ababa',
    @TimePeriod = 'Quarter',
    @Year = 2023,
    @Quarter = 1;


Get Top N Products by Sales:

EXEC GetTopNProductsBySales 
    @TopN = 5,
    @StartDate = '2023-01-01',
    @EndDate = '2023-12-31';


Step 7: Indexes for Performance Optimization
Indexing commonly used columns to speed up queries:

-- Indexes on Fact Table
CREATE INDEX idx_sales_customer_id ON Sales.SalesFact (Customer_ID);
CREATE INDEX idx_sales_product_id ON Sales.SalesFact (Product_ID);

-- Index on Time Dimension for fast date-based queries
CREATE INDEX idx_time_year ON Time.TimeDimension (Year);

-- Index on Product Dimension for optimized product lookups
CREATE INDEX idx_product_name ON Product.ProductDimension (Product_Name);


Step 8: Aggregation Queries
Total Sales by Region (Customer Location)

SELECT
    c.Location AS Customer_Region,
    SUM(sf.Sales_Amount) AS Total_Sales,
    COUNT(sf.SalesFact_ID) AS Transactions_Count
FROM Sales.SalesFact sf
JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID
GROUP BY c.Location;



Step 9: Slowly Changing Dimensions (SCD Type 2)
To track changes in customer data over time (e.g., address changes), we implement SCD Type 2.

Add Start and End Dates to Customer Dimension

ALTER TABLE Customer.CustomerDimension
ADD Start_Date DATE, End_Date DATE, Current_Flag CHAR(1) DEFAULT 'Y';


Insert New Record and Mark the Old One as Inactive

-- Insert a new customer record when the address changes
INSERT INTO Customer.CustomerDimension
    (Customer_ID, Name, Age, Gender, Location, Customer_Type, Start_Date, End_Date, Current_Flag)
SELECT
    Customer_ID, Name, Age, Gender, 'New Address', Customer_Type,
    GETDATE() AS Start_Date, NULL AS End_Date, 'Y'
FROM Customer.CustomerDimension
WHERE Customer_ID = @Customer_ID AND Current_Flag = 'Y';

-- Update the old record to mark it as inactive
UPDATE Customer.CustomerDimension
SET End_Date = GETDATE(), Current_Flag = 'N'
WHERE Customer_ID = @Customer_ID AND Current_Flag = 'Y';


Step 10: Window Functions for Advanced Analytics
Running Total of Sales

SELECT
    c.Customer_ID,
    c.Name,
    sf.Sales_Amount,
    SUM(sf.Sales_Amount) OVER (PARTITION BY c.Customer_ID ORDER BY sf.SalesFact_ID) AS Running_Total
FROM Sales.SalesFact sf
JOIN Customer.CustomerDimension c ON sf.Customer_ID = c.Customer_ID;
