-- ============================================================
-- Author: Kranthi Paul
-- Database: MySQL
-- Schema: analyst_bootcamp (customers, orders, order_items, products)
-- ============================================================


-- ============================================================
-- DATABASE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS analyst_bootcamp;
USE analyst_bootcamp;

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city          VARCHAR(50),
    segment       VARCHAR(50)
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    product_id    INT PRIMARY KEY,
    product_name  VARCHAR(100),
    category      VARCHAR(50),
    unit_price    DECIMAL(10,2)
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    order_id      INT PRIMARY KEY,
    customer_id   INT,
    order_date    DATE,
    total_amount  DECIMAL(10,2)
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
    item_id       INT PRIMARY KEY,
    order_id      INT,
    product_id    INT,
    quantity      INT,
    unit_price    DECIMAL(10,2)
);

-- Insert customers
INSERT INTO customers VALUES
(1, 'Alice Johnson', 'New York', 'Corporate'),
(2, 'Bob Smith',     'Chicago',  'Consumer'),
(3, 'Carol White',   'New York', 'Corporate'),
(4, 'David Brown',   'Houston',  'Consumer'),
(5, 'Emma Davis',    'Chicago',  'Corporate'),
(6, 'Frank Miller',  'New York', 'Consumer'),
(7, 'Grace Wilson',  'Houston',  'Corporate'),
(8, 'Henry Taylor',  'Chicago',  'Consumer');

-- Insert products
INSERT INTO products VALUES
(1, 'Laptop Pro',     'Electronics', 1200.00),
(2, 'Wireless Mouse', 'Electronics',   35.00),
(3, 'Office Chair',   'Furniture',    450.00),
(4, 'Standing Desk',  'Furniture',    850.00),
(5, 'Notebook Pack',  'Stationery',    15.00),
(6, 'Pen Set',        'Stationery',    12.00),
(7, 'Monitor 27"',    'Electronics',  600.00),
(8, 'Desk Lamp',      'Furniture',     75.00);

-- Insert orders
INSERT INTO orders VALUES
(101, 1, '2024-01-05', 2435.00),
(102, 2, '2024-01-08',  450.00),
(103, 3, '2024-01-15', 1200.00),
(104, 1, '2024-01-22',  635.00),
(105, 4, '2024-02-01',  850.00),
(106, 5, '2024-02-10', 1800.00),
(107, 3, '2024-02-14',   87.00),
(108, 6, '2024-02-20',  600.00),
(109, 2, '2024-03-01', 1250.00),
(110, 7, '2024-03-10',   75.00);

-- Insert order items
INSERT INTO order_items VALUES
(1,  101, 1, 1, 1200.00),
(2,  101, 2, 3,   35.00),
(3,  101, 7, 1,  600.00),
(4,  102, 3, 1,  450.00),
(5,  103, 1, 1, 1200.00),
(6,  104, 2, 2,   35.00),
(7,  104, 7, 1,  600.00),
(8,  105, 4, 1,  850.00),
(9,  106, 1, 1, 1200.00),
(10, 106, 7, 1,  600.00),
(11, 107, 5, 3,   15.00),
(12, 107, 6, 2,   12.00),
(13, 108, 7, 1,  600.00),
(14, 109, 1, 1, 1200.00),
(15, 110, 8, 1,   75.00);


-- ============================================================
-- DAY 1: WINDOW FUNCTIONS
-- ROW_NUMBER, RANK, DENSE_RANK, SUM OVER, LAG
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 ROW_NUMBER — Number each rep's sales chronologically
-- ------------------------------------------------------------
SELECT
    rep_name,
    sale_date,
    sale_amount,
    ROW_NUMBER() OVER (
        PARTITION BY rep_name
        ORDER BY sale_date
    ) AS sale_number
FROM sales;

-- ------------------------------------------------------------
-- 1.2 RANK — Rank all sales by amount (highest = rank 1)
-- ------------------------------------------------------------
SELECT
    rep_name,
    sale_amount,
    RANK() OVER (ORDER BY sale_amount DESC) AS sales_rank
FROM sales;

-- ------------------------------------------------------------
-- 1.3 SUM OVER — Company-wide running total by date
-- ------------------------------------------------------------
SELECT
    sale_date,
    rep_name,
    sale_amount,
    SUM(sale_amount) OVER (ORDER BY sale_date) AS running_total
FROM sales;

-- ------------------------------------------------------------
-- 1.4 SUM OVER with PARTITION — Running total per rep
-- ------------------------------------------------------------
SELECT
    sale_date,
    rep_name,
    sale_amount,
    SUM(sale_amount) OVER (
        PARTITION BY rep_name
        ORDER BY sale_date
    ) AS running_total
FROM sales;

-- ------------------------------------------------------------
-- 1.5 LAG — Previous sale per rep + difference
-- ------------------------------------------------------------
SELECT
    rep_name,
    sale_date,
    sale_amount,
    LAG(sale_amount, 1) OVER (
        PARTITION BY rep_name
        ORDER BY sale_date
    ) AS previous_sale,
    sale_amount - LAG(sale_amount, 1) OVER (
        PARTITION BY rep_name
        ORDER BY sale_date
    ) AS difference
FROM sales;

-- ------------------------------------------------------------
-- 1.6 LAG + CASE WHEN — Trend classification (UP/DOWN/FIRST SALE)
-- ------------------------------------------------------------
SELECT
    rep_name,
    sale_date,
    sale_amount,
    LAG(sale_amount, 1) OVER (
        PARTITION BY rep_name
        ORDER BY sale_date
    ) AS previous_sale,
    CASE
        WHEN LAG(sale_amount, 1) OVER (
             PARTITION BY rep_name ORDER BY sale_date) IS NULL
             THEN 'FIRST SALE'
        WHEN sale_amount > LAG(sale_amount, 1) OVER (
             PARTITION BY rep_name ORDER BY sale_date)
             THEN 'UP'
        ELSE 'DOWN'
    END AS trend
FROM sales;

-- ------------------------------------------------------------
-- 1.7 Percentage contribution per rep (no subquery needed)
-- ------------------------------------------------------------
SELECT
    rep_name,
    sale_amount,
    SUM(sale_amount) OVER (PARTITION BY rep_name) AS rep_total,
    ROUND(
        (sale_amount / SUM(sale_amount) OVER (PARTITION BY rep_name)) * 100
    , 2) AS pct_contribution
FROM sales;

-- ------------------------------------------------------------
-- 1.8 Top 2 sales per rep — subquery filter pattern
-- ------------------------------------------------------------
SELECT * FROM (
    SELECT
        rep_name,
        sale_date,
        sale_amount,
        ROW_NUMBER() OVER (
            PARTITION BY rep_name
            ORDER BY sale_amount DESC
        ) AS rn
    FROM sales
) AS ranked
WHERE rn <= 2
ORDER BY rep_name, rn;

-- ------------------------------------------------------------
-- 1.9 Highest sale per region + global rank
-- ------------------------------------------------------------
SELECT * FROM (
    SELECT
        rep_name,
        region,
        sale_amount,
        RANK() OVER (
            PARTITION BY region
            ORDER BY sale_amount DESC
        ) AS region_rank,
        RANK() OVER (
            ORDER BY sale_amount DESC
        ) AS global_rank
    FROM sales
) AS ranked
WHERE region_rank = 1
ORDER BY global_rank;


-- ============================================================
-- DAY 2: CTEs AND SUBQUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 Single CTE — Reps above company average total sales
-- ------------------------------------------------------------
WITH rep_totals AS (
    SELECT
        rep_name,
        SUM(sale_amount) AS total_sales
    FROM sales
    GROUP BY rep_name
),
company_avg AS (
    SELECT ROUND(AVG(total_sales), 2) AS avg_total
    FROM rep_totals
)
SELECT
    r.rep_name,
    r.total_sales,
    c.avg_total,
    r.total_sales - c.avg_total AS gap_above_avg
FROM rep_totals r
CROSS JOIN company_avg c
WHERE r.total_sales > c.avg_total
ORDER BY r.total_sales DESC;

-- ------------------------------------------------------------
-- 2.2 CTE + Window Function — Tier classification
-- ------------------------------------------------------------
WITH rep_totals AS (
    SELECT
        rep_name,
        SUM(sale_amount)                                        AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(sale_amount) DESC)     AS rank_sales
    FROM sales
    GROUP BY rep_name
)
SELECT
    *,
    CASE
        WHEN rank_sales = 1       THEN 'Top Performer'
        WHEN rank_sales IN (2, 3) THEN 'Mid Performer'
        ELSE                           'Needs Improvement'
    END AS tier
FROM rep_totals
ORDER BY rank_sales;

-- ------------------------------------------------------------
-- 2.3 Month-over-Month analysis — Two CTEs + LAG
-- ------------------------------------------------------------
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(sale_date, '%Y-%m')     AS sales_month,
        SUM(sale_amount)                    AS total_sales
    FROM sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
),
mom_analysis AS (
    SELECT
        *,
        LAG(total_sales, 1) OVER (ORDER BY sales_month) AS prev_month
    FROM monthly_sales
)
SELECT
    sales_month,
    total_sales,
    prev_month,
    ROUND((total_sales - prev_month) / prev_month * 100, 2) AS mom_growth_pct,
    CASE
        WHEN prev_month IS NULL            THEN 'N/A'
        WHEN total_sales > prev_month      THEN 'Growth'
        ELSE                                    'Decline'
    END AS trend
FROM mom_analysis
ORDER BY sales_month;

-- ------------------------------------------------------------
-- 2.4 Best and worst month — UNION ALL pattern
-- ------------------------------------------------------------
WITH monthly_totals AS (
    SELECT
        DATE_FORMAT(sale_date, '%Y-%m')     AS sales_month,
        SUM(sale_amount)                    AS total_sales
    FROM sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
),
ranked AS (
    SELECT
        sales_month,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS best_rn,
        ROW_NUMBER() OVER (ORDER BY total_sales ASC)  AS worst_rn
    FROM monthly_totals
)
SELECT sales_month, total_sales, 'Best Month'  AS label FROM ranked WHERE best_rn  = 1
UNION ALL
SELECT sales_month, total_sales, 'Worst Month' AS label FROM ranked WHERE worst_rn = 1;


-- ============================================================
-- DAY 3: ADVANCED JOINS
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 INNER JOIN — Orders with customer names
-- ------------------------------------------------------------
SELECT
    c.customer_name,
    o.order_date,
    o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date;

-- ------------------------------------------------------------
-- 3.2 LEFT JOIN — Find customers who never ordered
-- ------------------------------------------------------------
SELECT
    c.customer_name,
    c.city,
    o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- ------------------------------------------------------------
-- 3.3 SELF JOIN — Customers in the same city
-- ------------------------------------------------------------
SELECT
    c1.customer_name AS customer,
    c2.customer_name AS same_city_customer,
    c1.city
FROM customers c1
JOIN customers c2
    ON  c1.city = c2.city
    AND c1.customer_id <> c2.customer_id;

-- ------------------------------------------------------------
-- 3.4 4-Table JOIN — Full order detail report
-- ------------------------------------------------------------
SELECT
    c.customer_name,
    o.order_date,
    p.product_name,
    oi.quantity,
    oi.quantity * oi.unit_price AS line_total
FROM orders o
JOIN customers   c  ON o.customer_id  = c.customer_id
JOIN order_items oi ON o.order_id     = oi.order_id
JOIN products    p  ON oi.product_id  = p.product_id
ORDER BY o.order_date, c.customer_name;

-- ------------------------------------------------------------
-- 3.5 Revenue by product category (filtered)
-- ------------------------------------------------------------
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)  AS total_revenue,
    SUM(oi.quantity)                             AS total_units_sold,
    ROUND(AVG(oi.unit_price), 2)                AS avg_unit_price
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.category
HAVING SUM(oi.quantity * oi.unit_price) > 500
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------
-- 3.6 Customer value classification — LEFT JOIN + COALESCE
-- ------------------------------------------------------------
SELECT
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    COALESCE(SUM(o.total_amount), 0)        AS total_spent,
    CASE
        WHEN COALESCE(SUM(o.total_amount), 0) > 1500 THEN 'High Value'
        WHEN COALESCE(SUM(o.total_amount), 0) >= 500 THEN 'Medium Value'
        ELSE                                               'Low Value'
    END AS value_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name, c.city
ORDER BY total_spent DESC;

-- ------------------------------------------------------------
-- 3.7 City revenue ranking
-- ------------------------------------------------------------
SELECT
    c.city,
    SUM(o.total_amount)                                     AS total_revenue,
    COUNT(DISTINCT c.customer_id)                           AS unique_customers,
    ROUND(AVG(o.total_amount), 2)                          AS avg_spend_per_order,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC)        AS city_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY city_rank;


-- ============================================================
-- DAY 4: DATE FUNCTIONS AND BUSINESS REPORTING
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 DATE_FORMAT examples
-- ------------------------------------------------------------
SELECT
    order_id,
    order_date,
    DATE_FORMAT(order_date, '%Y-%m')    AS year_month,
    DATE_FORMAT(order_date, '%M %Y')    AS display_month,
    MONTH(order_date)                   AS month_number,
    YEAR(order_date)                    AS year_number,
    DATEDIFF(CURDATE(), order_date)     AS days_since_order
FROM orders
ORDER BY order_date;

-- ------------------------------------------------------------
-- 4.2 Conditional aggregation — High vs Low value orders per month
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(order_date, '%Y-%m')                        AS order_month,
    COUNT(order_id)                                         AS total_orders,
    COUNT(CASE WHEN total_amount > 1000 THEN 1 END)        AS high_value_orders,
    COUNT(CASE WHEN total_amount <= 1000 THEN 1 END)       AS low_value_orders,
    ROUND(SUM(CASE WHEN total_amount > 1000
                   THEN total_amount ELSE 0 END), 2)       AS high_value_revenue
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

-- ------------------------------------------------------------
-- 4.3 Customer activation rate by city
-- ------------------------------------------------------------
WITH activation AS (
    SELECT
        c.city,
        COUNT(DISTINCT c.customer_id)                       AS total_customers,
        COUNT(DISTINCT CASE
            WHEN o.order_id IS NOT NULL
            THEN c.customer_id END)                         AS active_customers
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.city
)
SELECT
    city,
    total_customers,
    active_customers,
    total_customers - active_customers                      AS inactive_customers,
    ROUND(active_customers / total_customers * 100, 1)     AS activation_rate
FROM activation
ORDER BY activation_rate DESC;

-- ------------------------------------------------------------
-- 4.4 Complete Monthly Business Report
--     3 CTEs: monthly_base + best_product + mom_analysis
-- ------------------------------------------------------------
WITH monthly_base AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m')                  AS monthly,
        COUNT(DISTINCT o.order_id)                          AS total_orders,
        SUM(oi.quantity * oi.unit_price)                    AS total_revenue,
        COUNT(DISTINCT o.customer_id)                       AS unique_customers
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
best_product AS (
    SELECT * FROM (
        SELECT
            DATE_FORMAT(o.order_date, '%Y-%m')              AS monthly,
            p.product_name,
            SUM(oi.quantity * oi.unit_price)                AS product_revenue,
            ROW_NUMBER() OVER (
                PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m')
                ORDER BY SUM(oi.quantity * oi.unit_price) DESC
            )                                               AS rn
        FROM orders o
        JOIN order_items oi ON o.order_id  = oi.order_id
        JOIN products    p  ON oi.product_id = p.product_id
        GROUP BY monthly, p.product_name
    ) AS ranked
    WHERE rn = 1
),
mom_analysis AS (
    SELECT
        *,
        LAG(total_revenue, 1) OVER (ORDER BY monthly)      AS prev_month_rev
    FROM monthly_base
)
SELECT
    m.monthly,
    m.total_orders,
    m.total_revenue,
    ROUND(m.total_revenue / m.total_orders, 2)             AS avg_order_value,
    m.unique_customers,
    b.product_name                                          AS best_product,
    ROUND((m.total_revenue - m.prev_month_rev)
          / m.prev_month_rev * 100, 2)                     AS mom_growth_pct,
    SUM(m.total_revenue) OVER (ORDER BY m.monthly)         AS running_total,
    CASE
        WHEN m.prev_month_rev IS NULL                      THEN 'N/A'
        WHEN m.total_revenue > m.prev_month_rev            THEN 'Growth'
        ELSE                                                    'Decline'
    END                                                     AS trend
FROM mom_analysis m
LEFT JOIN best_product b ON m.monthly = b.monthly
ORDER BY m.monthly;


-- ============================================================
-- DAY 5: ADVANCED WINDOW FUNCTIONS + EXISTS VS IN
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 LEAD — Monthly revenue with previous and next month
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m')    AS order_month,
        SUM(total_amount)                   AS total_revenue
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    order_month,
    total_revenue,
    LAG(total_revenue,  1) OVER (ORDER BY order_month) AS prev_month,
    LEAD(total_revenue, 1) OVER (ORDER BY order_month) AS next_month
FROM monthly
ORDER BY order_month;

-- ------------------------------------------------------------
-- 5.2 LEAD — Customer next order analysis
-- ------------------------------------------------------------
WITH order_data AS (
    SELECT
        c.customer_name,
        o.order_date,
        o.total_amount,
        LEAD(o.total_amount, 1) OVER (
            PARTITION BY c.customer_name
            ORDER BY o.order_date
        ) AS next_order_amount
    FROM orders o
    LEFT JOIN customers c ON c.customer_id = o.customer_id
)
SELECT
    *,
    next_order_amount - total_amount AS difference
FROM order_data;

-- ------------------------------------------------------------
-- 5.3 NTILE — Customer quartile segmentation
-- ------------------------------------------------------------
WITH customer_spending AS (
    SELECT
        c.customer_name,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_name
)
SELECT
    customer_name,
    total_spent,
    NTILE(4) OVER (ORDER BY total_spent DESC)           AS quartile,
    CASE NTILE(4) OVER (ORDER BY total_spent DESC)
        WHEN 1 THEN 'Top 25% — VIP'
        WHEN 2 THEN 'Upper Mid 25%'
        WHEN 3 THEN 'Lower Mid 25%'
        WHEN 4 THEN 'Bottom 25%'
    END                                                  AS segment
FROM customer_spending
ORDER BY total_spent DESC;

-- ------------------------------------------------------------
-- 5.4 PERCENT_RANK — Customer percentile position
-- ------------------------------------------------------------
WITH customer_spending AS (
    SELECT
        c.customer_name,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_name
)
SELECT
    customer_name,
    total_spent,
    ROUND(PERCENT_RANK() OVER (
        ORDER BY total_spent DESC
    ) * 100, 1)                                          AS percentile_rank
FROM customer_spending
ORDER BY total_spent DESC;

-- ------------------------------------------------------------
-- 5.5 EXISTS vs IN vs JOIN — Three ways to find customers with orders
-- ------------------------------------------------------------

-- Using IN
SELECT customer_name FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- Using EXISTS (faster on large datasets, NULL safe)
SELECT customer_name FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
);

-- Using JOIN
SELECT DISTINCT c.customer_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;

-- ------------------------------------------------------------
-- 5.6 NOT EXISTS — Find customers who never ordered (NULL safe)
-- ------------------------------------------------------------
SELECT customer_name FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
);


-- ============================================================
-- DAY 6: STRING FUNCTIONS, NULL HANDLING, PIVOT, OPTIMISATION
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 String cleaning — All functions combined
-- ------------------------------------------------------------
SELECT
    LOWER(TRIM(full_name))                              AS clean_name,
    LOWER(email)                                        AS clean_email,
    UPPER(TRIM(city))                                   AS clean_city,
    REPLACE(phone, '-', '')                             AS clean_phone,
    LOWER(SUBSTRING_INDEX(email, '@', -1))              AS domain
FROM messy_data;

-- ------------------------------------------------------------
-- 6.2 NULL handling — COALESCE, NULLIF, IFNULL
-- ------------------------------------------------------------
SELECT
    -- Convert empty string to NULL, then replace NULL with default
    NULLIF(TRIM(full_name), '')                         AS name_nulled,
    COALESCE(NULLIF(TRIM(full_name), ''), 'Unknown')   AS name_clean,
    -- Safe division — prevent division by zero
    total_revenue / NULLIF(total_orders, 0)             AS avg_order_value
FROM messy_data;

-- ------------------------------------------------------------
-- 6.3 PIVOT — Monthly revenue by product category
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m')                  AS order_month,
    SUM(CASE WHEN p.category = 'Electronics'
             THEN oi.quantity * oi.unit_price
             ELSE 0 END)                                AS electronics_revenue,
    SUM(CASE WHEN p.category = 'Furniture'
             THEN oi.quantity * oi.unit_price
             ELSE 0 END)                                AS furniture_revenue,
    SUM(CASE WHEN p.category = 'Stationery'
             THEN oi.quantity * oi.unit_price
             ELSE 0 END)                                AS stationery_revenue,
    SUM(oi.quantity * oi.unit_price)                    AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id    = oi.order_id
JOIN products    p  ON oi.product_id = p.product_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month;

-- ------------------------------------------------------------
-- 6.4 COUNT PIVOT — Customers by segment per city
-- ------------------------------------------------------------
SELECT
    city,
    COUNT(CASE WHEN segment = 'Corporate' THEN 1 END)  AS corporate_customers,
    COUNT(CASE WHEN segment = 'Consumer'  THEN 1 END)  AS consumer_customers,
    COUNT(customer_id)                                  AS total_customers
FROM customers
GROUP BY city;

-- ------------------------------------------------------------
-- 6.5 FULL OUTER JOIN simulation — Unmatched records both sides
-- ------------------------------------------------------------
SELECT c.customer_name, o.order_id,
    CASE
        WHEN o.order_id    IS NULL THEN 'Customer has no order'
        WHEN c.customer_id IS NULL THEN 'Order has no customer'
    END AS status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
UNION
SELECT c.customer_name, o.order_id,
    CASE
        WHEN o.order_id    IS NULL THEN 'Customer has no order'
        WHEN c.customer_id IS NULL THEN 'Order has no customer'
    END AS status
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- ------------------------------------------------------------
-- 6.6 Query optimisation — Create indexes
-- ------------------------------------------------------------
CREATE INDEX idx_customer_id ON orders(customer_id);
CREATE INDEX idx_city         ON customers(city);
CREATE INDEX idx_order_date   ON orders(order_date);

-- Check execution plan
EXPLAIN SELECT * FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.city = 'New York';

-- ============================================================
-- END OF SQL PORTFOLIO
-- ============================================================
