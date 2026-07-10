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
    -- Fixed typo: 'gold.fact_salse' to 'gold.fact_sales'
    from gold.fact_sales f
    left join gold.dim_customers c 
        on c.customer_key = f.customer_key
    -- Fixed typo: 'where order_date' (added space)
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
    end as age_group, -- Removed single quotes from alias name
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
        -- Prevent division by zero if lifespan is 0
        when lifespan = 0 or lifespan is null then total_sales
        else total_sales / lifespan
    end as avg_monthly_spend
from customer_aggregation;