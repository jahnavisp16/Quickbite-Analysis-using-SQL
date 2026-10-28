-- Create the database  
CREATE DATABASE quickbiteanalysis;
USE quickbiteanalysis;


-- Create Tables & Import Data  
-- Customers
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    signup_date VARCHAR(20),
    customer_segment VARCHAR(30)
);

-- Restaurants
CREATE TABLE IF NOT EXISTS restaurants (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(100),
    city VARCHAR(50),
    cuisine VARCHAR(50),
    rating DECIMAL(3, 2)
);

-- Menu_items
CREATE TABLE IF NOT EXISTS menu_items (
    item_id INT PRIMARY KEY,
    restaurant_id INT,
    item_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2)
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_date VARCHAR(20),
    order_status VARCHAR(30),
    delivery_minutes DECIMAL(5, 2),
    order_amount DECIMAL(10, 2),
    discount DECIMAL(10, 2)
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    payment_method VARCHAR(50),
    payment_status VARCHAR(30),
    payment_date VARCHAR(20)
);

-- Understand the Data
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM restaurants;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM payments;

-- Check Missing Values
-- Check for NULLs in customers
SELECT 
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN customer_name IS NULL OR customer_name='' THEN 1 END) AS missing_name,
  COUNT(CASE WHEN city IS NULL OR city='' THEN 1 END) AS missing_city,
  COUNT(CASE WHEN signup_date IS NULL OR signup_date='' THEN 1 END) AS missing_signup_date,
  COUNT(CASE WHEN customer_segment IS NULL OR customer_segment='' THEN 1 END) AS missing_segment
FROM customers;

-- Menu Items Table
SELECT 
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN item_name IS NULL OR item_name='' THEN 1 END) AS missing_item,
  COUNT(CASE WHEN category IS NULL OR category='' THEN 1 END) AS missing_category,
  COUNT(CASE WHEN price IS NULL OR price='' THEN 1 END) AS missing_price
FROM menu_items;

-- order table
SELECT 
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN order_status IS NULL OR order_status='' THEN 1 END) AS missing_status,
  COUNT(CASE WHEN delivery_minutes IS NULL OR delivery_minutes='' THEN 1 END) AS missing_delivery_time,
  COUNT(CASE WHEN order_amount IS NULL OR order_amount='' THEN 1 END) AS missing_amount,
  COUNT(CASE WHEN discount IS NULL OR discount='' THEN 1 END) AS missing_discount
FROM orders;

-- Payment Table
SELECT 
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN payment_method IS NULL OR payment_method='' THEN 1 END) AS missing_method,
  COUNT(CASE WHEN payment_status IS NULL OR payment_status='' THEN 1 END) AS missing_status,
  COUNT(CASE WHEN payment_date IS NULL OR payment_date='' THEN 1 END) AS missing_date
FROM payments;

-- Restaurants Table
SELECT 
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN restaurant_name IS NULL OR restaurant_name='' THEN 1 END) AS missing_name,
  COUNT(CASE WHEN city IS NULL OR city='' THEN 1 END) AS missing_city,
  COUNT(CASE WHEN cuisine IS NULL OR cuisine='' THEN 1 END) AS missing_cuisine,
  COUNT(CASE WHEN rating IS NULL OR rating='' THEN 1 END) AS missing_rating
FROM restaurants;

-- Check Distinct Values - To spot inconsistencies:
-- Customer segments
SELECT DISTINCT customer_segment FROM customers;

-- Order statuses
SELECT DISTINCT order_status FROM orders;

-- Payment statuses
SELECT DISTINCT payment_status FROM payments;

-- Cuisine types
SELECT DISTINCT cuisine FROM restaurants;

DESCRIBE customers;
DESCRIBE restaurants;
DESCRIBE menu_items;
DESCRIBE orders;
DESCRIBE payments;

-- Data Cleanning
-- Convert signup_date from text to DATE
SET SQL_SAFE_UPDATES = 0;
-- Run your update
UPDATE customers
SET signup_date = STR_TO_DATE(signup_date, '%d-%m-%Y')
WHERE signup_date IS NOT NULL AND signup_date <> '';

-- Re-enable safe update mode (recommended)
SET SQL_SAFE_UPDATES = 1;

-- Fill missing customer_segment with 'Unknown'
UPDATE customers
SET customer_segment = 'Unknown'
WHERE customer_segment IS NULL OR customer_segment = '';

## Orders
-- Normalize order_status values
UPDATE orders
SET order_status = CASE 
  WHEN order_status IN ('Delivered','Cancelled','Pending') THEN order_status
  ELSE 'Unknown' END;

-- Normalize payment_status values
UPDATE payments
SET payment_status = CASE 
  WHEN payment_status IN ('Paid','Pending','Failed') THEN payment_status
  ELSE 'Unknown' END;

-- Clean Resturants
-- Standardize cuisine names (example: trim spaces)
UPDATE restaurants
SET cuisine = TRIM(cuisine);

### Clean Menu Items
-- Remove invalid prices
DELETE FROM menu_items
WHERE price IS NULL OR price <= 0;

-- Standardize category values
UPDATE menu_items
SET category = CASE 
  WHEN category IN ('Main Course','Starter','Beverage','Dessert') THEN category
  ELSE 'Other' END;

## Validation After Cleaning
-- Customers
SELECT DISTINCT customer_segment FROM customers;

-- Orders
SELECT DISTINCT order_status FROM orders;

-- Payments
SELECT DISTINCT payment_status FROM payments;

-- Restaurants
SELECT DISTINCT cuisine FROM restaurants;

-- Menu Items
SELECT DISTINCT category FROM menu_items;

## A. Category Price Distribution
-- 1. Total number of menu items
SELECT * FROM menu_items;
SELECT COUNT(*) AS total_menu_items 
FROM menu_items;

-- 2. Number of items by category
SELECT category, COUNT(*) AS item_count
FROM menu_items
GROUP BY category;

-- 3. Overall average menu item price
SELECT AVG(price) AS overall_avg_price
FROM menu_items;

-- 4. Average price by category
SELECT category, AVG(price) AS avg_price
FROM menu_items
GROUP BY category
ORDER BY avg_price DESC;

-- 5. Minimum and maximum price per category
SELECT category, MIN(price) AS min_price, MAX(price) AS max_price
FROM menu_items
GROUP BY category;

-- 6. Most expensive item on the platform
SELECT item_name, category, price
FROM menu_items
ORDER BY price DESC
LIMIT 1;

-- 7. Most affordable item on the platform
SELECT item_name, category, price
FROM menu_items
ORDER BY price ASC
LIMIT 1;

## B. Cuisine-Level Pricing & Analysis
-- 8. Average menu price by cuisine
SELECT r.cuisine, AVG(m.price) AS avg_cuisine_price
FROM menu_items m 
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
GROUP BY r.cuisine
ORDER BY avg_cuisine_price DESC;

-- 9. Cuisine with highest average price
SELECT r.cuisine, AVG(m.price) AS highest_avg_price
FROM menu_items m 
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
GROUP BY r.cuisine
ORDER BY highest_avg_price DESC
LIMIT 1;

-- 10. Number of items offered per cuisine
SELECT r.cuisine, COUNT(m.item_id) AS total_items
FROM menu_items m 
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
GROUP BY r.cuisine
ORDER BY total_items DESC;

-- 11. Average price by category within each cuisine
SELECT r.cuisine, m.category, AVG(m.price) AS avg_category_price
FROM menu_items m 
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
GROUP BY r.cuisine, m.category
ORDER BY r.cuisine, avg_category_price DESC;

## C. Price Benchmarking & Classification
-- 12. Menu items priced above overall platform average
SELECT item_name, category, price
FROM menu_items
WHERE price > (SELECT AVG(price) FROM menu_items)
ORDER BY price DESC;

-- 13. Menu items priced above their own category average
WITH cat_avg AS (
  SELECT category, AVG(price) AS avg_price
  FROM menu_items
  GROUP BY category
)
SELECT m.item_name, m.category, m.price, c.avg_price AS category_avg
FROM menu_items m 
JOIN cat_avg c ON m.category = c.category
WHERE m.price > c.avg_price
ORDER BY m.category, m.price DESC;

-- 14. Classify menu items into High, Medium, or Low Price Tier
WITH cat_avg AS (
  SELECT category, AVG(price) AS avg_price
  FROM menu_items
  GROUP BY category
)
SELECT m.item_name, m.category, m.price,
       CASE 
         WHEN m.price >= c.avg_price * 1.15 THEN 'High Price'
         WHEN m.price <= c.avg_price * 0.85 THEN 'Low Price'
         ELSE 'Medium Price'
       END AS price_tier
FROM menu_items m 
JOIN cat_avg c ON m.category = c.category;

## D. Underrepresented Category Identification
-- 15. Underrepresented category offerings per cuisine (fewer than 3 items)
SELECT r.cuisine, m.category, COUNT(*) AS item_count
FROM menu_items m 
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
GROUP BY r.cuisine, m.category
HAVING COUNT(*) < 3
ORDER BY item_count ASC, r.cuisine;

-- 16. Categories offered by lowest number of cuisines
SELECT m.category, COUNT(DISTINCT r.cuisine) AS cuisine_count
FROM menu_items m 
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
GROUP BY m.category
ORDER BY cuisine_count ASC;

-- 17. Restaurants offering only one category on their menu
SELECT r.restaurant_name, COUNT(DISTINCT m.category) AS distinct_categories
FROM restaurants r 
JOIN menu_items m ON r.restaurant_id = m.restaurant_id
GROUP BY r.restaurant_name
HAVING COUNT(DISTINCT m.category) = 1;

## E. Advanced Price Ranking & Restaurant Strategy
-- 18. Rank items by price within each cuisine
SELECT r.cuisine, m.item_name, m.category, m.price,
       RANK() OVER (PARTITION BY r.cuisine ORDER BY m.price DESC) AS price_rank
FROM menu_items m 
JOIN restaurants r ON m.restaurant_id = r.restaurant_id;

-- 19. Most expensive item in each cuisine
WITH ranked_items AS (
  SELECT r.cuisine, m.item_name, m.category, m.price,
         ROW_NUMBER() OVER (PARTITION BY r.cuisine ORDER BY m.price DESC) AS rn
  FROM menu_items m 
  JOIN restaurants r ON m.restaurant_id = r.restaurant_id
)
SELECT cuisine, item_name, category, price AS max_price
FROM ranked_items
WHERE rn = 1
ORDER BY max_price DESC;

-- 20. Top restaurants with highest average menu prices
SELECT r.restaurant_name, r.cuisine, AVG(m.price) AS avg_menu_price
FROM restaurants r 
JOIN menu_items m ON r.restaurant_id = m.restaurant_id
GROUP BY r.restaurant_name, r.cuisine
ORDER BY avg_menu_price DESC
LIMIT 5;








