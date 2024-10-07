-- Monday--Coffee_Analysis

create database coffee_day;
use coffee_day;
select * from customers;
select * from sales;
select * from city;
select * from products;

-- Report & --Data Analysis
-- Q1 Coffee Consume Count
-- How Many Peoples in each city are estimated to consume coffee ,given that 25% of population is does--

select city_name,
round(((population)*0.25),2)/1000000 as coffee_consumed_population,
city_rank from city
order by 2 Desc
limit 5; -- Top 5 cities to consume coffee more

--  Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select  ci.city_name,sum(total) as Revenue
from sales as s 
join customers as c 
on s.customer_id=c.customer_id
join city as ci 
on ci.city_id=c.city_id
where year(sale_date)=2023 and 
quarter(sale_date)=4
group by 1
order by 2 desc;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select p.product_name ,count(s.sale_id) as Total_orders
from products as p 
join sales as s 
on p.product_id=s.product_id
group  by p.product_name
order by 2 desc
limit 5;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city and total sale
-- number of customers in each these city

select 
city_name , sum(total) as Total_Revenue,
count(distinct s.customer_id) as total_customers,
sum(total)/count(distinct s.customer_id) as avg_sales_pr_cx
from sales as s
join customers as c 
on s.customer_id=c.customer_id
join city as ci 
on c.city_id= ci.city_id 
group by 1
order by 2 desc
limit 5;

-- Q5 city population and coffee consumer (25%)
-- provide list of cities with estimated population and coffee consumer 
-- return city_name,total_customer with estimated coffee consumer (25%)

with city_table 
as 
(
select city_name,
round((population*0.25)/1000000,2) as coffee_consumers_in_million
from city
),

customer_table
as 
(
select ci.city_name,
count(distinct c.customer_id) as unique_customers
from sales as s
join customers as c 
on s.customer_id= c.customer_id
join city as ci 
on ci.city_id=c.city_id
group by 1
)
select 
customer_table.city_name,
city_table.coffee_consumers_in_million,
customer_table.unique_customers
from city_table 
join customer_table
on city_table.city_name=customer_table.city_name
order by 2 desc;

-- Q6 top selling products by city 
-- what are the top 3 selling products by city as per the volume

select ci.city_name,
p.product_name,
count(sale_id) as sales
from sales as s
join products as p 
on s.product_id = p.product_id
join customers  as c 
on s.customer_id=c.customer_id
join city as ci 
on ci.city_id=c.city_id
group  by 1,2 
order by 1,3 desc;

select * 
from 
(
select ci.city_name,
p.product_name,
count(sale_id) as sales,
dense_rank() over(partition by ci.city_name order by count(sale_id) desc) as Ranks
from sales as s
join products as p 
on s.product_id = p.product_id
join customers  as c 
on s.customer_id=c.customer_id
join city as ci 
on ci.city_id=c.city_id
group  by 1,2 
) as t1
where Ranks <=3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select ci.city_name,
count(distinct c.customer_id) as unique_customers
from city as ci 
left join customers as c 
on ci.city_id=c.city_id
join sales as s
on s.customer_id=c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1;


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

with 
 city_table
 as
(
select ci.city_name,
count(distinct c.customer_id) as unique_cx,
sum(total)/count(distinct c.customer_id) as avg_revenue
from  sales as s
join customers as c 
on s.customer_id=c.customer_id
join city as ci 
on ci.city_id=c.city_id
group by 1
order by 2 desc
),

city_rent
as 
(
 select city_name,
estimated_rent
from city
)

select cr.city_name,
cr.estimated_rent,
cit.unique_cx,
cit.avg_revenue,
round((estimated_rent/unique_cx),2) as avg_sales_pr_cx
from city_table as cit
join city_rent as cr
on cit.city_name=cr.city_name
order by 5 desc;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city


with 
monthly_sales 
as 
(
select ci.city_name,
month(s.sale_date) as month_,
year(s.sale_date) as year_,
   sum(s.total) as total_sales
from sales as s 
join customers as c
on s.customer_id=c.customer_id
join city as ci
on ci.city_id =c.city_id
group by 1,2,3
order by 1,3,2
) ,

growth_ratio as
(
select 
city_name ,
month_,year_,
total_sales as cr_monthly_sales,
lag(total_sales,1) over(partition by city_name order by year_, month_) as last_month_sale
from monthly_sales
)

select 
city_name,month_,year_,
cr_monthly_sales,
last_month_sale,
 round(((cr_monthly_sales -last_month_sale)/last_month_sale *100),2 )as growth_ratio
from growth_ratio;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
with 
city_table 
as
(
select ci.city_name,
count(distinct c.customer_id) as unique_cx,
sum(s.total)as total_revenue,
sum(total)/count(distinct c.customer_id) as avg_revenue
from  sales as s
join customers as c 
on s.customer_id=c.customer_id
join city as ci 
on ci.city_id=c.city_id
group by 1
order by 2 desc
),

city_rent
as 
(
 select city_name,
estimated_rent,
round((population*0.25)/1000000,2) as coffee_consumer_in_million
from city
)

select cr.city_name,
cit.total_revenue,
cr.estimated_rent as total_rent,
cr.coffee_consumer_in_million,
cit.unique_cx,
cit.avg_revenue,
round((estimated_rent/unique_cx),2) as avg_sales_pr_cx
from city_table as cit
join city_rent as cr
on cit.city_name=cr.city_name
order by 2 desc;


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.


