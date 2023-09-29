--What was the total quantity sold for all products?

SELECT sum(qty)
FROM [data_mart].[dbo].[sales]

---What is the total generated revenue for all products before discounts?
SELECT 
	SUM(price * qty) AS nodis_revenue
FROM [data_mart].[dbo].[sales] AS sales;

--for each product category
SELECT 
	details.product_name,
	SUM(sales.qty * sales.price) AS nodis_revenue
FROM [data_mart].[dbo].[sales] AS sales
INNER JOIN [data_mart].[dbo].product_details AS details
	ON sales.prod_id = details.product_id
GROUP BY details.product_name
ORDER BY nodis_revenue DESC;


--How many unique transactions were there?
SELECT 
	COUNT (DISTINCT txn_id) AS unique_txn
FROM [data_mart].[dbo].[sales]



--What was the total discount amount for all products?
SELECT sum(discount)
FROM [data_mart].[dbo].[sales]

--What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH cte_trans AS (
  SELECT
    txn_id,
    qty * price AS revenue
  FROM [data_mart].[dbo].[sales]
  GROUP BY txn_id, qty, price
)
SELECT TOP 1
   PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY revenue) OVER() AS pct_25,
   PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY revenue) OVER() AS pct_50,
   PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY revenue) OVER() AS pct_75
FROM cte_trans
ORDER BY revenue;

--What is the average discount value per transaction?

SELECT prod_id, AVG(s.discount) avg_discount
FROM [data_mart].[dbo].[sales] s
GROUP BY prod_id


WITH cte_transaction_discounts AS (
	SELECT
		txn_id,
		SUM(price * qty * discount)/100 AS total_discount
	FROM [data_mart].[dbo].[sales]
	GROUP BY txn_id
)
SELECT
	ROUND(AVG(total_discount), 0) AS avg_unique_products
FROM cte_transaction_discounts;

--What is the percentage split of all transactions for members vs non-members?
SELECT *
FROM [data_mart].[dbo].[sales]

SELECT COUNT(DISTINCT member)
FROM [data_mart].[dbo].[sales]

SELECT 
    (COUNT(CASE WHEN member = 't' THEN 1 END) * 100.0 / COUNT(*)) AS t_percentage,
    (COUNT(CASE WHEN member = 'f' THEN 1 END) * 100.0 / COUNT(*)) AS f_percentage
FROM [data_mart].[dbo].[sales]

--What is the average revenue for member transactions and non-member transactions?

WITH cte_member_revenue AS (
  SELECT
    member,
    txn_id,
    SUM(price * qty) AS revenue
  FROM [data_mart].[dbo].[sales]
  GROUP BY 
	member, 
	txn_id
)
SELECT
  member,
  ROUND(AVG(revenue), 2) AS avg_revenue
FROM cte_member_revenue
GROUP BY member;


---What are the top 3 products by total revenue before discount?


SELECT prod_id, SUM(qty*price) AS revenue
FROM [data_mart].[dbo].[sales]
GROUP BY prod_id
ORDER BY revenue DESC;

SELECT prod_id, SUM(qty * price) AS revenue
FROM [data_mart].[dbo].[sales]
GROUP BY prod_id
ORDER BY revenue DESC;


SELECT TOP 3
    details.product_name,
    SUM(sales.qty * sales.price) AS nodis_revenue
FROM [data_mart].[dbo].[sales]
INNER JOIN [data_mart].[dbo].[product_details] AS details
    ON sales.prod_id = details.product_id
GROUP BY details.product_name
ORDER BY nodis_revenue DESC;

--What is the total quantity, revenue and discount for each segment?
WITH cte_prosales AS (
SELECT pro.segment_id, pro.product_name, pro.segment_name, sales.qty, sales.price, sales.discount
FROM [data_mart].[dbo].product_details pro
INNER JOIN [data_mart].[dbo].[sales] sales
ON pro.product_id = sales.prod_id
)
SELECT product_name, segment_name, COUNT(qty) Quantity,
	SUM(qty*price) AS revenue 
FROM cte_prosales
GROUP BY segment_id, segment_name, product_name
	
--What is the top selling product for each segment?
SELECT TOP 5
	details.segment_id,
	details.segment_name,
	details.product_id,
	details.product_name,
	SUM(sales.qty) AS product_quantity
FROM [data_mart].[dbo].[sales] AS sales
INNER JOIN [data_mart].[dbo].product_details AS details
	ON sales.prod_id = details.product_id
GROUP BY
	details.segment_id,
	details.segment_name,
	details.product_id,
	details.product_name
ORDER BY product_quantity DESC

--What is the total quantity, revenue and discount for each category
WITH cte_category AS (
SELECT pro.category_id, sales.qty, sales.price, sales.discount
FROM [data_mart].[dbo].product_details pro
INNER JOIN [data_mart].[dbo].[sales] sales
ON pro.product_id = sales.prod_id
)
SELECT category_id, COUNT(qty) Quantity,
	SUM(qty*price) AS revenue 
FROM cte_category
GROUP BY category_id
ORDER BY revenue DESC

--What is the top selling product for each category?
WITH cte_category AS (
SELECT pro.category_id, pro.category_name, pro.product_name, sales.qty, sales.price, sales.discount
FROM [data_mart].[dbo].product_details pro
INNER JOIN [data_mart].[dbo].[sales] sales
ON pro.product_id = sales.prod_id
)
SELECT category_id, product_name,SUM(qty) Quantity,
	SUM(qty*price) AS revenue 
FROM cte_category
GROUP BY category_id, product_name
ORDER BY revenue DESC

--What is the percentage split of revenue by product for each segment?
WITH cte_product_revenue AS (
  SELECT
    product_details.segment_id,
    product_details.segment_name,
    product_details.product_id,
    product_details.product_name,
    SUM(sales.qty * sales.price) AS product_revenue
  FROM [data_mart].[dbo].[sales]
  INNER JOIN [data_mart].[dbo].product_details
    ON sales.prod_id = product_details.product_id
  GROUP BY
    product_details.segment_id,
    product_details.segment_name,
    product_details.product_id,
    product_details.product_name
)
SELECT
	segment_name,
	product_name,
	ROUND(
    100 * product_revenue /
      SUM(product_revenue) OVER (
        PARTITION BY segment_id),
    	2) AS segment_product_percentage
FROM cte_product_revenue
ORDER BY
	segment_id,
	segment_product_percentage DESC;
--What is the percentage split of revenue by segment for each category?
WITH cte_product_revenue AS (
  SELECT
    product_details.segment_id,
    product_details.segment_name,
    product_details.category_id,
    product_details.category_name,
    SUM(sales.qty * sales.price) AS product_revenue
  FROM [data_mart].[dbo].[sales]
  INNER JOIN [data_mart].[dbo].product_details
    ON sales.prod_id = product_details.product_id
  GROUP BY
    product_details.segment_id,
    product_details.segment_name,
    product_details.category_id,
    product_details.category_name
)
SELECT
	category_name,
	segment_name,
	ROUND(
    100 * product_revenue /
      SUM(product_revenue) OVER (
        PARTITION BY category_id),
    	2) AS category_segment_percentage
FROM cte_product_revenue
ORDER BY
	category_id,
	category_segment_percentage DESC;

--What is the percentage split of total revenue by category?
SELECT 
   ROUND(100 * SUM(CASE WHEN details.category_id = 1 THEN (sales.qty * sales.price) END) / 
		 SUM(qty * sales.price),
		 2) AS category_1,
   (100 - ROUND(100 * SUM(CASE WHEN details.category_id = 1 THEN (sales.qty * sales.price) END) / 
		 SUM(sales.qty * sales.price),
		 2)
	) AS category_2
FROM [data_mart].[dbo].[sales] AS sales
INNER JOIN [data_mart].[dbo].product_details AS details
	ON sales.prod_id = details.product_id