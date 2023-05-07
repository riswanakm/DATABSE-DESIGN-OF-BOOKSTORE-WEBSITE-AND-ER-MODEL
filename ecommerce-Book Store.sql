/*Which customer spent the most in the previous quarter??*/

select c.customer_id,
concat(c.first_name, ' ' , c.last_name) as customer_name,
a.purchased
from 
(select customer_id,sum(order_amount) as purchased from orders
where ordered_date between  MAKEDATE(YEAR(CURDATE()), 1) + INTERVAL QUARTER(CURDATE())-2 QUARTER and  
 MAKEDATE(YEAR(CURDATE()), 1) + INTERVAL QUARTER(CURDATE())-1 QUARTER - INTERVAL 1 DAY 
 and order_status='Success'
group by customer_id
order by purchased desc limit 1) a , customers c where a.customer_id=c.customer_id;

/*Create a Procedure to update/insert the discount % to a customer*/

USE BOOK_STORE;
DELIMITER //
CREATE PROCEDURE SET_DISCOUNT()
BEGIN
	update customers
    set promo_code='BESTCUST'
    where customer_id = (select a.customer_id
from 
(select customer_id,sum(order_amount) as purchased from orders
where ordered_date between  MAKEDATE(YEAR(CURDATE()), 1) + INTERVAL QUARTER(CURDATE())-2 QUARTER and  
 MAKEDATE(YEAR(CURDATE()), 1) + INTERVAL QUARTER(CURDATE())-1 QUARTER - INTERVAL 1 DAY 
 and order_status='Success'
group by customer_id
order by purchased desc limit 1) a );
    
END //

DELIMITER ;

 /*Create a Procedure to create a view to show rank according to average rate and amount of sold copies*/
DELIMITER //
CREATE PROCEDURE rate_sold_view()
BEGIN
CREATE OR REPLACE VIEW books_rank AS (
  SELECT
    book_id,
    title,
    rate,
    sold
     FROM (
	SELECT
          books.book_id                   AS id,
          title                        AS title,
          avg(reviews)  AS rate,
          sum(sold)                  AS sold
        FROM books
                  JOIN (SELECT
                  books.book_id,
                  coalesce(sum(order_amount), 0) AS sold
                FROM books
                  LEFT JOIN books_has_orders ON books.book_id= books_has_orders.book_id
                  LEFT JOIN  orders ON books_has_orders.order_id = orders.order_id
                GROUP BY books.book_id) AS s ON s.book_id LIKE books.book_id
                order by rate desc,sold desc) a
 GROUP BY books.book_id,title);
 END //
DELIMITER ;


/*  Find the city where more books are shipped to? */
select location.city from
(SELECT books_has_orders.book_id ,orders.customer_id,count(books_has_orders.book_id) as book_count 
FROM orders INNER JOIN books_has_orders  ON orders.order_id= books_has_orders.order_id
INNER JOIN books ON books_has_orders.book_id=books.book_id
inner join customers  on orders.customer_id=customers.customer_id
where ordered_date between DATE_SUB(curdate(),INTERVAL DAYOFMONTH(curdate())- 1 DAY)  and   LAST_DAY(curdate())
 and order_status='Success'
GROUP BY books_has_orders.book_id ,orders.customer_id
order by book_count limit 1) as a INNER JOIN  customers ON a.customer_id = customers. customer_id 
inner join location on customers.zip=location.zip;

/* Which is the best-selling Genre this month?*/
select genres.name
from 
(select book_id,sum(order_amount) as purchased from
 orders join books_has_orders on orders.order_id=books_has_orders.order_id
where  ordered_date between   DATE_SUB(curdate(),INTERVAL DAYOFMONTH(curdate())- 1 DAY)  and   LAST_DAY(curdate())
 and order_status='Success'
group by book_id
order by purchased desc limit 1) a inner join books on a.book_id= books.book_id
inner join genres on books.genres_id=genres.genres_id;



/* Create a Function to calculate and return the total order amount  */
DROP FUNCTION IF EXISTS calculateTotalOrderAmount;
DELIMITER //
CREATE FUNCTION calculateTotalOrderAmount (orderId int(11))
RETURNS decimal(8,2) DETERMINISTIC
BEGIN
	DECLARE totalAmount decimal(8,2);
	SELECT (SUM(books.price*books_has_orders.quantity) + orders.shipping_amount) INTO totalAmount 
	FROM orders INNER JOIN books_has_orders  ON orders.order_id= books_has_orders.order_id
	INNER JOIN books ON books_has_orders.book_id=books.book_id
    WHERE orders.order_id=orderId
	GROUP BY books_has_orders.order_id,orders.shipping_amount;
	return totalAmount ;
END //
DELIMITER ;

Select calculateTotalOrderAmount (1);

	
