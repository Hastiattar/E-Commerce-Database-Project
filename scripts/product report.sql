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