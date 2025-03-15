--QUESTION 1: Create a database named Customers and a table named FLO that includes the variables in the given dataset.
CREATE DATABASE CUSTOMERS

CREATE TABLE FLO (
	master_id							VARCHAR(50),
	order_channel						VARCHAR(50),
	last_order_channel					VARCHAR(50),
	first_order_date					DATE,
	last_order_date						DATE,
	last_order_date_online				DATE,
	last_order_date_offline				DATE,
	order_num_total_ever_online			INT,
	order_num_total_ever_offline		INT,
	customer_value_total_ever_offline	FLOAT,
	customer_value_total_ever_online	FLOAT,
	interested_in_categories_12			VARCHAR(50),
	store_type							VARCHAR(10)
);

--QUESTION 2: Write a query to show how many unique customers have made a purchase.
SELECT COUNT(DISTINCT(master_id)) AS DISTINCT_CUSTOMER_COUNT FROM FLO;

--QUESTION 3: Write a query to get the total number of purchases made and total revenue.
SELECT 
	SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOTAL_ORDER_COUNT,
	ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) AS TOTAL_REVENUE
FROM FLO;

--QUESTION 4: Write a query to get the average revenue per order.
SELECT  
	ROUND((SUM(customer_value_total_ever_offline + customer_value_total_ever_online) / 
	SUM(order_num_total_ever_online+order_num_total_ever_offline) 
	), 2) AS AVG_REVENUE_PER_ORDER 
 FROM FLO;

--QUESTION 5: Write a query to get the total revenue and number of purchases made through the last order channel (last_order_channel).
SELECT  last_order_channel AS LAST_ORDER_CHANNEL,
SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS TOTAL_REVENUE,
SUM(order_num_total_ever_online+order_num_total_ever_offline) AS TOTAL_ORDER_COUNT
FROM FLO
GROUP BY last_order_channel;

--QUESTION 6: Write a query to get the total revenue broken down by store type.
SELECT store_type AS STORE_TYPE, 
       ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) AS TOTAL_REVENUE 
FROM FLO 
GROUP BY store_type;

--BONUS: Parsed version of store type values.
SELECT Value,SUM(TOTAL_REVENUE/COUNT_) FROM
(
SELECT store_type AS STORE_TYPE,(SELECT COUNT(VALUE) FROM string_split(store_type,',') ) COUNT_,
       ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) AS TOTAL_REVENUE 
FROM FLO 
GROUP BY store_type) T
CROSS APPLY (SELECT  VALUE  FROM  string_split(T.STORE_TYPE,',') ) D
GROUP BY Value;

--QUESTION 7: Write a query to get the number of purchases broken down by year (based on the customer's first purchase date - first_order_date).
SELECT 
YEAR(first_order_date) AS YEAR,  SUM(order_num_total_ever_offline + order_num_total_ever_online) AS ORDER_COUNT
FROM  FLO
GROUP BY YEAR(first_order_date);

--QUESTION 8: Write a query to calculate the average revenue per purchase based on the last order channel breakdown.
SELECT last_order_channel, 
       ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online),2) AS TOTAL_REVENUE,
	   SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOTAL_ORDER_COUNT,
       ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online) / SUM(order_num_total_ever_offline + order_num_total_ever_online),2) AS EFFICIENCY
FROM FLO
GROUP BY last_order_channel;

--QUESTION 9: Write a query to get the most popular category in the last 12 months.
SELECT interested_in_categories_12, 
       COUNT(*) AS FREQUENCY_INFO 
FROM FLO
GROUP BY interested_in_categories_12
ORDER BY 2 DESC;

--BONUS: Parsed version of the categories.
SELECT K.VALUE,SUM(T.FREQUENCY_INFO/T.COUNT) FROM 
(
SELECT 
(SELECT COUNT(VALUE) FROM string_split(interested_in_categories_12,',')) AS COUNT,
REPLACE(REPLACE(interested_in_categories_12,']',''),'[','') AS CATEGORY, 
COUNT(*) AS FREQUENCY_INFO 
FROM FLO
GROUP BY interested_in_categories_12
) T 
CROSS APPLY (SELECT * FROM string_split(CATEGORY,',')) K
GROUP BY K.value;

--QUESTION 10: Write a query to get the most preferred store type.
SELECT TOP 1   
	store_type, 
    COUNT(*) AS FREQUENCY_INFO 
FROM FLO 
GROUP BY store_type 
ORDER BY 2 DESC;

--BONUS: Solution using row number.
SELECT * FROM
(
SELECT    
ROW_NUMBER() OVER(  ORDER BY COUNT(*) DESC) AS ROWNR,
	store_type, 
    COUNT(*) AS FREQUENCY_INFO 
FROM FLO 
GROUP BY store_type 
)T 
WHERE ROWNR=1;

--QUESTION 11: Write a query to get the most popular category and the revenue generated from this category based on the last order channel.
SELECT DISTINCT last_order_channel,
(
	SELECT TOP 1 interested_in_categories_12
	FROM FLO WHERE last_order_channel=f.last_order_channel
	GROUP BY interested_in_categories_12
	ORDER BY 
	SUM(order_num_total_ever_online+order_num_total_ever_offline) DESC 
),
(
	SELECT TOP 1 SUM(order_num_total_ever_online+order_num_total_ever_offline)
	FROM FLO WHERE last_order_channel=f.last_order_channel
	GROUP BY interested_in_categories_12
	ORDER BY 
	SUM(order_num_total_ever_online+order_num_total_ever_offline) DESC 
)
FROM FLO F;

--BONUS: Solution using CROSS APPLY.
SELECT DISTINCT last_order_channel,D.interested_in_categories_12,D.TOTAL_ORDERS
FROM FLO  F
CROSS APPLY 
(
	SELECT TOP 1 interested_in_categories_12,SUM(order_num_total_ever_online+order_num_total_ever_offline) AS TOTAL_ORDERS
	FROM FLO WHERE last_order_channel=f.last_order_channel
	GROUP BY interested_in_categories_12
	ORDER BY 
	SUM(order_num_total_ever_online+order_num_total_ever_offline) DESC 
) D;

--QUESTION 12: Write a query to get the ID of the customer who made the most purchases.
SELECT TOP 1 master_id   		    
	FROM FLO 
	GROUP BY master_id 
ORDER BY  SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC;

--BONUS: Using row number.
SELECT D.master_id
FROM 
	(SELECT master_id, 
		   ROW_NUMBER() OVER(ORDER BY SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC) AS RN
	FROM FLO 
	GROUP BY master_id) AS D
WHERE RN = 1;

--QUESTION 13: Write a query to get the average revenue per order and shopping frequency of the customer who made the most purchases.
SELECT D.master_id,ROUND((D.TOTAL_REVENUE / D.TOTAL_ORDER_COUNT),2) AS AVG_REVENUE_PER_ORDER,
ROUND((DATEDIFF(DAY, first_order_date, last_order_date)/D.TOTAL_ORDER_COUNT ),1) AS AVERAGE_SHOPPING_DAYS
FROM
(
SELECT TOP 1 master_id, first_order_date, last_order_date,
		   SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS TOTAL_REVENUE,
		   SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOTAL_ORDER_COUNT
	FROM FLO 
	GROUP BY master_id,first_order_date, last_order_date
ORDER BY TOTAL_REVENUE DESC
) D;

--QUESTION 14: Write a query to get the shopping frequency of the top 100 highest spending customers.
SELECT  
D.master_id,
       D.TOTAL_REVENUE,
	   D.TOTAL_ORDER_COUNT,
       ROUND((D.TOTAL_REVENUE / D.TOTAL_ORDER_COUNT),2) AS AVG_REVENUE_PER_ORDER,
	   DATEDIFF(DAY, first_order_date, last_order_date) AS DAYS_BETWEEN_FIRST_AND_LAST_PURCHASE,
	   ROUND((DATEDIFF(DAY, first_order_date, last_order_date)/D.TOTAL_ORDER_COUNT ),1) AS AVERAGE_SHOPPING_DAYS	 
FROM
(
SELECT TOP 100 master_id, first_order_date, last_order_date,
		   SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS TOTAL_REVENUE,
		   SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOTAL_ORDER_COUNT
	FROM FLO 
	GROUP BY master_id,first_order_date, last_order_date
ORDER BY TOTAL_REVENUE DESC
) D;

--QUESTION 15: Write a query to get the customer who made the most purchases in terms of revenue for each last order channel (last_order_channel).
SELECT DISTINCT last_order_channel,
(
	SELECT TOP 1 master_id
	FROM FLO WHERE last_order_channel=f.last_order_channel
	GROUP BY master_id
	ORDER BY 
	SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC 
) AS TOP_SPENDING_CUSTOMER,
(
	SELECT TOP 1 SUM(customer_value_total_ever_offline + customer_value_total_ever_online)
	FROM FLO WHERE last_order_channel=f.last_order_channel
	GROUP BY master_id
	ORDER BY 
	SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC 
) AS TOTAL_REVENUE
FROM FLO F;

--QUESTION 16: Write a query to get the ID of the last customer who made a purchase. 
--(If there are multiple customers who made purchases on the latest date, include them as well.)
SELECT master_id, last_order_date FROM FLO
WHERE last_order_date = (SELECT MAX(last_order_date) FROM FLO);
