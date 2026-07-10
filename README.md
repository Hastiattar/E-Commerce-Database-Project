E-Commerce Data Warehouse & Analytics Project

This project features a Data Warehouse environment designed for an e-commerce platform. It transforms raw transactional data into a clean, structured dimensional model (**Star Schema**) to perform advanced business intelligence and analytics using SQL Server.

---

## 🛠️ Tech Stack
* **Database Management System:** Microsoft SQL Server
* **Language:** T-SQL (Transact-SQL)
* **Design Pattern:** Dimensional Modeling (Star Schema)

---

## 🗺️ Database Architecture & Schema

The database is named `DataWarehouseAnalytics`. All clean, analytics-ready tables are organized under the `gold` schema.

### Core Tables:
* **`gold.dim_customers` (Dimension):** Contains customer demographics (e.g., country, marital status, gender, birthdate).
* **`gold.dim_products` (Dimension):** Manages product catalog details, including categories, subcategories, and cost tracking.
* **`gold.fact_sales` (Fact):** Stores transactional sales data, linking customers and products with metrics like sales amount, quantity, and price.

---

## 📊 Advanced SQL Analytics

Below are the key analytical queries implemented to extract business insights and track key performance indicators (KPIs):

### 1️⃣ Changing Over Time Analysis
> Evaluates trends and patterns over time, such as monthly sales growth, daily order volume, or user registration trends.

```sql
SELECT 
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,  
    SUM(quantity) AS total_quantity -- Added space before FROM
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
    YEAR(order_date), 
    MONTH(order_date);
```

### 2️⃣ Cumulative Analysis
> Performs cumulative calculations, such as calculating the running total of revenue over time to understand financial growth.

``` sql
CREATE VIEW gold.cumulative_sales_report AS
WITH monthly_summary AS (
    SELECT
        DATETRUNC(month, order_date) AS order_month,
        SUM(sales_amount)           AS total_sales,
        AVG(price)                  AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(month, order_date)
)
SELECT 
    order_month,
    total_sales,
    avg_price,
    -- 1. Lifetime Running Total
    SUM(total_sales) OVER (
        ORDER BY order_month
    ) AS cumulative_sales_lifetime,
    
    -- 2. Year-to-Date (YTD) Running Total (Resets every January)
    SUM(total_sales) OVER (
        PARTITION BY YEAR(order_month) 
        ORDER BY order_month
    ) AS cumulative_sales_ytd,
    
    -- 3. Cumulative Moving Average of Price
    AVG(avg_price) OVER (
        ORDER BY order_month
    ) AS cumulative_avg_price
FROM monthly_summary;
```
### 3️⃣ Performance Analysis
>Assesses the performance of products, categories, or overall sales (e.g., identifying top-selling items or lowest-performing inventory).
``` sql
create view  gold.performance as 
WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name 
)
SELECT 
    order_year, 
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales- avg(current_sales) over (partition by product_name) as diff_avg,
    case when current_sales- avg(current_sales) over (partition by product_name) >0 then 'above avg'
          when current_sales- avg(current_sales) over (partition by product_name) <0 then'bellow avg'
          else 'avg'
    end avg_change,
    lag(current_sales) over (partition by product_name order by order_year) as py_sales,
     lag(current_sales) over (partition by product_name order by order_year) - current_sales as diff_py,
     case  
     when  lag(current_sales) over (partition by product_name order by order_year) - current_sales> 0 then 'decrease'
     when  lag(current_sales) over (partition by product_name order by order_year) - current_sales<0 then 'increase'
     else ' no chang'
     end as py_change
FROM yearly_product_sales
```
### 4️⃣ Part-to-Whole Analysis
>Determines the proportion of individual components relative to the whole (e.g., each category's percentage contribution to total sales).
```sql

create view gold.part_of_whole as
with category_sales as(
select 
category,
sum(sales_amount) as total_sales
from gold.fact_sales f
left join  gold.dim_products p
on f.product_key = p.product_key
group by category)

select 
category,
total_sales,
sum (total_sales) over () overall_sales,
concat(round((cast(total_sales as float)/sum (total_sales) over () )*100 , 2) , '%') as percentage_of_total
from category_sales
```

### 5️⃣ Data Segmentation analysis
>Segments customers or products based on specific behaviors or attributes (e.g., categorizing products into cost ranges).
```sql
CREATE VIEW gold.data_segment AS
WITH product_segment AS (
    SELECT 
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    COUNT(product_key) AS total_product,
    cost_range
FROM product_segment
GROUP BY cost_range;
```
## 📋 Analytical Reports
>Two comprehensive reports designed to assist stakeholder decision-making:
### 📦 Product Report
>Provides a consolidated view of inventory status, total units sold, generated revenue, and profit margins per product.
```sql
create view  gold.report_product as
WITH base_query AS (
    SELECT 
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p 
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),
product_aggregations AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date) AS last_sales_date,
        COUNT(DISTINCT order_number) AS total_order,
        COUNT(DISTINCT customer_key) AS total_customer,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)
SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sales_date,
    DATEDIFF(MONTH, last_sales_date, GETDATE()) AS recency_in_months, 
    CASE 
        WHEN total_sales > 50000 THEN 'high_performance'
        WHEN total_sales >= 10000 THEN 'mid_range' 
        ELSE 'low_performance'
    END AS product_segment,
    lifespan,
    total_order,
    total_sales,
    total_quantity,
    total_customer,
    avg_selling_price,
    CASE 
        WHEN total_order = 0 OR total_order IS NULL THEN 0
        ELSE total_sales / total_order
    END AS avg_order_revenue,
    CASE
        WHEN lifespan = 0 OR lifespan IS NULL THEN total_sales 
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue
FROM product_aggregations;
```
### 👤 Customer Report
>Summarizes customer purchasing behavior, including first/last purchase dates, lifetime order frequency, and total lifetime value (LTV).
```sql
create view gold.customer_report as 
with base_query as (
    select 
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        concat(c.first_name, ' ', c.last_name) as customer_name, 
        datediff(year, c.birthdate, getdate()) as age
    from gold.fact_sales f
    left join gold.dim_customers c 
        on c.customer_key = f.customer_key
    where f.order_date is not null
), 
customer_aggregation as (
    select 
        customer_key,
        customer_number,
        customer_name,
        age, 
        count(distinct order_number) as total_orders,
        sum(sales_amount) as total_sales,
        sum(quantity) as total_quantity,
        count(distinct product_key) as total_product,
        max(order_date) as last_order_date,
        datediff(month, min(order_date), max(order_date)) as lifespan
    from base_query
    group by 
        customer_key,
        customer_number,
        customer_name,
        age
)
select 
    customer_key,
    customer_number,
    customer_name,
    age,
    case	
        when age < 20 then 'under 20'
        when age between 20 and 29 then '20-29'
        when age between 30 and 39 then '30-39'
        when age between 40 and 49 then '40-49'
        else '50 and above'
    end as age_group,
    case	
        when lifespan >= 12 and total_sales > 5000 then 'VIP'
        when lifespan >= 12 and total_sales <= 5000 then 'Regular'
        else 'New'
    end as customer_segment,
    total_orders,
    total_sales,
    total_quantity,
    total_product,
    last_order_date,
    lifespan,	
    datediff(month, last_order_date, getdate()) as recency,
    case
        when total_orders = 0 or total_orders is null then 0
        else total_sales / total_orders 
    end as avg_order_value,
    case
        when lifespan = 0 or lifespan is null then total_sales
        else total_sales / lifespan
    end as avg_monthly_spend
from customer_aggregation;
```
## 🚀 How to Run the Project
1- Open the initialization script (00_init_database.sql) in SQL Server Management Studio (SSMS).

2- Ensure your local CSV file paths match the BULK INSERT statements in the script.

3- Run the script to drop/recreate the DataWarehouseAnalytics database, build the tables, and load the datasets.

4- Execute any of the analysis queries above to see the results.

Ensure your local CSV file paths match the BULK INSERT statements in the script.

Run the script to drop/recreate the DataWarehouseAnalytics database, build the tables, and load the datasets.

Execute any of the analysis queries above to see the results.
