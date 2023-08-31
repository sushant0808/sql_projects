
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 


INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--	1. What is the total amount each customer spent on zomato
select userid, sum(price) as total_amount_spent from sales as s
left join product as p
on s.product_id = p.product_id
group by userid order by total_amount_spent desc;

-- 2. How many days has each customer visited zomato?
select userid, COUNT(distinct created_date) as number_of_times_visited from sales 
group by userid


-- 3. What was the first product purchased by each customer
-- Solution 1
select userid, MIN(created_date) from sales group by userid;

-- Solution 2
select * from (select *, rank() over(partition by userid order by created_date) 
as rank_by_date from sales) as finalData where rank_by_date = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers??
select userid, count(product_id) as count_of_most_product_purchased from sales
where product_id = (
	select top 1 product_id
	from sales group by product_id order by count(product_id) desc
) 
group by userid

-- 5. Which item was the most popular for each customer ?


select * from
	(select *, rank() over(partition by userid order by count_of_product desc) as fav_product_rank from 
		(
			select userid, product_id, COUNT(product_id) as count_of_product
			from sales group by userid, product_id
		) as rank_table
	) as finalTable where fav_product_rank = 1

-- 6. Which item was purchased first by the customer after they became a member.
-- Solution 1
select 
s.userid,
min(s.created_date) as newest
from sales as s
inner join goldusers_signup as g
on s.userid = g.userid and s.created_date > g.gold_signup_date group by s.userid;

-- Solution 2
select * from 
(
	select *, rank() over(partition by userid order by created_date) as rank_by_newest_order_date from 
	(
		select s.userid, s.created_date, s.product_id, g.gold_signup_date
		from sales as s inner join goldusers_signup as g
		on s.userid = g.userid and s.created_date > g.gold_signup_date
	) as ranktable
) as finaltable
where rank_by_newest_order_date = 1;


-- 7. Which item was purchased just before the customer became a member??
select * from 
(
	select *, rank() over(partition by userid order by created_date desc) as rank_by_newest_order_date from 
	(
		select s.userid, s.created_date, s.product_id, g.gold_signup_date
		from sales as s inner join goldusers_signup as g
		on s.userid = g.userid and s.created_date <= g.gold_signup_date
	) as ranktable
) as finaltable
where rank_by_newest_order_date = 1;

-- 8. What is the total orders and amount spent for each member before they became a member ??
select 
s.userid,
count(distinct created_date) as total_orders,
sum(p.price) as total_amount_spent
from sales as s
inner join goldusers_signup as g
on s.userid = g.userid and s.created_date <= g.gold_signup_date
inner join product as p
on s.product_id = p.product_id group by s.userid;

--If buying each product generates points for eg: 5rs=2 zomato point and each product has different purchasing 
--points for eg: for p1 5rs=1 zomato point, for p2 10rs=5 zomato points and p3 5rs=1 zomato point

select userid, sum(total_points) from
(
	select data3.*, total_amount/per_product_price as total_points from
	(
		select data2.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end 
		as per_product_price from (
			select userid, product_id, sum(price) as total_amount from
			(
				select s.*, p.price from sales as s inner join product as p on s.product_id = p.product_id
			)as data1 group by userid,product_id
		) as data2
	) as data3
) as data4 group by userid;

select top 1 product_id, sum(total_points) as max_points from
(
	select data3.*, total_amount/per_product_price as total_points from
	(
		select data2.*, case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end 
		as per_product_price from (
			select userid, product_id, sum(price) as total_amount from
			(
				select s.*, p.price from sales as s inner join product as p on s.product_id = p.product_id
			)as data1 group by userid,product_id
		) as data2
	) as data3
) as data4 group by product_id order by max_points desc;

-- Ques

select data1.*, p.price, p.price/2 as total_points from
(
	select s.userid, s.created_date, s.product_id, g.gold_signup_date
	from sales as s inner join goldusers_signup as g
	on s.userid = g.userid and s.created_date > g.gold_signup_date and created_date <= DATEADD(YEAR,1, gold_signup_date)
) as data1 inner join product as p on data1.product_id = p.product_id;

-- Rank all the transactions of the customers
select *, rank() over(partition by userid order by created_date) rank from sales;

-- Rank all the transactions for each member whenever they are a zomato gold member, and mark NA to transaction for
-- non gold member

select *,
case when g.gold_signup_date is null then 'NA'
else str(rank() over(partition by s.userid order by created_date desc)) end as temp
from
sales as s left join goldusers_signup as g on s.userid = g.userid and s.created_date >= g.gold_signup_date;


-- Temp solution
select s.userid, s.created_date, s.product_id, g.gold_signup_date,
case when g.gold_signup_date is null or s.created_date < g.gold_signup_date then 'NA'
else str(rank() over(partition by s.userid order by created_date)) end as temp
from
sales as s left join goldusers_signup as g on s.userid = g.userid;
