CREATE VIEW gold.changing_over_time AS 
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