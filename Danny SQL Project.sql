--Schema SQL Query SQL ResultsEdit on DB Fiddle
--CREATE SCHEMA dannys_diner;
--SET search_path = dannys_diner;

USE [Danny's Dinner sql];

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SELECT *
FROM sales;

SELECT *
FROM menu;

SELECT *
FROM members;

--(1.What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id,
    CONCAT('$', SUM(m.price)) AS total_amt
FROM
    sales s
JOIN
    menu m ON s.product_id = m.product_id
GROUP BY
    s.customer_id
ORDER BY
    total_amt DESC;

--2.--How many days has each customer visited the restaurant?
SELECT 
	s.customer_id,
	CONCAT(COUNT(DISTINCT order_date),  'days') as num_of_visitations
FROM 
    sales s
GROUP BY 
     s.customer_id
ORDER BY 
      num_of_visitations DESC;

--3--What was the first item from the menu purchased by each customer?
WITH First_purchase AS(
SELECT 
   s.customer_id,
   MIN(s.order_date) min_date
FROM 
    sales s
GROUP BY 
       s.customer_id)

SELECT
	DISTINCT 
	s.customer_id,
	f.min_date,
	s.product_id,
	m.product_name
FROM 
    First_purchase f
JOIN 
    sales s
ON
    f.min_date = s.order_date
AND 
    s.customer_id = f.customer_id
JOIN 
     menu m
ON 
   s.product_id = m.product_id;


---4---What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	TOP 1
	m.product_name,
	COUNT(*) num_of_orders,
	m.product_id
FROM 
     sales s
JOIN 
     menu m
ON 
     s.product_id = m.product_id
GROUP BY 
        m.product_id,m.product_name
ORDER BY 
        num_of_orders DESC;

--5--Which item was the most popular for each customer?
WITH popular_item AS (
SELECT
s.customer_id,
m.product_id,
m.product_name,
count(*) as num_of_orders,
RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rn
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id,m.product_name,m.product_id)

SELECT
customer_id,
product_name,
product_id
FROM popular_item
WHERE rn = 1;

--6--Which item was purchased first by the customer after they became a member?
WITH First_purchase_Customer AS(
 SELECT 
 s.customer_id,
 s.order_date,
 m.product_name,
 me.join_date,
 ROW_NUMBER () OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
 FROM sales s
 JOIN menu m
 ON m.product_id = s.product_id
 JOIN members me
 ON s.customer_id = me.customer_id
 AND me.join_date > s.order_date)

 SELECT
 customer_id,
 product_name
 FROM First_purchase_Customer
 WHERE rn = 1;
--7--Which item was purchased just before the customer became a member?
WITH Purchase_before_a_member AS(
SELECT
s.customer_id,
s.order_date,
me.join_date,
m.product_name,
RANK () OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnK
FROM sales s
JOIN menu m
ON m.product_id = s.product_id
JOIN members me
ON s.customer_id = me.customer_id
AND me.join_date < s.order_date
)
SELECT
customer_id,
product_name
FROM Purchase_before_a_member
WHERE rnK = 1;

--8--What is the total items and amount spent for each member before they became a member?
WITH Purchase_before_a_member AS(
SELECT
s.customer_id,
s.order_date,
me.join_date,
m.product_name
FROM sales s
JOIN menu m
ON m.product_id = s.product_id
JOIN members me
ON s.customer_id = me.customer_id
AND me.join_date > s.order_date
GROUP BY s.customer_id,s.order_date,me.join_date,m.product_name)
SELECT
customer_id,
product_name
FROM Purchase_before_a_member
--9-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
s.customer_id,
SUM(CASE
WHEN m.product_name = 'sushi' THEN 10 * 2 *m.price
ELSE 10 * m.price
END)AS Pointers
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY Pointers DESC;
--10-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH Points_after_joining AS (
SELECT
s.customer_id,s.order_date,
m.product_name,me.join_date, 
DATEADD(DAY,7,me.join_date) AS after_join_date,m.price
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members me ON s.customer_id = me.customer_id
)
SELECT 
customer_id,
SUM(
 CASE
WHEN order_date BETWEEN join_date AND after_join_date THEN 10 * 2 * price
WHEN order_date NOT BETWEEN join_date AND after_join_date AND product_name = 'sushi' THEN 2 * 10 * price
WHEN order_date NOT BETWEEN join_date AND after_join_date AND product_name != 'sushi' THEN 10 * price
END)
AS total_point
FROM Points_after_joining
WHERE MONTH(order_date) = 1
GROUP BY customer_id;

--BONUS QUESTIONS (Recreating tables by joining all)
IF OBJECT_ID('tempdb..#Customer_list') IS NOT NULL
    DROP TABLE #Customer_list;

CREATE TABLE #Customer_list
(
    customer_id CHAR (1),
	order_date DATE,
	product_name VARCHAR(255),
    price INT,
    member CHAR(1)
);

INSERT INTO #Customer_list (customer_id, order_date, product_name, price, member)
SELECT
    s.customer_id,
	 s.order_date,
	 m.product_name,
    m.price,
    CASE
        WHEN s.order_date < me.join_date THEN 'N'
        WHEN s.order_date >= me.join_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM
    sales s
JOIN
    menu m ON m.product_id = s.product_id
JOIN
    members me ON me.customer_id = s.customer_id;

SELECT *
FROM #Customer_list
---Ranking
SELECT *,
CASE
WHEN member = 'Y' THEN RANK ()  OVER(PARTITION BY customer_id ORDER BY order_date)
END AS Ranking
FROM #Customer_list