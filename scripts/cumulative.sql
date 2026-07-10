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