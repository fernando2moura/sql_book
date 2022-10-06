
-- CONVERT TIME ZONE
select '2020-09-01 00:00:00 -0' at time zone 'pst';

-- Brings the first day of the month
select date_trunc('month','2022-10-04 12:40:05'::timestamp); 

select extract('month' from interval '3 months');

select to_char(current_timestamp,'Day');
select to_char(current_timestamp,'Month');
select to_char(current_timestamp,'YYYY');

select DATE_PART('day',current_timestamp);
select DATE_PART('month',current_timestamp);
select DATE_PART('hour',current_timestamp);

select date '2022-09-01' + time '03:00:00' as timestamp;

select make_date(2022,09,24);

SELECT to_date(concat(2020,'-',09,'-',01), 'yyyy-mm-dd');
-- or
SELECT cast(concat(2020,'-',09,'-',01) as date);


SELECT age(date('2020-06-30'), date('2020-01-01')) as days;

SELECT date_part('month',age(date('2020-06-30'), date('2020-01-01'))) as days;

select date('2021-09-19') + interval '370 days' as new_date;

SELECT age(date('2022-09-24'), date('2021-09-19')) as days;

--adding time

select dateadd('month',1,'2022-06-01') as new_date;
-- ==
select date '2022-06-01' + interval '1 month';

select date '2022-06-01' + integer '5';



--DROP table if exists retail_sales;
CREATE table retail_sales
(
sales_month date
,naics_code varchar
,kind_of_business varchar
,reason_for_null varchar
,sales decimal
)
;

-- populate the table with data from the csv file. Download the file locally before completing this step
COPY retail_sales 
FROM '/home/fmoura/Downloads/us_retail_sales.csv' -- change to the location you saved the csv file
DELIMITER ','
CSV HEADER
;

select * from retail_sales rs 

SELECT sales_month 
,sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total'
ORDER BY 1
;

select distinct kind_of_business from retail_sales rs order by 1;

SELECT date_part('year',sales_month) as sales_year
,sum(sales) as sales
FROM retail_sales
WHERE kind_of_business = 'Retail and food services sales, total'
GROUP BY 1
ORDER BY 1
;

-- Comparing components
SELECT date_part('year',sales_month) as sales_year
,kind_of_business
,sum(sales) as sales
FROM retail_sales
WHERE kind_of_business in ('Book stores','Sporting goods stores','Hobby, toy, and game stores')
GROUP BY 1,2
ORDER BY 1,2
;


SELECT sales_month
,kind_of_business
,sales
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
,'Women''s clothing stores')
;

select 
	sales_year
	,womens_sales - mens_sales as womens_minus_mens
	,mens_sales - womens_sales as mens_minus_womens
from
	(
	SELECT 
		date_part('year',sales_month) as sales_year
		,sum(
			case 
				when kind_of_business = 'Women''s clothing stores'
			then sales
		end) as womens_sales
		,sum(
			case 
				when kind_of_business = 'Men''s clothing stores'
			then sales
		end) as mens_sales
	FROM retail_sales
	WHERE kind_of_business in ('Men''s clothing stores'
	,'Women''s clothing stores')
	GROUP BY 1
	order by 1
	) a
	;

-- doing directly

SELECT 
	date_part('year',sales_month) as sales_year
		,sum(
			case 
				when kind_of_business = 'Women''s clothing stores'
			then sales 
		end)
		-
		sum(
			case 
				when kind_of_business = 'Men''s clothing stores'
			then sales 
		end)
	as womens_minus_mens
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
,'Women''s clothing stores')
and sales_month <= '2019-12-01'
GROUP BY 1;


SELECT 
	sales_year
	,round(womens_sales / mens_sales,2) as womens_times_of_mens
FROM
	(
	SELECT 
		date_part('year',sales_month) as sales_year
		,sum(
			case 
				when kind_of_business = 'Women''s clothing stores'
			then sales
		end) as womens_sales
		,sum(
			case 
				when kind_of_business = 'Men''s clothing stores'
			then sales
		end) as mens_sales
	FROM retail_sales
	WHERE kind_of_business in ('Men''s clothing stores'
	,'Women''s clothing stores')
	and sales_month <= '2019-12-01'
	GROUP BY 1
	) a
order by 1
;


SELECT 
	sales_year
	,round((womens_sales / mens_sales -1) * 100,2) as womens_times_of_mens
FROM
	(
	SELECT 
		date_part('year',sales_month) as sales_year
		,sum(
			case 
				when kind_of_business = 'Women''s clothing stores'
			then sales
		end) as womens_sales
		,sum(
			case 
				when kind_of_business = 'Men''s clothing stores'
			then sales
		end) as mens_sales
	FROM retail_sales
	WHERE kind_of_business in ('Men''s clothing stores'
	,'Women''s clothing stores')
	and sales_month <= '2019-12-01'
	GROUP BY 1
	) a
order by 1
;


select 	
	sales_month
	,kind_of_business
	, sales * 100 / total_sales as pct_total_sales
from 
	(
	select
		 a.sales_month
		,a.kind_of_business
		,a.sales
		,sum(b.sales) as total_sales
	from retail_sales a
		join retail_sales b 
			on a.sales_month = b.sales_month 
				and b.kind_of_business in ('Men''s clothing stores'
											,'Women''s clothing stores')
											
	where a.kind_of_business in ('Men''s clothing stores'
									,'Women''s clothing stores')
	group by 1,2,3
	) aa
;
-- other form to do percentual

SELECT 
	sales_month, 
	kind_of_business, 
	sales
	,sum(sales) over (partition by sales_month) as total_sales
	,sales * 100 / sum(sales) over (partition by sales_month) as pct_total
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
								,'Women''s clothing stores')
;



SELECT 
	sales_month
	,kind_of_business
	,sales * 100 / yearly_sales as pct_yearly
FROM
	(
	SELECT 
	a.sales_month, 
	a.kind_of_business, 
	a.sales
	,sum(b.sales) as yearly_sales
	FROM retail_sales a
		JOIN retail_sales b 
			on date_part('year',a.sales_month) = date_part('year',b.sales_month)
				and a.kind_of_business = b.kind_of_business
					and b.kind_of_business in ('Men''s clothing stores'
												,'Women''s clothing stores')
	WHERE a.kind_of_business in ('Men''s clothing stores'
									,'Women''s clothing stores')
	GROUP BY 1,2,3
	) aa
;


SELECT 
	sales_month, 
	kind_of_business, 
	sales
	,sum(sales) over (partition by date_part('year',sales_month)
									,kind_of_business
									) as yearly_sales
	,sales * 100 /
		sum(sales) over (partition by date_part('year',sales_month)
									,kind_of_business
									) as pct_yearly
FROM retail_sales
WHERE kind_of_business in ('Men''s clothing stores'
,'Women''s clothing stores') and date_part('year',sales_month) = 2019
;


select * FROM retail_sales WHERE kind_of_business in ('Men''s clothing stores'
,'Women''s clothing stores');


---------------------
-- USANDO SELF JOIN

select 
	a.sales_month
	,a.sales
	,avg(b.sales) as moving_avg
	,count(b.sales) as records_count
from
	retail_sales a
join retail_sales b 
		on a.kind_of_business = b.kind_of_business
			and b.sales_month between a.sales_month - interval '11 months' and a.sales_month
			and b.kind_of_business = 'Women''s clothing stores'
where
	a.kind_of_business = 'Women''s clothing stores'
	and a.sales_month >= '1993-01-01'
group by 1,2
order by 1
;

-- USANDO FUNÇAO DE JANELA
select
	sales_month
	,sales
	,avg(sales) over ( order by sales_month rows between 2 preceding and current row) as moving_avg
	,avg(sales) over ( order by sales_month rows between 1 preceding and 1 preceding) as previous_value
	,avg(sales) over ( order by sales_month rows between current row and 2 following) as moving_avg_future_1m
	,count(sales) over (order by sales_month rows between 2 preceding and current row) as records_count

from retail_sales
where kind_of_business = 'Women''s clothing stores'
;


--- simulando dados esparsos

drop table if exists public.date_dim;

create table public.date_dim
as
select
	date::date
,
	to_char(date, 'yyyymmdd')::int as date_key
,
	date_part('day', date)::int as day_of_month
,
	date_part('doy', date)::int as day_of_year
,
	date_part('dow', date)::int as day_of_week
,
	trim(to_char(date, 'Day')) as day_name
,
	trim(to_char(date, 'Dy')) as day_short_name
,
	date_part('week', date)::int as week_number
,
	to_char(date, 'W')::int as week_of_month
,
	date_trunc('week', date)::date as week
,
	date_part('month', date)::int as month_number
,
	trim(to_char(date, 'Month')) as month_name
,
	trim(to_char(date, 'Mon')) as month_short_name
,
	date_trunc('month', date)::date as first_day_of_month
,
	(date_trunc('month', date) + interval '1 month' - interval '1 day')::date as last_day_of_month
,
	date_part('quarter', date)::int as quarter_number
,
	trim('Q' || date_part('quarter', date)::int) as quarter_name
,
	date_trunc('quarter', date)::date as first_day_of_quarter
,
	(date_trunc('quarter', date) + interval '3 months' - interval '1 day')::date as last_day_of_quarter
,
	date_part('year', date)::int as year 
,
	date_part('decade', date)::int * 10 as decade
,
	date_part('century', date)::int as centurys
from
	generate_series('1770-01-01'::date, '2030-12-31'::date, '1 day') as date
;

select * from date_dim;


select
	a.date,
	b.sales_month,
	b.sales
from
	date_dim a
join
(
	select
		sales_month,
		sales
	from
		retail_sales
	where
		kind_of_business = 'Women''s clothing stores'
		and date_part('month', sales_month) in (1, 7)
) b on
	b.sales_month between a.date - interval '11 months' and a.date
where
	a.date = a.first_day_of_month
	and a.date between '1993-01-01' and '2020-12-01'
;

-- COM MÉDIA MÓVEL

select
	a.date
	,avg(b.sales) as moving_avg
	,count(b.sales) as records
from
	date_dim a
join
	(
	select
		sales_month,
		sales
	from
		retail_sales
	where
		kind_of_business = 'Women''s clothing stores'
		and date_part('month', sales_month) in (1, 7)
	) b on b.sales_month between a.date - interval '11 months' and a.date
where a.date = a.first_day_of_month
	and a.date between '1993-01-01' and '2020-12-01'
group by 1
;


select
	a.sales_month,
	avg(b.sales) as moving_avg
from
	(
	select
		distinct sales_month
	from
		retail_sales
	where
		sales_month between '1993-01-01' and '2020-12-01'
) a
join retail_sales b 
	on b.sales_month between a.sales_month - interval '11 months' and a.sales_month
		and b.kind_of_business = 'Women''s clothing stores'
group by 1
;

-- YTD
 -- USANDO WINDOW FUNCTIONS
select
	sales_month,
	sales,
	sum(sales) over (partition by date_part('year', sales_month) order by sales_month) as sales_ytd
from retail_sales
where kind_of_business = 'Women''s clothing stores'
;
-- USANDO SELF JOIN
select
	a.sales_month,
	a.sales,
	sum(b.sales) as sales_ytd
from
	retail_sales a
	join retail_sales b on
		date_part('year', a.sales_month) = date_part('year', b.sales_month)
			and b.sales_month <= a.sales_month
			and b.kind_of_business = 'Women''s clothing stores'
where a.kind_of_business = 'Women''s clothing stores'
group by 1,2
;

-- COMPARAÇÃO MoM
select
	kind_of_business,
	sales_month,
	sales,
	lag(sales_month,1) over (partition by kind_of_business order by sales_month) as prev_month,
	lag(sales,1) over (partition by kind_of_business order by sales_month) as prev_month_sales,
	round((sales / lag(sales) over (partition by kind_of_business order by sales_month) - 1) * 100,1) as pct_growth_from_previous
from retail_sales
where kind_of_business = 'Book stores'
;

--YoY - Precisamos agregar antes

select
	sales_year,
	yearly_sales,
	lag(yearly_sales) over (order by sales_year) as prev_year_sales, 
	(yearly_sales / lag(yearly_sales) over (order by sales_year)-1) * 100 as pct_growth_from_previous
from
	(
	select
		date_part('year', sales_month) as sales_year,
		sum(sales) as yearly_sales
	from retail_sales
	where kind_of_business = 'Book stores'
	group by 1
) a
;
-- MESMO YoY usando CTE
with YEAR_AGG as
	(	
	select
		date_part('year', sales_month) as sales_year,
		sum(sales) as yearly_sales
	from retail_sales
	where kind_of_business = 'Book stores'
	group by 1
	)
select
	sales_year,
	yearly_sales,
	lag(yearly_sales) over (order by sales_year) as prev_year_sales, 
	ROUND((yearly_sales / lag(yearly_sales) over (order by sales_year)-1) * 100,1) as pct_growth_from_previous
from YEAR_AGG;

-- Period-over-Period Comparisons: Same Month Versus Last Year

-- SAZONALIDADE DOS MESES

select
	sales_month,
	sales,
	lag(sales_month) over (partition by date_part('month', sales_month) order by sales_month) as prev_year_month,
	lag(sales) over (partition by date_part('month', sales_month) order by sales_month) as prev_year_sales,
	sales - lag(sales) over (partition by date_part('month',sales_month) order by sales_month) as absolute_diff,
	(sales / lag(sales) over (partition by date_part('month',sales_month) order by sales_month)- 1) * 100 as pct_diff
from retail_sales
where kind_of_business = 'Book stores'
;


select
	date_part('month', sales_month) as month_number,
	to_char(sales_month, 'Month') as month_name,
	max(case when date_part('year', sales_month) = 1992 then sales end) as sales_1992,
	max(case when date_part('year', sales_month) = 1993 then sales end) as sales_1993,
	max(case when date_part('year', sales_month) = 1994 then sales end) as sales_1994
from retail_sales
where kind_of_business = 'Book stores'
		and sales_month between '1992-01-01' and '1994-12-01'
group by 1,2
;

-- COMPARANDO COM OS ÚLTIMOS 3 ANOS NO MESMO MES

select
	sales_month,
	sales,
	lag(sales, 1) over (partition by date_part('month', sales_month) order by sales_month) as prev_sales_1,
	lag(sales, 2) over (partition by date_part('month', sales_month) order by sales_month) as prev_sales_2,
	lag(sales, 3) over (partition by date_part('month', sales_month) order by sales_month) as prev_sales_3
from retail_sales
where kind_of_business = 'Book stores'
;

-- COMPARANANDO COM A MÉDIA MÓVEL
select
	sales_month,
	sales,
	sales / ((prev_sales_1 + prev_sales_2 + prev_sales_3) / 3)
as pct_of_3_prev
from
(
select
	sales_month,
	sales,
	lag(sales, 1) over (partition by date_part('month', sales_month) order by sales_month) as prev_sales_1,
	lag(sales, 2) over (partition by date_part('month', sales_month) order by sales_month) as prev_sales_2,
	lag(sales, 3) over (partition by date_part('month', sales_month) order by sales_month) as prev_sales_3
from retail_sales
where kind_of_business = 'Book stores') a
;
-- MESMA COMPARAÇÃO, EXCLUINDO LINHA ATUAL

select
	sales_month,
	sales,
	sales / avg(sales) over (partition by date_part('month', sales_month) order by sales_month rows between 3 preceding and 1 preceding) as pct_of_prev_3
from retail_sales
where kind_of_business = 'Book stores'
;


