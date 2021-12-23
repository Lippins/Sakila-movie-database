-- Question 1
/* What are the top 10 countries in terms of customer base? */

SELECT co.country, COUNT(DISTINCT r.customer_id) customer_base
FROM country co
JOIN city ci
ON ci.country_id = co.country_id
JOIN address ad
ON ad.city_id = ci.city_id
JOIN customer cu
ON cu.address_id = ad.city_id
JOIN rental r
ON r.customer_id = cu.customer_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10


-- Question 2
/* What are the highest and least rented movie categories in terms of total rentals and revenue? */

WITH t1 AS (SELECT c.name AS movie_category, COUNT(*) AS no_of_rentals
		    FROM film f
		    JOIN film_category fc
		    ON f.film_id = fc.film_id
		    JOIN category c
		    ON c.category_id = fc.category_id
		    JOIN inventory i 
		    ON f.film_id = i.film_id
		    JOIN rental r
		    ON r.inventory_id = i.inventory_id
            GROUP BY 1),
			
     t2 AS (SELECT c.name AS movie_category, SUM(p.amount) AS total_revenue
		    FROM film f
		    JOIN film_category fc
		    ON f.film_id = fc.film_id
		    JOIN category c
		    ON c.category_id = fc.category_id
		    JOIN inventory i 
		    ON f.film_id = i.film_id
		    JOIN rental r
		    ON r.inventory_id = i.inventory_id
            JOIN payment p
            ON r.rental_id = p.rental_id
		    GROUP BY 1)

SELECT t1.movie_category, t1.no_of_rentals, t2.total_revenue
FROM t1
JOIN t2
ON t1.movie_category = t2.movie_category
ORDER BY 2 DESC;


-- Question 3
/* How do the number of movie rentals differ across both stores? */

WITH t1 AS (SELECT ('store ' || sto.store_id) AS store_name, c.name AS movie_category,
				COUNT(*) AS no_of_rentals
		    FROM store sto
		    JOIN staff sta
		    USING(store_id)
		    JOIN rental r
		    USING(staff_id)
		    JOIN Inventory i
		    USING(inventory_id)
		    JOIN film f
		    USING(film_id)
		    JOIN film_category fc
		    USING(film_id)
		    JOIN category c
		    USING(category_id)
		    GROUP BY 1,2
		    ORDER BY 2,1),
			
     t2 AS (SELECT movie_category, no_of_rentals AS store_1_rentals
		    FROM t1
		    WHERE store_name = 'store 1'),
	
     t3 AS (SELECT movie_category, no_of_rentals AS store_2_rentals
		    FROM t1
		    WHERE store_name = 'store 2')
			
SELECT t2.movie_category, t2.store_1_rentals, t3.store_2_rentals
FROM t2
JOIN t3
ON t2.movie_category = t3.movie_category


-- Question 4
/* Who are the top 10 customers. Which of them paid the most difference in terms of payments in 2017? */

WITH t1 AS (SELECT first_name || ' ' || last_name AS customer_name, SUM(amount) amount_paid
		    FROM customer c
		    JOIN payment p
		    ON c.customer_id = p.customer_id
	        GROUP BY 1
	        ORDER BY 2 DESC
	        LIMIT 10),
			
     t2 AS (SELECT DATE_TRUNC('month', payment_date) AS pay_date, 
	           first_name || ' ' || last_name AS customer_name, amount
		    FROM customer c
		    JOIN payment p
		    ON c.customer_id = p.customer_id
		    WHERE DATE_TRUNC('month', payment_date) BETWEEN '2007-01-01' AND '2008-01-01'),
	
     t3 AS (SELECT t2.pay_date, t2.customer_name, COUNT(*), SUM(t2.amount) AS total
		    FROM t2
		    JOIN t1
		    ON t2.customer_name = t1.customer_name
		    GROUP BY 1,2
		    ORDER BY 2,1),

     t4 AS (SELECT *,
     			COALESCE(LEAD(total) OVER (PARTITION BY customer_name ORDER BY customer_name),0) AS next_payment,
	   	      	COALESCE(LEAD(total) OVER (PARTITION BY customer_name ORDER BY customer_name) - total, 0) AS payment_difference  
	    	FROM t3)

SELECT customer_name, MAX(payment_difference) highest_difference_paid
FROM t4
GROUP BY 1
ORDER BY 2 DESC