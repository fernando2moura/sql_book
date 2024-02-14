-- formato de data e timestamp

select
	current_timestamp;

select
	date_trunc('month',
	'2023-12-31 20:56:00'::timestamp)
	-- date_part

select
	date_part('day',
	current_timestamp)
	
	-- extract
	
select
	extract('month'
from
	current_timestamp);

select
	extract('day'
from
	interval '32 days');

-- equivalente ao datefromparts no postgres

select make_date(2023,12,31);

--ou

select cast(concat(2023,'-',12,'-',31) as date);


-- MATEMATICA DAS DATAS

select DATE('2023-12-31') - DATE('2016-03-18') as days;

-- age

select date_part('month', age('2023-12-31','2016-03-18')) + (12 * date_part('years', age('2023-12-31','2016-03-18'))) as months; 

select date_part('years', age('2023-12-31','2016-03-18'));

--ou

select date('2016-03-18') + interval '7 years' as new_date;

-- MATEMATICA DAS HORAS

-- ADICIONANDO INTERVALOS

select TIME '05:00' + interval '3 hours' as new_time;

-- conta com horas

select time '05:00' - time '03:00' as  time_diff;

select time '05:00' * 2 as time_multiplied;

-- intervalo multiplicado

select interval '1 second' * 2000 as interval_multiplied;


------ ANÁLISES - BASE RETAIL


SELECT 
	sales_month,
	sales
FROM RETAIL_SALES
WHERE KIND_OF_BUSINESS = 'Retail and food services sales, total'





