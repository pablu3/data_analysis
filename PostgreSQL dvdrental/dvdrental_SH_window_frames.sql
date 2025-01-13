-- Task 1
-- First CTE to calculate total sales using different aggregations
WITH cte AS (
SELECT 
	cn.country_region,
	EXTRACT(Year FROM s.time_id) AS calendar_year,
	c.channel_desc,
	SUM(amount_sold) AS amount_sold,
	SUM(SUM(amount_sold)) OVER(PARTITION BY cn.country_region, EXTRACT(Year FROM s.time_id)) AS total_sales
	-- partitioned by region and year
FROM sales s 
JOIN channels c ON c.channel_id = s.channel_id 
JOIN customers cus ON cus.cust_id = s.cust_id 
JOIN countries cn ON cn.country_id = cus.country_id 
WHERE EXTRACT(Year FROM time_id) IN (1999, 2000, 2001)
GROUP BY cn.country_region, EXTRACT(Year FROM s.time_id), c.channel_desc -- I know that it is more appropriate to GROUP BY ids, but those columns have to be in the query anyways
),
-- second CTE to perform calculations on aggregated totals
cte2 AS (
SELECT 
	cte.*, 
	amount_sold/total_sales*100 AS by_channels,
	COALESCE(LAG(amount_sold/total_sales*100) OVER(PARTITION BY country_region, channel_desc ORDER BY calendar_year), 0) AS previous_period
	-- no previous period in the main query, so I have to take care of the NULLs using COALESCE
FROM cte
ORDER BY country_region, calendar_year, channel_desc -- I used ORDER BY here so I didn't have to use it in PARTITION BY
)
-- final query to calculate current vs previous period diff
SELECT 
	country_region,
	calendar_year,
	channel_desc,
	TO_CHAR(ROUND(amount_sold, 0), '999G999G999 $') AS amount_sold,
	TO_CHAR(ROUND(by_channels, 2), '99D99 %') AS "% BY CHANNELS",
	CASE 
		WHEN previous_period != 0 THEN TO_CHAR(ROUND(previous_period, 2), '99D99 %')
		ELSE 'N/A' END AS "% PREVIOUS PERIOD", 
	CASE 
		WHEN previous_period != 0 THEN TO_CHAR(ROUND(by_channels - previous_period, 2), '99D99 %')
		ELSE 'N/A' END AS "% DIFF"
FROM cte2
ORDER BY country_region, calendar_year, channel_desc;


-- Task 2
SELECT 
	EXTRACT(Week FROM s.time_id) AS calendar_week_number,
	s.time_id,
	TO_CHAR(s.time_id, 'Day') AS day_name, -- to get the day of the week
	SUM(amount_sold) AS sales,
	SUM(SUM(amount_sold)) OVER(PARTITION BY EXTRACT(Week FROM s.time_id) 
			 					ORDER BY s.time_id 
			 					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum,
	ROUND(CASE 
		WHEN TO_CHAR(s.time_id, 'Day') = 'Monday' THEN 
			AVG(SUM(amount_sold)) OVER(ORDER BY s.time_id ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING)	
		WHEN TO_CHAR(s.time_id, 'Day') = 'Friday' THEN 
			AVG(SUM(amount_sold)) OVER(ORDER BY s.time_id ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING)	
		ELSE AVG(SUM(amount_sold)) OVER(ORDER BY s.time_id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
	END, 2) AS centered_3_day_avg
FROM sales s 
JOIN channels c ON c.channel_id = s.channel_id 
JOIN customers cus ON cus.cust_id = s.cust_id 
JOIN countries cn ON cn.country_id = cus.country_id 
WHERE EXTRACT(Week FROM time_id) IN (49, 50, 51) AND EXTRACT(Year FROM s.time_id) = 1999
GROUP BY EXTRACT(Week FROM s.time_id), s.time_id, TO_CHAR(s.time_id, 'Day');


-- Task 3
SELECT 
	channel_id,
	EXTRACT(Year FROM time_id) AS sales_year,
	EXTRACT(Month FROM time_id) AS sales_month,
	SUM(amount_sold) AS sales,
-- the obvious case for using ROWS BETWEEN is a cumulative sum, but a little bit more complicated example...
-- first case - ROWS, this is a very useful of defining a frame when performing aggregated calculations within a specified period
-- in my example, each single period is 1 month
	SUM(SUM(amount_sold)) OVER(PARTITION BY EXTRACT(Year FROM time_id) ORDER BY EXTRACT(Month FROM time_id)
								ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS rows_example,
								
-- second case - RANGE, it is useful when whe want to calculate aggragated data within a specified period frame, but it contains another variable
-- in case of RANGE BETWEEN, SQL takes into account not only X number of rows preceding or following the current row
-- for RANGE, every row within a frame that has a same value, counts too
	SUM(SUM(amount_sold)) OVER(PARTITION BY channel_id
								ORDER BY EXTRACT(Month FROM time_id)
								RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS range_example,
-- in above example, I partition only by channel but the cumulative sum is calculated for a specified month using values from all available years, because they have the same month in them
FROM sales s 
WHERE channel_id = 4
GROUP BY channel_id, EXTRACT(Year FROM time_id), EXTRACT(Month FROM time_id)
ORDER BY sales_year, sales_month;


-- finally GROUPS
-- in GROUPS, 1 row shift means either a shift of 1 row or a shift of 1 group of related rows
-- therefore here, if there are missing months, RANGE will return the previous value, but GROUPS will
SELECT 
	EXTRACT(Month FROM time_id) AS sales_month,
	SUM(amount_sold) AS sales,
	FIRST_VALUE(SUM(amount_sold)) OVER(ORDER BY EXTRACT(Month FROM time_id) 
										RANGE BETWEEN 1 PRECEDING AND CURRENT ROW) AS range_example,
	FIRST_VALUE(SUM(amount_sold)) OVER(ORDER BY EXTRACT(Month FROM time_id) 
										GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW) AS groups_example
FROM sales s
WHERE EXTRACT(Month FROM time_id) IN (1, 2, 3, 4, 8, 9, 10 ,11, 12)
GROUP BY EXTRACT(Month FROM time_id)
ORDER BY sales_month;





