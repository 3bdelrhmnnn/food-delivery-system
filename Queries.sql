SELECT * FROM customer;
SELECT * FROM Orders;

-- Get the customer with the highest number of orders

SELECT top(1) c.first_name, COUNT(o.customer_id) AS order_count
fROM customer c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name
order by order_count desc
----------------------------------------------
-------------------------------------
-- Get all customers who have never placed an order

SELECT c.first_name, COUNT(o.customer_id) AS order_count
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name
HAVING COUNT(o.customer_id)=0

------------------------------
-----------------------------------
select * from Orders

-- Get the restaurant with the highest number of orders

SELECT TOP 1 r.name, COUNT(o.restaurant_id) AS order_count
FROM restaurant r
INNER JOIN orders o ON r.restaurant_id = o.restaurant_id
GROUP BY  r.name
ORDER BY order_count DESC;

----------------------------------------
-- Get the most ordered food item
select top 1 name ,count(o.food_item_id) as  order_count
from fooditem f inner join orderitem o on f.food_item_id=o.food_item_id
group by f.name
order by  order_count desc


-- Rank restaurants competitively by total revenue

SELECT 
    r.name AS restaurant_name,
    SUM(o.total_amount) AS revenue,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS rank
FROM Orders o
JOIN fooditem fi ON fi.food_item_id IN (
    SELECT food_item_id FROM orderitem WHERE order_id = o.order_id
)
JOIN restaurant r ON r.restaurant_id = fi.restaurant_id
GROUP BY r.restaurant_id, r.name;

--------------------------------
------------------------------------------------------
--------------------views--------------------

CREATE VIEW  vw_OrderDeliveryStatus AS
    select  o.order_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    d.delivery_person_name,
    d.delivery_phone,
    CASE d.status 
        WHEN 0 THEN 'In Progress '
        WHEN 1 THEN 'Delivered '
    END AS delivery_status,
    d.estimated_time,
    o.status AS order_status
FROM Orders o
JOIN customer c ON c.customer_id = o.customer_id
JOIN delivery d ON d.delivery_id = o.delivery_id
WHERE d.status = 0;

select * from vw_OrderDeliveryStatus

CREATE VIEW vw_OrderItems AS
SELECT 
    o.order_id,
    fi.name AS food_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS total_price
FROM orderitem oi
JOIN fooditem fi ON fi.food_item_id = oi.food_item_id
JOIN Orders o ON o.order_id = oi.order_id;

select * from vw_OrderItems

------------summary of orders-----

CREATE VIEW vw_OrderSummary AS
SELECT 
    o.order_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.phone,
    r.name AS restaurant_name,
	oi.unit_price,
	oi.quantity,
	oi.quantity * oi.unit_price AS total_price,
   
    o.order_date,
    CASE o.status
        WHEN 0 THEN 'Pending..... '
        WHEN 1 THEN 'Completed * '
    END AS order_status
FROM Orders o
JOIN customer c ON c.customer_id = o.customer_id
JOIN orderitem oi ON oi.order_id = o.order_id
JOIN fooditem fi ON fi.food_item_id = oi.food_item_id
JOIN restaurant r ON r.restaurant_id = fi.restaurant_id

select * from vw_OrderSummary

-------------payment report

CREATE VIEW vw_PaymentReport AS
	SELECT 
    o.order_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    oi.unit_price,
    oi.quantity,
    oi.unit_price * oi.quantity AS item_total,
    p.payment_method,
    CASE p.payment_status
        WHEN 0 THEN 'Unpaid '
        WHEN 1 THEN 'Paid '
    END AS payment_status,
    p.payment_date
FROM payment p
JOIN Orders o ON o.payment_id = p.payment_id
JOIN customer c ON c.customer_id = o.customer_id
JOIN orderitem oi ON oi.order_id = o.order_id;

select * from vw_PaymentReport

-----------------------------------------------
----------------------------------
----stored procedures----
create proc change_delivery_status  @deli_id int , @t bit
as
update delivery
set status=@t
where delivery_id= @deli_id


change_delivery_status 4,1

--- stored procedures for display all orders of specific customer--------------------

create or alter proc orders_of_customer @id_cu int
AS
SELECT 
    c.first_name + ' ' + c.last_name AS 'customer name',
    c.phone,
    o.order_id,
    o.order_date,
    fo.name AS 'food name',
    orr.quantity,
    orr.unit_price,
    orr.unit_price * orr.quantity AS total_price
FROM customer c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN orderitem orr ON o.order_id = orr.order_id
JOIN fooditem fo ON orr.food_item_id = fo.food_item_id
LEFT JOIN restaurant r ON fo.restaurant_id = r.restaurant_id
WHERE c.customer_id = @id_cu;


orders_of_customer 2

 -----------------------------------------------------------------
-------------------triggers--------------------

    create trigger t1
	on customer
	after insert
	as
	print'welcom to system'

	insert into customer(first_name) values
	('ramadan')
	delete customer where last_name is null
	------------------------------------------------

	CREATE or alter TRIGGER trg_UpdateOrderStatus
ON payment
AFTER UPDATE
AS
   
    IF EXISTS (SELECT 1 FROM INSERTED WHERE payment_status = 1)
    BEGIN
        UPDATE Orders
        SET status = 1
        FROM Orders o
        JOIN INSERTED i ON o.payment_id = i.payment_id
        WHERE i.payment_status = 1
    END

	-------------------------------------------------------
	-------------

	CREATE TRIGGER t2
ON payment
INSTEAD OF DELETE
AS
BEGIN
   
    IF EXISTS (SELECT 1 FROM DELETED WHERE payment_status = 0)
    BEGIN
        DELETE FROM payment
        WHERE payment_id IN (SELECT payment_id FROM DELETED)
    END
    ELSE
    BEGIN
       
        PRINT 'The invoice that has been paid cannot be deleted.'
        ROLLBACK
    END
END

-----------------------------
----------------------------------------

CREATE NONCLUSTERED INDEX IX_fooditem_name
ON fooditem (name);


CREATE UNIQUE NONCLUSTERED INDEX IX_customer_email
ON customer (email);


CREATE NONCLUSTERED INDEX IX_orders_date
ON Orders (order_date);