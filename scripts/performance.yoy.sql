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
