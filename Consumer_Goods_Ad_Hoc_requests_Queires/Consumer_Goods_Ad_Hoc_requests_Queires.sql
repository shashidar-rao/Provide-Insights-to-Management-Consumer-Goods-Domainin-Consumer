#1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

 SELECT market
 FROM gdb023.dim_customer
 WHERE customer = 'Atliq Exclusive' AND region = 'APAC'
 GROUP BY market
 
 #2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg

WITH cte1 AS (
			SELECT 
				   COUNT(DISTINCT(product_code)) AS	unique_products_2020
            FROM   gdb023.fact_sales_monthly
            WHERE fiscal_year = 2020 ),
     cte2 AS (
			SELECT 
				   COUNT(DISTINCT(product_code)) AS	unique_products_2021
            FROM   gdb023.fact_sales_monthly
            WHERE fiscal_year = 2021 )
            
    SELECT *,
		   ROUND((( unique_products_2021 - unique_products_2020 ) / unique_products_2020)* 100,2) AS percentage_chg
    FROM cte1,cte2
    
    
    #3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count

SELECT segment,
	   COUNT( DISTINCT(product_code)) AS product_count
FROM   gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC 


#4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference

WITH cte1 AS (
				SELECT  p.segment,
						COUNT(DISTINCT s.product_code) AS product_count_2020
                FROM    gdb023.fact_sales_monthly s 
                JOIN    gdb023.dim_product p 
                ON      p.product_code = s.product_code
                WHERE   s.fiscal_year = 2020
                GROUP BY segment
                ORDER BY product_count_2020 DESC
                ),
      cte2 AS (   
				SELECT  p.segment,
						COUNT(DISTINCT s.product_code) AS product_count_2021
                FROM    gdb023.fact_sales_monthly s 
                JOIN    gdb023.dim_product p 
                ON      p.product_code = s.product_code
                WHERE   s.fiscal_year = 2021
                GROUP BY segment
                ORDER BY product_count_2021 DESC
                )
       
   SELECT  ct2.segment,
           ct1.product_count_2020,
           ct2.product_count_2021,
		  ( ct2.product_count_2021 - ct1.product_count_2020 ) AS difference
   FROM   cte1  ct1 
   JOIN cte2 ct2   
   ON ct1.segment = ct2.segment ;
   
   
   #5. Get the products that have the highest and lowest manufacturing costs.The final output should contain these fields,
product_code
product
manufacturing_cost

SELECT p.product_code,
       p.product,
       ROUND(manufacturing_cost,2) AS manufacturing_cost
FROM  gdb023.dim_product p 
JOIN  gdb023.fact_manufacturing_cost mc 
ON    mc.product_code = p.product_code 
WHERE manufacturing_cost IN ( 
                         (SELECT MAX(manufacturing_cost) FROM gdb023.fact_manufacturing_cost),
                         (SELECT MIN(manufacturing_cost) FROM gdb023.fact_manufacturing_cost) 
                             )
 
 
 #6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage


SELECT c.customer_code,
       c.customer,
       ROUND(AVG(pre.pre_invoice_discount_pct),4) AS average_discount_percentage
FROM   gdb023.dim_customer c 
JOIN   gdb023.fact_pre_invoice_deductions pre 
ON     c.customer_code = pre.customer_code
WHERE  pre.fiscal_year = 2021 AND c.market ='India'
GROUP BY c.customer_code,c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5


# 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.The final report contains these columns:
Month
Year
Gross sales Amount


SELECT MONTH(date) AS Month,
	   YEAR(date) AS Year,
       ROUND(SUM(Sold_quantity * gross_price)/1000000,2) AS Gross_sales_Amount
FROM   gdb023.fact_sales_monthly s 
JOIN   gdb023.fact_gross_price g 
ON     s.fiscal_year = g.fiscal_year AND
       s.product_code = g.product_code
JOIN   gdb023.dim_customer c 
ON     s.customer_code = c.customer_code        
WHERE customer = 'Atliq Exclusive'
GROUP BY Month, Year  
ORDER BY  Year  


# 8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity

  
SELECT get_fiscal_quarter(date) AS Quarter,
       SUM(sold_quantity) AS total_sold_quantity
FROM   gdb023.fact_sales_monthly       
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC

(OR)

SELECT  
        CASE
			WHEN MONTH(date) IN(9,10,11) THEN "Q1"
            WHEN MONTH(date) IN(12,1,2) THEN "Q2"
            WHEN MONTH(date) IN(3,4,5) THEN "Q3"
            ELSE "Q4"
        END AS Quarter,
		SUM(sold_quantity) AS total_sold_quantity
FROM   gdb023.fact_sales_monthly       
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC


# 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage

WITH cte AS ( 
SELECT c.channel,
       ROUND(SUM(s.sold_quantity * g.gross_price)/1000000,2) AS gross_sales_mln,
       ROUND((SUM(s.sold_quantity * g.gross_price)/SUM(SUM(s.sold_quantity * g.gross_price)) OVER())*100,2) As percentage     
FROM  gdb023.fact_sales_monthly s 
JOIN   gdb023.fact_gross_price g 
ON     s.product_code = g.product_code AND
       s.fiscal_year = g.fiscal_year
JOIN   gdb023.dim_customer c 
ON     s.customer_code = c.customer_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel
ORDER BY gross_sales_mln DESC  )

SELECT ct.channel,
	    ct.gross_sales_mln,
		ROUND(SUM(s.sold_quantity * g.gross_price)/SUM(SUM(s.sold_quantity * g.gross_price,2))OVER())*100 AS percentage
FROM   cte ct 
GROUP BY ct.channel 



#10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code

WITH cte1 AS (
				SELECT p.division,
					   p.product_code,
                       P.product,
                       SUM(sold_quantity) AS total_sold_quantity
                 FROM  fact_sales_monthly s 
                 JOIN  dim_product p 
                 ON    p.product_code = p.product_code
                 WHERE fiscal_year = 2021
                 GROUP BY p.product_code , p.product ),
       cte2 AS ( 
			      SELECT *,
                         DENSE_RANK() OVER( PARTITION BY division ORDER BY total_sold_quantity DESC ) AS drnk
                  FROM cte1 )
                  
         SELECT *
         FROM cte2
         WHERE drnk <=3