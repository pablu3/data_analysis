-- Part 1
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
SELECT 
	title,
	release_year,
	rental_rate  
FROM film
WHERE film_id IN 
				(SELECT film_id -- subquery to retrieve all film_id of the films with 'animation' category
				FROM film_category fc
				WHERE category_id = 
									(SELECT category_id -- subquery to retrieve category_id of animation movies
									FROM category c 
									WHERE UPPER(name) = 'ANIMATION'))
AND release_year BETWEEN 2017 AND 2019
AND rental_rate > 1
ORDER BY title; 


--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
SELECT 
	CONCAT(a.address, ' ', a.address2) AS address,
	SUM(p.amount) AS revenue
FROM rental r 
INNER JOIN payment p 
ON r.rental_id = p.rental_id 
INNER JOIN inventory i 
ON r.inventory_id = i.inventory_id 
INNER JOIN store s 
ON i.store_id = s.store_id 
INNER JOIN address a 
ON s.address_id = a.address_id 
WHERE p.payment_date > '2017-03-31' -- after March = after the last day of March?
									-- depending on the company's accounting policies, the revenue could be recorded either on payment_date or rental_date
									-- I decided to filter based on payment date here because that was a correct approach in other tasks from this module
GROUP BY s.store_id, CONCAT(a.address, ' ', a.address2);


-- And another way of handling the address with the CTE
WITH address_cte AS (
SELECT 
	address_id,
	CONCAT(address, ' ', address2) AS address
FROM address 
)

SELECT 
	a.address,
	SUM(p.amount) AS revenue
FROM rental r 
INNER JOIN payment p 
ON r.rental_id = p.rental_id 
INNER JOIN inventory i 
ON r.inventory_id = i.inventory_id 
INNER JOIN store s 
ON i.store_id = s.store_id 
INNER JOIN address_cte a 
ON s.address_id = a.address_id 
WHERE p.payment_date > '2017-03-31'
GROUP BY a.address; -- this makes the group by clause more readable


--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
SELECT 
	a.first_name,
	a.last_name,
	COUNT(DISTINCT fa.film_id) AS number_of_movies -- I went for DISTINCT just to make sure that there are no duplicates among the movies
FROM film_actor fa 
INNER JOIN actor a 
ON a.actor_id = fa.actor_id 
INNER JOIN film f 
ON f.film_id = fa.film_id 
WHERE f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name 
ORDER BY number_of_movies DESC
LIMIT 5;


--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)
WITH drama AS ( -- CTE to retrieve all drama film_id's
SELECT 
	film_id,
	release_year
FROM film f 
WHERE film_id IN 
				(SELECT film_id -- subquery to filter for all film_id's with category_id belonging to 'drama'
				FROM film_category fc 
				WHERE category_id IN 
									(SELECT category_id -- subquery to filter for category_id's with 'drama' name
									FROM category c 
									WHERE UPPER(name) = 'DRAMA'))
),

travel AS ( -- CTE to retrieve all travel film_id's
SELECT 
	film_id,
	release_year
FROM film f 
WHERE film_id IN 
				(SELECT film_id
				FROM film_category fc 
				WHERE category_id IN 
									(SELECT category_id
									FROM category c 
									WHERE UPPER(name) = 'TRAVEL'))
),

documentary AS ( -- CTE to retrieve all documentary film_id's
SELECT 
	film_id,
	release_year
FROM film f 
WHERE film_id IN 
				(SELECT film_id
				FROM film_category fc 
				WHERE category_id IN 
									(SELECT category_id
									FROM category c 
									WHERE UPPER(name) = 'DOCUMENTARY'))
)

SELECT 
	COALESCE(d.release_year, t.release_year, doc.release_year) AS release_year, -- this COALESCE is used to deal with NULL release_years
	COUNT(DISTINCT d.film_id) AS number_of_drama_movies, -- DISTINCT to avoid counting of duplicates
	COUNT(DISTINCT t.film_id) AS number_of_travel_movies,
	COUNT(DISTINCT doc.film_id) AS number_of_documentary_movies
FROM drama d
FULL OUTER JOIN travel t -- FULL OUTER JOINS here because I know that table 1 may contain release years that are not present in table 2 and vice versa
ON d.release_year = t.release_year
FULL OUTER JOIN documentary doc
ON d.release_year = doc.release_year
GROUP BY COALESCE(d.release_year, t.release_year, doc.release_year)
ORDER BY release_year DESC;
-- This code takes up quite a lot of space but I decided to go for this approach because I find it readable due to CTEs

-- The same query without a CTE as requested in the comment
SELECT 
    f.release_year,
    COUNT(DISTINCT CASE WHEN UPPER(c.name) = 'DRAMA' THEN f.film_id END) AS number_of_drama_movies,
    COUNT(DISTINCT CASE WHEN UPPER(c.name) = 'TRAVEL' THEN f.film_id END) AS number_of_travel_movies,
    COUNT(DISTINCT CASE WHEN UPPER(c.name) = 'DOCUMENTARY' THEN f.film_id END) AS number_of_documentary_movies
    -- in this case I know the exact category names, but if I didn't, I would use a subquery in each of the case statements like this:
    -- COUNT(DISTINCT CASE WHEN c.category_id = (SELECT category_id FROM category WHERE UPPER(name) = 'DRAMA') THEN f.film_id END)
FROM film f
INNER JOIN film_category fc 
ON f.film_id = fc.film_id 
INNER JOIN category c 
ON fc.category_id = c.category_id
GROUP BY f.release_year
ORDER BY release_year DESC;



--------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Part 2
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Who were the top revenue-generating staff members in 2017? They should be rewarded with a bonus for their performance. Please indicate which store the employee worked in. If he changed stores during 2017, indicate the last one
SELECT 
	CONCAT(s.first_name, ' ', s.last_name) AS staff_full_name, -- only 5 staff members in the whole database?
	s2.store_id,
	CONCAT(a.address, ' ', a.address2) AS store_address,
	SUM(p.amount) AS staff_revenue 
FROM rental r 
INNER JOIN staff s 
ON r.staff_id = s.staff_id
INNER JOIN payment p 
ON p.rental_id = r.rental_id 
INNER JOIN store s2
ON s2.store_id = s.store_id 
INNER JOIN address a 
ON a.address_id = s2.address_id 
WHERE EXTRACT(Year FROM p.payment_date) = 2017 
GROUP BY 
	CONCAT(s.first_name, ' ', s.last_name),
	s2.store_id,
	CONCAT(a.address, ' ', a.address2)
ORDER BY staff_revenue DESC;



--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Which 5 movies were rented more than others, and what's the expected age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system'
SELECT 
	f.title,
	CASE 
		WHEN f.rating = 'G' THEN 'General audiences'
		WHEN f.rating = 'PG' THEN 'Parental guidance suggested'
		WHEN f.rating = 'PG-13' THEN 'Parents strongly cautioned'
		WHEN f.rating = 'R' THEN 'Restricted'
		WHEN f.rating = 'NC-17' THEN 'Adults only'
		END AS expected_age_of_audience,
	COUNT(r.rental_id) AS number_of_rentals
FROM film f 
INNER JOIN inventory i 
ON i.film_id = f.film_id 
INNER JOIN rental r 
ON r.inventory_id = i.inventory_id 
GROUP BY 
	f.title,
	CASE 
		WHEN f.rating = 'G' THEN 'General audiences'
		WHEN f.rating = 'PG' THEN 'Parental guidance suggested'
		WHEN f.rating = 'PG-13' THEN 'Parents strongly cautioned'
		WHEN f.rating = 'R' THEN 'Restricted'
		WHEN f.rating = 'NC-17' THEN 'Adults only' END -- once again, this long CASE statement in the group by could be avoided by using a CTE
ORDER BY number_of_rentals DESC
LIMIT 5;



-- Part 3
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Which actors/actresses didn't act for a longer period of time than the others? 
-- Version 1: gap between the latest release_year and current year per each actor 
WITH calculations AS ( -- CTE to retrieve the latest relase year per actor
SELECT  
	a.first_name || ' ' || a.last_name AS actor_full_name,
	MAX(f.release_year) AS latest_release_year
FROM actor a 
INNER JOIN film_actor fa 
ON a.actor_id = fa.actor_id 
INNER JOIN film f 
ON f.film_id = fa.film_id 
GROUP BY a.first_name || ' ' || a.last_name
)

SELECT
	actor_full_name,
	EXTRACT(Year FROM NOW()) - latest_release_year AS years_not_played -- summary column created from the CTE
FROM calculations
ORDER BY years_not_played DESC; 


-- Version 2: gaps between sequential films per each actor
WITH calculations AS ( -- same CTE as in version one but without aggregation (every release year per each actor)
SELECT  
	a.first_name || ' ' || a.last_name AS actor_full_name,
	f.release_year
FROM actor a 
INNER JOIN film_actor fa 
ON a.actor_id = fa.actor_id 
INNER JOIN film f 
ON f.film_id = fa.film_id 
ORDER BY actor_full_name, f.release_year DESC
),

gap_calculation AS ( -- another CTE to calculate the gaps in years between sequential movies per each actor
SELECT actor_full_name, release_year,
       release_year - 
       					(SELECT MAX(release_year) -- in this subquery I find the maximum release year of the previous movie for each actor
						FROM calculations AS c2
						WHERE c2.actor_full_name = c1.actor_full_name -- making sure that the actor's name is the same
						AND c2.release_year < c1.release_year) AS gap_in_years -- and also making sure that the release_year from the outer query is greater than the one from the subquery
						-- so as a result, this subquery returns the greatest release_year that is smaller than the release year from the outer query for each actor (which is a release year of the previous movie)
FROM calculations AS c1
ORDER BY actor_full_name, release_year DESC -- ordered 
)

SELECT 
	actor_full_name,
	MAX(gap_in_years) AS max_gap_in_years -- so this way I get the longest period when the actor hasn't played in any movies (per each actor)
FROM gap_calculation
GROUP BY actor_full_name;
-- This query could be rewritten into a much simpler format using window functions (but we are not allowed to use them) + it is super slow to run


-- Version 3: gap between the release of their first and last film
WITH calculations AS ( -- CTE to retrieve the latest and the earliest relase year per actor
SELECT  
	a.first_name || ' ' || a.last_name AS actor_full_name,
	MAX(f.release_year) AS latest_release_year,
	MIN(f.release_year) AS earliest_release_year
FROM actor a 
INNER JOIN film_actor fa 
ON a.actor_id = fa.actor_id 
INNER JOIN film f 
ON f.film_id = fa.film_id 
GROUP BY a.first_name || ' ' || a.last_name
)

SELECT
	actor_full_name,
	latest_release_year - earliest_release_year AS years_gap -- summary column created from the CTE
FROM calculations
ORDER BY years_gap DESC;