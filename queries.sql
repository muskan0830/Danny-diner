SELECT * FROM members;
SELECT * FROM menu;
SELECT * FROM sales;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price * s.product_id) AS Total_Amount
FROM sales s
INNER JOIN menu m
ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;
-- Amount spent by Customer A:178, B:152, C:108

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(order_date)
FROM sales
GROUP BY 1
ORDER BY 2 DESC;
-- Days Visited by customer B: 6, A:6, C:3

-- 3. What was the first item from the menu purchased by each customer?
WITH menu_rank AS 
(
   SELECT customer_id,
          ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranked,
	      product_id
   FROM sales
)

SELECT mr.customer_id, m.product_name
FROM menu_rank mr
INNER JOIN menu m
ON m.product_id = mr.product_id
WHERE ranked = 1
GROUP BY 1,2;
-- First menu ordered by each customer is: A-Sushi, B: curry, C:ramen

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id)
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC;
-- Most Purchased item: Ramen

SELECT s.customer_id, COUNT(s.product_id)
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
WHERE m.product_name = 'ramen'
GROUP BY 1
ORDER BY 2 DESC;
-- Total times purchased by each customer: C-3,B-3,A-2

-- 5. Which item was the most popular for each customer?
WITH product_count AS 
(
   SELECT customer_id, 
          product_id,
          COUNT(product_id) AS productCount,
          DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS ranked
   FROM sales
   GROUP BY 1,2
)

SELECT pc.customer_id, m.product_name, pc.productCount
FROM product_count pc
INNER JOIN menu m
ON pc.product_id = m.product_id 
WHERE ranked = 1
GROUP 1,2,3;
-- A: Ramen, bought 3 times ; B-curry, ramen, sushi, each bought 2 times, C: sushi, bought 3 time

-- 6. Which item was purchased first by the customer after they became a member?
SELECT s.customer_id, m.product_name
FROM sales s
INNER JOIN menu m
ON m.product_id = s.product_id
RIGHT JOIN members mb
ON mb.customer_id = s.customer_id
WHERE s.order_date > mb.join_date
GROUP BY 1,2;
-- A: Ramen, B: Sushi, C: Ramen

-- 7. Which item was purchased just before the customer became a member?
SELECT s.customer_id, m.product_name
FROM sales s
INNER JOIN menu m
ON m.product_id = s.product_id
RIGHT JOIN members mb
ON mb.customer_id = s.customer_id
WHERE s.order_date < mb.join_date
GROUP BY 1,2;
-- both A,B: curry, sushi

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) AS total_items, SUM(m.price * s.product_id) AS Total_amount_Spent
FROM sales s
INNER JOIN menu m
ON m.product_id = s.product_id
RIGHT JOIN members mb
ON mb.customer_id = s.customer_id
WHERE s.order_date < mb.join_date
GROUP BY 1;
-- B: 3 items,amount spent:70 ; A: 2 items,amount spent:40

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id,
       SUM(
		   CASE
	       WHEN m.product_name = 'sushi' Then m.price * 20
	       ELSE m.price * 10
	       END) AS Total_points
FROM sales s
INNER JOIN menu m
ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;
--B:940, A:860, C:360

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,
       SUM(
		   CASE
               WHEN m.product_name = 'sushi' THEN m.price * 20
               WHEN s.order_date < mb.join_date + INTERVAL '1 week' THEN m.price * 20
               ELSE m.price * 10
	       END) AS Total_points
FROM sales s
INNER JOIN menu m
ON m.product_id = s.product_id
RIGHT JOIN members mb
ON s.customer_id = mb.customer_id
GROUP BY 1
ORDER BY 2 DESC;
--A:1520, B:1240