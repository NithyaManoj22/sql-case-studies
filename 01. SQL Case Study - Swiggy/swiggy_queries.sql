-- 1. Find the customers who never placed an order
SELECT u.name FROM users u
FULL OUTER JOIN orders o
ON u.user_id = o.user_id
WHERE o.user_id IS NULL;

-- using left join on users to retrieve all users
SELECT u.name FROM users u
LEFT JOIN orders o
ON u.user_id = o.user_id
WHERE o.user_id IS NULL;

-- using subqueries
SELECT name FROM users
WHERE users.user_id NOT IN (SELECT DISTINCT(user_id) FROM orders );

-- 2. Find the average price per dish with the highest average price
SELECT f.f_name, t.f_id, t.Average_Price
FROM (SELECT f_id, ROUND(AVG(price),2) as Average_Price
      FROM menu
      GROUP BY f_id) t
JOIN food f
ON t.f_id = f.f_id
ORDER BY t.Average_Price DESC;

-- without subquery
SELECT f.f_name, m.f_id, ROUND(AVG(m.price),2) as Average_Price
FROM menu m
JOIN food f
ON m.f_id = f.f_id
GROUP BY f.f_id;

-- 3. Find the top restaurant in terms of the number of orders for a given month
SELECT r_name, Month, Max_Orders_For_Month
       FROM
            (SELECT r.r_name, strftime('%m',  date) as 'Month', o.r_id, COUNT(order_id) as  Number_of_Orders,
                    MAX(COUNT(order_id)) OVER(PARTITION BY (strftime('%m',  date))  ORDER BY COUNT(order_id) DESC) as Max_Orders_For_Month
            FROM orders o
            JOIN restaurants r
            ON o.r_id = r.r_id
            GROUP BY strftime('%m',  date), o.r_id) t
WHERE t.Number_of_Orders = Max_Orders_For_Month;

-- 4. restaurants with monthly sales greater than x for
-- using subquery
SELECT Month, r_name, r_id, Sales
    FROM
        (SELECT strftime('%m',  date) as 'Month', r.r_name, o.r_id,SUM(amount) as 'Sales'
        FROM orders o
        JOIN restaurants r
        ON o.r_id = r.r_id
        GROUP BY strftime('%m',  date), o.r_id) t
WHERE t.Sales > 500;

-- using Having clause
SELECT strftime('%m',  date) as 'Month', r.r_name, o.r_id,SUM(amount) as 'Sales'
FROM orders o
JOIN restaurants r
ON o.r_id = r.r_id
GROUP BY strftime('%m',  date), o.r_id
HAVING SUM(amount) > 500;

-- 5. Show all orders with order details for a particular customer in a particular date range
-- Assuming date range between May 15 and June 15
SELECT o.order_id, u.name,r.r_name, f.f_name, os.amount, os.date
FROM order_details o
JOIN food f
ON o.f_id = f.f_id
JOIN orders os
ON os.order_id = o.order_id
JOIN users u
ON u.user_id = os.user_id
JOIN restaurants r
ON r.r_id = os.r_id
WHERE u.name LIKE 'Ankit' AND (os.date BETWEEN '2022-06-15' AND '2022-07-01')  ;

-- 6. Find those restaurants with maximum number of repeated customers
-- Dense Rank not required, did it for practice
SELECT *, count(user_id) as max_repeat_customers
FROM
       (SELECT o.r_id, r.r_name, o.user_id, count(*) AS Number_of_Visits,
               DENSE_RANK() OVER(PARTITION BY o.r_id ORDER BY count(*) DESC ) AS Rank_RepeatCustomers,
               MAX(count(*)) OVER() AS Max_Visit_For_Restaurant
        FROM orders o
        JOIN restaurants r
        ON r.r_id = o.r_id
        GROUP BY o.r_id, o.user_id) t
WHERE t.Number_of_Visits >= Max_Visit_For_Restaurant ;
GROUP BY t.r_name
ORDER by count(user_id) DESC
LIMIT 1;

-- 7. Month over Month revenue growth of Swiggy
SELECT *,
       ((t.Month_Total - t.Lag) * 100/t.Lag)
FROM(SELECT strftime('%m',  date) as 'Month', SUM(amount) as Month_Total,LAG(SUM(amount)) OVER() as Lag
    FROM orders
    GROUP BY strftime('%m',  date)) t;

-- 8. each customer's favourite food
SELECT *
FROM (SELECT o.order_id ,os.user_id, u.name, o.f_id, f.f_name, COUNT(f.f_name) as Number_Orders,
             DENSE_RANK() OVER(PARTITION BY os.user_id ORDER BY COUNT(f.f_name) DESC) as Order_Rank
    FROM order_details o
    JOIN food f
    ON o.f_id = f.f_id
    JOIN orders os
    ON os.order_id = o.order_id
    JOIN users u
    ON u.user_id = os.user_id
    GROUP BY os.user_id, o.f_id
    ) t
WHERE Order_Rank = 1;

-- As a CTE
WITH Food_Preference AS (
    SELECT o.order_id ,os.user_id, u.name, o.f_id, f.f_name, COUNT(f.f_name) as Number_Orders,
             DENSE_RANK() OVER(PARTITION BY os.user_id ORDER BY COUNT(f.f_name) DESC) as Order_Rank
    FROM order_details o
    JOIN food f
    ON o.f_id = f.f_id
    JOIN orders os
    ON os.order_id = o.order_id
    JOIN users u
    ON u.user_id = os.user_id
    GROUP BY os.user_id, o.f_id
)

SELECT * FROM Food_Preference WHERE Order_Rank = 1;

-- 9. Identify the most loyal customers for all restaurants
SELECT *
FROM (SELECT r.r_name,u.name, COUNT(*) Number_Visits,
       DENSE_RANK() OVER(PARTITION BY o.r_id ORDER BY COUNT(*) DESC) AS Visit_Rank
FROM orders o
JOIN users u
ON u.user_id = o.user_id
JOIN restaurants r
ON r.r_id = o.r_id
GROUP BY o.r_id, o.user_id) t
WHERE Visit_Rank = 1;

-- 10. Most paired products or those frequently purchased together
SELECT f1.f_name, f2.f_name, COUNT(*) AS Number_Times_Ordered
FROM order_details o1
JOIN order_details o2
ON o1.order_id = o2.order_id AND o1.f_id < o2.f_id
JOIN food f1
ON f1.f_id = o1.f_id
JOIN food f2
ON f2.f_id = o2.f_id
GROUP BY o1.f_id, o2.f_id
ORDER BY count(*) DESC;

