-- Task 1
WITH customer_data AS (
SELECT DISTINCT
	c.channel_desc,
	cus.cust_last_name,
	cus.cust_first_name,
	SUM(amount_sold) OVER(PARTITION BY c.channel_desc, cus.cust_id) AS amount_sold,
	SUM(amount_sold) OVER(PARTITION BY c.channel_desc) AS channel_total
FROM sh.sales s 
JOIN sh.channels c ON c.channel_id = s.channel_id 
JOIN sh.customers cus ON cus.cust_id = s.cust_id 
)
SELECT 
	channel_desc,
	cust_last_name,
	cust_first_name,
	ROUND(amount_sold, 2) AS amount_sold,
	REGEXP_REPLACE(TO_CHAR(sales_percentage, '9D99999 %'), ',', '.') AS sales_percentage
FROM (
SELECT 
	*,
	DENSE_RANK() OVER(PARTITION BY channel_desc ORDER BY amount_sold DESC) AS ranking, -- I used DENSE_RANK() because it displays the top 5 even in case of ties
	(amount_sold/channel_total)*100 AS sales_percentage
FROM customer_data) sq
WHERE sq.ranking <= 5;


-- Task 2
WITH sales_data AS ( -- cte for the purpose of retrieving required data
SELECT 
	p.prod_name,
	s.time_id,
	s.amount_sold 
FROM sh.sales s 
JOIN sh.products p ON p.prod_id = s.prod_id 
JOIN sh.customers c ON c.cust_id = s.cust_id 
JOIN sh.countries cn ON cn.country_id = c.country_id 
WHERE EXTRACT(Year FROM s.time_id) = 2000
	AND UPPER(cn.country_region) = 'ASIA'
	AND UPPER(p.prod_category) = 'PHOTO'
)

SELECT 
	prod_name,
	COALESCE(SUM(CASE WHEN EXTRACT(Quarter FROM time_id) = 1 THEN amount_sold END), 0) AS q1,
	COALESCE(SUM(CASE WHEN EXTRACT(Quarter FROM time_id) = 2 THEN amount_sold END), 0) AS q2,
	COALESCE(SUM(CASE WHEN EXTRACT(Quarter FROM time_id) = 3 THEN amount_sold END), 0) AS q3,
	COALESCE(SUM(CASE WHEN EXTRACT(Quarter FROM time_id) = 4 THEN amount_sold END), 0) AS q4,
	SUM(SUM(amount_sold)) OVER(PARTITION BY prod_name) AS year_sum -- SUM(SUM()) here because I want to aggregate 
FROM sales_data
GROUP BY prod_name
ORDER BY year_sum DESC;


-- Task 3
SELECT
	ch.channel_desc,
	c.cust_id, 
	c.cust_last_name, 
	c.cust_first_name, 
	ROUND(SUM(s.amount_sold), 2) AS total_sales	
FROM sh.sales s 
JOIN sh.customers c ON s.cust_id = c.cust_id 
JOIN sh.channels ch ON ch.channel_id = s.channel_id 
WHERE c.cust_id IN -- filter for the top 300 customers
	(SELECT DISTINCT cust_id FROM 
		(SELECT cust_id, DENSE_RANK() OVER(ORDER BY total_sales DESC) AS ranking
		FROM
			(SELECT DISTINCT
				c.cust_id, 
				c.cust_last_name, 
				c.cust_first_name, 
				SUM(s.amount_sold) AS total_sales	
			FROM sh.sales s 
			JOIN sh.customers c ON s.cust_id = c.cust_id 
			WHERE EXTRACT(Year FROM s.time_id) IN (1998, 1999, 2001)
			GROUP BY c.cust_id, c.cust_last_name, c.cust_first_name
			)) WHERE ranking <= 300) -- subquery for the top 300 customers by sales
GROUP BY ch.channel_desc, c.cust_id, c.cust_last_name, c.cust_first_name;


-- Task 4
SELECT 
	TO_CHAR(s.time_id, 'yyyy-mm') AS calender_month_desc,
	p.prod_category,
	SUM(CASE WHEN UPPER(cn.country_region) = 'AMERICAS' THEN s.amount_sold END) AS "America SALES",
	SUM(CASE WHEN UPPER(cn.country_region) = 'EUROPE' THEN s.amount_sold END) AS "Europe SALES"
FROM sh.sales s 
JOIN sh.products p ON s.prod_id = p.prod_id 
JOIN sh.customers c ON c.cust_id = s.cust_id 
JOIN sh.countries cn ON cn.country_id = c.country_id 
WHERE EXTRACT(Year FROM s.time_id) = 2000 AND EXTRACT(Month FROM s.time_id) IN (1, 2, 3)
GROUP BY TO_CHAR(s.time_id, 'yyyy-mm'), p.prod_category
ORDER BY calender_month_desc, p.prod_category



