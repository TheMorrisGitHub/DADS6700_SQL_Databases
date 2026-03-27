-- Homework 4, module 11.

-- PROBLEM 1
-- Chapter 9, Problems and Exercises 9.10E Recursive Query.
-- I will comment this entire query since is related to the book, and not to the classicmodels.sql database.
    /*
    WITH entire-pre-req-courses(coursenr, pre-req-coursenr, level)
    AS
    (SELECT pre.coursenr, pre.pre-req-coursenr, 1
    FROM PRE-REQUISITE pre
    JOIN COURSE c
    ON c.coursenr = pre.coursenr
    WHERE c.coursename = "Principles of Database Management"
    )

    UNION All

    (SELECT entire.coursenr, pre.pre-req-coursenr,  entire.level+1
    FROM entire-pre-req-courses as entire
    JOIN PRE-REQUISITE as pre
    ON  pre.coursenr = entire.pre-req-coursenr
    )

    SELECT * FROM entire-pre-req-courses
    */


-- PROBLEM 2
-- Create a view that returns customer number, customer name, total order value (i.e., dollar amount. Note only to count the shipped orders) for all customers.
-- Then use the view to retrieve the top 5 customers with the highest total order value. Note that you cannot create the view on the server!
-- In order to test the view you created on the server, you may treat the view as a piece of SQL.

-- View to calculate total order value for each customer based on shipped orders
DROP VIEW IF EXISTS problem2_view;
CREATE VIEW problem2_view AS
SELECT c.customerNumber, c.customerName, sum(quantityOrdered * priceEach) AS total_order_value
FROM customers c
join orders
on c.customerNumber = orders.customerNumber
join orderdetails
on orders.orderNumber = orderdetails.orderNumber
WHERE status = 'Shipped'
GROUP BY c.customerNumber, c.customerName;

-- Query to retrieve the top 5 customers with the highest total order value
SELECT *
FROM problem2_view
ORDER BY total_order_value DESC
LIMIT 5;

-- Problem 2. Using the "employees" table create a recursive query to find all subordinates of a given employee.
-- Please refer to the example in Section 9.4 (page 248 of the textbook) for guidance and details. Note that "with subordinates" should be replaced with "with recursive subordinates" in MySQL.
-- The output should contain five columns: "employeeNumber", "lastName", "firstName", "manager", "level".

WITH RECURSIVE subordinates AS (
    SELECT employeeNumber, lastName, firstName, reportsTo AS manager, 1 AS level
    FROM employees
    WHERE reportsTo IS NULL -- Since this is the top of the chain, she doesn't report to anyone.
    UNION ALL
    SELECT e.employeeNumber, e.lastName, e.firstName, e.reportsTo AS manager, s.level + 1
    FROM employees e
    JOIN subordinates s 
    ON e.reportsTo = s.employeeNumber
)

SELECT * FROM subordinates
ORDER BY level, level desc;


-- Problem 3. Create a SQL query that retrieves the productCode and totalProfit of top 5 products with the highest total profit value.
-- For each product, it has buy price (buyPrice in product table) and sell price (priceEach in orderdetails table). Use these two to calculate profit.
-- Sort the results by totalProfit decreasing.

SELECT o.productCode, SUM((o.priceEach - p.buyPrice) * o.quantityOrdered) AS totalProfit
FROM orderdetails o
JOIN products p
ON o.productCode = p.productCode
GROUP BY o.productCode
ORDER BY totalProfit DESC
LIMIT 5;

--Problem 4. Using the database (schema) “classicmodels” on Class Lab Virtual Machine to solve following questions:
--    Create a stored procedure called ‘customers_details’ retrieving customers table.

DROP PROCEDURE IF EXISTS customers_details;
CREATE PROCEDURE customers_details()
BEGIN
    SELECT * FROM customers;
END;

--    Create a stored procedure called ‘In_process_order’ retrieving customerNumber, customerName, phone of the customers with status ‘In_process’ (In Process).

DROP PROCEDURE IF EXISTS In_process_order;
CREATE PROCEDURE In_process_order()
BEGIN
    SELECT c.customerNumber, c.customerName, c.phone
    FROM customers c
    JOIN orders o
    ON c.customerNumber = o.customerNumber
    WHERE o.status = 'In Process';
END;

--    Create a stored procedure called ‘office_insert’ inserting new tuple into office table, providing officeCode and city.
--       This store procedure won't work... offices table have many not null values, and we are not providing those values in the procedure.
DROP PROCEDURE IF EXISTS office_insert;
CREATE PROCEDURE office_insert(IN officeCode VARCHAR(10), IN city VARCHAR(50))
BEGIN
    INSERT INTO offices (officeCode, city) VALUES (officeCode, city);
END;    



