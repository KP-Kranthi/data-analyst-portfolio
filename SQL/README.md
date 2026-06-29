# SQL Portfolio — Data Analyst

A complete collection of SQL queries covering advanced analytics concepts built using MySQL on a real 4-table business schema (customers, orders, order_items, products).

---

## About This Portfolio

This portfolio demonstrates production-level SQL skills across 6 core topic areas. Every query was written to solve a real business problem — not just as a syntax exercise. Each section includes the business context, the query, and the insight it produces.

**Database:** MySQL  
**Schema:** 4-table retail business dataset (customers, orders, order_items, products)  
**Total Queries:** 30+ covering beginner to advanced topics

---

## Skills Demonstrated

| Skill | Topics |
|---|---|
| **Window Functions** | ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, NTILE, PERCENT_RANK, SUM OVER |
| **CTEs** | Single CTEs, chained CTEs, CTEs referencing other CTEs, CROSS JOIN |
| **Subqueries** | Scalar, table, correlated subqueries, EXISTS vs IN vs JOIN |
| **JOINs** | INNER, LEFT, SELF, 4-table chains, WHERE vs ON, FULL OUTER JOIN simulation |
| **Date Functions** | DATE_FORMAT, DATEDIFF, CURDATE, DATE_SUB, period-over-period analysis |
| **Aggregations** | GROUP BY, HAVING, conditional aggregation, PIVOT patterns |
| **String Functions** | TRIM, UPPER, LOWER, REPLACE, CONCAT, SUBSTRING_INDEX, LIKE |
| **NULL Handling** | COALESCE, NULLIF, IFNULL, safe division, empty string conversion |
| **Query Optimisation** | EXPLAIN, indexes, avoiding function-on-column anti-patterns |
| **Business Reporting** | MoM growth, running totals, KPI dashboards, customer segmentation |

---

## Business Schema

```
customers              orders                order_items           products
─────────────          ──────────────         ───────────────       ──────────────
customer_id  ◄──────── customer_id            item_id               product_id
customer_name          order_id    ◄────────── order_id              product_name
city                   order_date              product_id ──────────► product_id
segment                total_amount            quantity              category
                                               unit_price            unit_price
```

---

## Query Highlights

### 1. Complete Monthly Business Report
**3 chained CTEs + 4 tables + window functions + MoM analysis**

Produces a full executive-level monthly report showing total orders, revenue, average order value, unique customers, best-selling product, month-over-month growth %, running total, and trend classification — all in one query.

```sql
WITH monthly_base AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m')      AS monthly,
        COUNT(DISTINCT o.order_id)              AS total_orders,
        SUM(oi.quantity * oi.unit_price)        AS total_revenue,
        COUNT(DISTINCT o.customer_id)           AS unique_customers
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
best_product AS (
    SELECT * FROM (
        SELECT
            DATE_FORMAT(o.order_date, '%Y-%m')  AS monthly,
            p.product_name,
            ROW_NUMBER() OVER (
                PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m')
                ORDER BY SUM(oi.quantity * oi.unit_price) DESC
            ) AS rn
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        GROUP BY monthly, p.product_name
    ) ranked WHERE rn = 1
),
mom_analysis AS (
    SELECT *, LAG(total_revenue, 1) OVER (ORDER BY monthly) AS prev_month_rev
    FROM monthly_base
)
SELECT
    m.monthly, m.total_orders, m.total_revenue,
    ROUND(m.total_revenue / m.total_orders, 2)          AS avg_order_value,
    m.unique_customers,
    b.product_name                                       AS best_product,
    ROUND((m.total_revenue - m.prev_month_rev)
          / m.prev_month_rev * 100, 2)                  AS mom_growth_pct,
    SUM(m.total_revenue) OVER (ORDER BY m.monthly)      AS running_total,
    CASE
        WHEN m.prev_month_rev IS NULL             THEN 'N/A'
        WHEN m.total_revenue > m.prev_month_rev   THEN 'Growth'
        ELSE                                           'Decline'
    END AS trend
FROM mom_analysis m
LEFT JOIN best_product b ON m.monthly = b.monthly
ORDER BY m.monthly;
```

**Business Output:**
```
2024-01  4  4225.00  1056.25  3  Laptop Pro  N/A      4225.00  N/A
2024-02  4  3319.00   829.75  4  Laptop Pro  -21.44   7544.00  Decline
2024-03  2  1275.00   637.50  2  Laptop Pro  -61.58   8819.00  Decline
```

---

### 2. Customer Segmentation — NTILE Quartiles

Automatically divides all customers into spending quartiles for targeted marketing campaigns.

```sql
WITH customer_spending AS (
    SELECT c.customer_name, SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_name
)
SELECT
    customer_name, total_spent,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS quartile,
    CASE NTILE(4) OVER (ORDER BY total_spent DESC)
        WHEN 1 THEN 'Top 25% — VIP'
        WHEN 2 THEN 'Upper Mid 25%'
        WHEN 3 THEN 'Lower Mid 25%'
        WHEN 4 THEN 'Bottom 25%'
    END AS segment
FROM customer_spending
ORDER BY total_spent DESC;
```

---

### 3. PIVOT — Monthly Revenue by Product Category

Turns category rows into columns for executive cross-tab reporting.

```sql
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m')                   AS order_month,
    SUM(CASE WHEN p.category = 'Electronics'
             THEN oi.quantity * oi.unit_price ELSE 0 END) AS electronics,
    SUM(CASE WHEN p.category = 'Furniture'
             THEN oi.quantity * oi.unit_price ELSE 0 END) AS furniture,
    SUM(CASE WHEN p.category = 'Stationery'
             THEN oi.quantity * oi.unit_price ELSE 0 END) AS stationery,
    SUM(oi.quantity * oi.unit_price)                      AS total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month;
```

---

### 4. Data Cleaning Pipeline — String Functions

Standardises messy customer data in a single query.

```sql
SELECT
    LOWER(TRIM(full_name))                       AS clean_name,
    LOWER(email)                                 AS clean_email,
    UPPER(TRIM(city))                            AS clean_city,
    REPLACE(phone, '-', '')                      AS clean_phone,
    LOWER(SUBSTRING_INDEX(email, '@', -1))       AS domain
FROM messy_data;
```

---

## Topics Covered — Full List

### Day 1 — Window Functions
- ROW_NUMBER() — unique sequential numbering per partition
- RANK() vs DENSE_RANK() — tie handling with and without gaps
- SUM() OVER() — running totals company-wide and per group
- LAG() — period-over-period comparison and trend classification
- Top-N per group using subquery filter pattern

### Day 2 — CTEs and Subqueries
- Single and multiple chained CTEs
- CTEs referencing other CTEs
- CROSS JOIN for single-value comparisons
- Month-over-month analysis with two-CTE pattern
- Best/worst month using UNION ALL

### Day 3 — Advanced JOINs
- INNER JOIN across 2 and 4 tables
- LEFT JOIN for missing record detection
- SELF JOIN for same-table comparisons
- WHERE vs ON filtering in LEFT JOINs
- COUNT(DISTINCT) for accurate join counts
- Customer value classification with COALESCE

### Day 4 — Date Functions and Business Reporting
- DATE_FORMAT for sort-safe vs display-safe month formatting
- DATEDIFF and CURDATE for recency analysis
- Conditional aggregation — COUNT and SUM with CASE WHEN
- Customer activation rate analysis
- 3-CTE monthly business report

### Day 5 — Advanced Window Functions and EXISTS
- LEAD() for forward-looking analysis and forecasting
- NTILE() for quartile and decile segmentation
- PERCENT_RANK() for percentile position
- EXISTS vs IN vs JOIN — performance and NULL safety
- NOT EXISTS as the safe alternative to NOT IN

### Day 6 — String Functions, NULL Handling, PIVOT
- TRIM, UPPER, LOWER, REPLACE, CONCAT, SUBSTRING_INDEX
- LIKE pattern matching with case-insensitive approach
- COALESCE, NULLIF, IFNULL — when to use each
- Safe division with NULLIF(denominator, 0)
- PIVOT with conditional aggregation — COUNT and SUM versions
- FULL OUTER JOIN simulation with UNION
- EXPLAIN and index creation for query optimisation

---

## Interview Questions This Portfolio Answers

- Find the top N records per group
- Calculate month-over-month growth percentage
- Find customers who have never placed an order
- Identify the best performing product per month
- Segment customers into quartiles by spending
- Build a cross-tab pivot report without a PIVOT keyword
- Calculate each customer's percentile rank
- Simulate FULL OUTER JOIN in MySQL
- Safely handle division by zero

---

## How to Run

```sql
-- 1. Create the database
CREATE DATABASE analyst_bootcamp;
USE analyst_bootcamp;

-- 2. Run the setup section in complete_sql_portfolio.sql
-- 3. Run any individual query section
```

---

## Connect

- LinkedIn: [Your LinkedIn URL]
- GitHub: [Your GitHub URL]
- Email: [Your Email]
