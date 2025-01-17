
select * from legislators_terms
where id_bioguide = 'A000118'

-- CAlcular a primeira data de mandato por fulano
-- Basic retention
SELECT id_bioguide
,min(term_start) as first_term
FROM legislators_terms 
GROUP BY 1
;

-- calcula a retenção, mas ainda é imperfeito
SELECT date_part('year',age(b.term_start,a.first_term)) as periods
,count(distinct a.id_bioguide) as cohort_retained
FROM
(
        SELECT id_bioguide
        ,min(term_start) as first_term
        FROM legislators_terms 
        GROUP BY 1
) a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
GROUP BY 1
;

-- cálculo do % de retenção por ano
SELECT period
,first_value(cohort_retained) over (order by period) as cohort_size
,cohort_retained
,cohort_retained * 1.0 / first_value(cohort_retained) over (order by period) as pct_retained
FROM
(
        SELECT date_part('year',age(b.term_start,a.first_term)) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
                SELECT id_bioguide
                ,min(term_start) as first_term
                FROM legislators_terms 
                GROUP BY 1
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
        GROUP BY 1
) aa
;

-- pivotear e mostrar até o ano 4
SELECT cohort_size
,max(case when period = 0 then pct_retained end) as yr0
,max(case when period = 1 then pct_retained end) as yr1
,max(case when period = 2 then pct_retained end) as yr2
,max(case when period = 3 then pct_retained end) as yr3
,max(case when period = 4 then pct_retained end) as yr4
FROM
(
        SELECT period
        ,first_value(cohort_retained) over (order by period) as cohort_size
        ,cohort_retained
        ,cohort_retained * 1.0 / first_value(cohort_retained) over (order by period) as pct_retained
        FROM
        (
                SELECT 
                date_part('year',age(b.term_start,a.first_term)) as period
                ,count(*) as cohort_retained
                FROM
                (
                        SELECT id_bioguide
                        ,min(term_start) as first_term
                        FROM legislators_terms 
                        GROUP BY 1
                ) a
                JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
                GROUP BY 1
        ) aa
) aaa
GROUP BY 1
;

-- Conta quantos anos passaram, com base no dia 31/12
-- Time adjustments
select
	a.id_bioguide,
	a.first_term,
	b.term_start,
	b.term_end,
	c.date,
	date_part('year',
	age(c.date,
	a.first_term)) as period
from
	(
	select
		id_bioguide,
		min(term_start) as first_term
	from
		legislators_terms
	group by
		1
) a
join legislators_terms b on
	a.id_bioguide = b.id_bioguide
left join date_dim c on
	c.date between b.term_start and b.term_end
	and c.month_name = 'December'
	and c.day_of_month = 31
;

-- uma forma de gerar a tabela calendário só com as datas desejadas para o cálculo
select distinct
		MAKE_DATE(date_part('year',term_start)::int,12,31)
from legislators_terms lt 

--- num cenário fazendo com essa data ficaria assim

select
	a.id_bioguide,
	a.first_term,
	b.term_start,
	b.term_end,
	c.date,
	date_part('year',
	age(c.date,
	a.first_term)) as period
from
	(
	select
		id_bioguide,
		min(term_start) as first_term
	from
		legislators_terms
	group by
		1
) a
join legislators_terms b on
	a.id_bioguide = b.id_bioguide
left join (
			select distinct
					MAKE_DATE(date_part('year',term_start)::int,12,31) date
			from legislators_terms) c on
	c.date between b.term_start and b.term_end

;




-- calculo da quantidade de retenção (ou permanÊncia) por ano.
select
	coalesce(date_part('year',
	age(c.date,a.first_term)),0) as period,
	count(distinct a.id_bioguide) as cohort_retained
from
	(
	select
		id_bioguide,
		min(term_start) as first_term
	from legislators_terms
	group by 1
) a
join legislators_terms b on
	a.id_bioguide = b.id_bioguide
left join date_dim c on
	c.date between b.term_start and b.term_end
	and c.month_name = 'December'
	and c.day_of_month = 31
group by 1
;


-- incluir o % de retidos e o geral no denominador desse %
SELECT period
,first_value(cohort_retained) over (order by period) as cohort_size
,cohort_retained
,cohort_retained * 1.0 / 
 first_value(cohort_retained) over (order by period) as pct_retained
FROM
(
        SELECT coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms 
                GROUP BY 1
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
        and c.month_name = 'December' and c.day_of_month = 31
        GROUP BY 1
) aa
;



SELECT 
	a.id_bioguide, 
	a.first_term,
	b.term_start,
	case when b.term_type = 'rep' then b.term_start + interval '2 years'
      when b.term_type = 'sen' then b.term_start + interval '6 years'
      end as term_end
FROM
(
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms 
        GROUP BY 1
) a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
;





SELECT 	
	a.id_bioguide, 
	a.first_term, 
	b.term_start,
	b.term_end term_end_original,
	lead(b.term_start) over (partition by a.id_bioguide order by b.term_start)  - interval '1 day' as term_end
FROM
(
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms 
        GROUP BY 1
) a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
ORDER BY 1,3
;

-- Time-based cohorts derived from the time-series

SELECT 
	date_part('year',a.first_term) as first_year,
	coalesce(date_part('year',age(c.date,a.first_term)),0) as period,
	count(distinct a.id_bioguide) as cohort_retained
FROM
(
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms 
        GROUP BY 1
) a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
LEFT JOIN 
	date_dim c 
		on c.date between b.term_start and b.term_end 
			and c.month_name = 'December' 
			and c.day_of_month = 31
GROUP BY 1,2
;


SELECT 
	first_year,
	period,
	first_value(cohort_retained) over (partition by first_year order by period) as cohort_size,
	cohort_retained,
	round(cohort_retained * 1.0 / first_value(cohort_retained) over (partition by first_year order by period),2) as pct_retained
FROM
(
        SELECT date_part('year',first_term) as first_year
        ,date_part('year',age(b.term_start,a.first_term)) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
                SELECT id_bioguide
                ,min(term_start) as first_term
                FROM legislators_terms 
                GROUP BY 1
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
        GROUP BY 1,2
) aa
;

-- realizar agrupamento por século

SELECT 
	first_century, 
	period,
	first_value(cohort_retained) over (partition by first_century order by period) as cohort_size,
	cohort_retained,
	cohort_retained * 1.0 / first_value(cohort_retained) over (partition by first_century order by period) as pct_retained
FROM
(
        SELECT date_part('century',a.first_term) as first_century
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms 
                GROUP BY 1
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
        and c.month_name = 'December' and c.day_of_month = 31
        GROUP BY 1,2
) aa
ORDER BY 1,2
;

SELECT distinct id_bioguide
,min(term_start) over (partition by id_bioguide) as first_term
,first_value(state) over (partition by id_bioguide order by term_start) as first_state
FROM legislators_terms 
;

SELECT first_state, period
,first_value(cohort_retained) over (partition by first_state order by period) as cohort_size
,cohort_retained
,cohort_retained * 1.0 / 
 first_value(cohort_retained) over (partition by first_state order by period) as pct_retained
FROM
(
        SELECT a.first_state
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
                SELECT distinct id_bioguide
                ,min(term_start) over (partition by id_bioguide) as first_term
                ,first_value(state) over (partition by id_bioguide order by term_start) as first_state
                FROM legislators_terms 
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
        and c.month_name = 'December' and c.day_of_month = 31
        GROUP BY 1,2
) aa
ORDER BY 1,2
;

-- Defining the cohort from a separate table
SELECT d.gender
,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
,count(distinct a.id_bioguide) as cohort_retained
FROM
(
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms 
        GROUP BY 1
) a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
and c.month_name = 'December' and c.day_of_month = 31
JOIN legislators d on a.id_bioguide = d.id_bioguide
GROUP BY 1,2
ORDER BY 2,1
;

SELECT gender, period
,first_value(cohort_retained) over (partition by gender order by period) as cohort_size
,cohort_retained
,cohort_retained * 1.0 / 
 first_value(cohort_retained) over (partition by gender order by period) as pct_retained
FROM
(
        SELECT d.gender
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms 
                GROUP BY 1
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
        and c.month_name = 'December' and c.day_of_month = 31
        JOIN legislators d on a.id_bioguide = d.id_bioguide
        GROUP BY 1,2
) aa
ORDER BY 2,1
;

SELECT gender, period
,first_value(cohort_retained) over (partition by gender order by period) as cohort_size
,cohort_retained
,cohort_retained * 1.0 / 
 first_value(cohort_retained) over (partition by gender order by period) as pct_retained
FROM
(
        SELECT d.gender
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms 
                GROUP BY 1
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
        and c.month_name = 'December' and c.day_of_month = 31
        JOIN legislators d on a.id_bioguide = d.id_bioguide
        WHERE a.first_term between '1917-01-01' and '1999-12-31'
        GROUP BY 1,2
) aa
ORDER BY 2,1
;

----------- Dealing with sparse cohorts
SELECT 
	first_state, 
	gender, 
	period,
	first_value(cohort_retained) over (partition by first_state, gender 
                                    order by period) as cohort_size,
	cohort_retained,
	cohort_retained / 
 		first_value(cohort_retained) over (partition by first_state, gender 
                                    order by period) as pct_retained
FROM
	(
    SELECT 
    	a.first_state, 
    	d.gender,
    	coalesce(date_part('year',age(c.date,a.first_term)),0) as period,
    	count(distinct a.id_bioguide) as cohort_retained
    FROM
    	(
        SELECT distinct 
        	id_bioguide,
        	min(term_start) over (partition by id_bioguide) as first_term,
        	first_value(state) over (partition by id_bioguide 
                                  order by term_start) as first_state
        FROM legislators_terms 
    	) a
    JOIN legislators_terms b 
    	on a.id_bioguide = b.id_bioguide 
    LEFT JOIN date_dim c 
    	on c.date between b.term_start and b.term_end 
    	and c.month_name = 'December' 
    	and c.day_of_month = 31
    JOIN legislators d 
    	on a.id_bioguide = d.id_bioguide
    WHERE a.first_term between '1917-01-01' and '1999-12-31'
    GROUP BY 1,2,3
) aa;


SELECT 
	aa.gender, 
	aa.first_state, 
	cc.period, 
	aa.cohort_size
FROM
	(
    SELECT 
    	b.gender, 
    	a.first_state,
        count(distinct a.id_bioguide) as cohort_size
        FROM 
        	(
             SELECT distinct 
             	id_bioguide,
             	min(term_start) over (partition by id_bioguide) as first_term,
                first_value(state) over (partition by id_bioguide 
                                          order by term_start) as first_state
             FROM legislators_terms 
        ) a
        JOIN legislators b 
        	on a.id_bioguide = b.id_bioguide
        WHERE a.first_term between '1917-01-01' and '1999-12-31' 
        GROUP BY 1,2
	) aa
JOIN
	(
    SELECT generate_series as period 
    FROM generate_series(0,20,1)
	) cc on 1 = 1
order by 2,1,3
;

--- fazendo com cte

with tb_first_values as
	(
	 SELECT distinct 
	 	id_bioguide,
	 	min(term_start) over (partition by id_bioguide) as first_term,
	    first_value(state) over (partition by id_bioguide 
	                              order by term_start) as first_state
	 FROM legislators_terms 
	),
tb_cohorts as
	(
    SELECT 
    	b.gender, 
    	a.first_state,
        count(distinct a.id_bioguide) as cohort_size
    FROM tb_first_values a
    	JOIN legislators b 
        	on a.id_bioguide = b.id_bioguide
    WHERE a.first_term between '1917-01-01' and '1999-12-31' 
    GROUP BY 1,2
    ),
tb_sequence as 
	(
	SELECT generate_series as period 
    FROM generate_series(0,20,1)
	)
SELECT 
	aa.gender, 
	aa.first_state, 
	cc.period, 
	aa.cohort_size
from tb_cohorts aa
	join tb_sequence cc	
		on 1=1
order by 2,1,3


--------------------

SELECT 
	aaa.gender, 
	aaa.first_state, 
	aaa.period, 
	aaa.cohort_size,
	coalesce(ddd.cohort_retained,0) as cohort_retained,
	coalesce(ddd.cohort_retained,0) * 1.0 / aaa.cohort_size as pct_retained
FROM
	(
	SELECT 
		aa.gender, 
		aa.first_state, 
		cc.period, 
		aa.cohort_size
	FROM
		(
        SELECT 
        	b.gender, 
        	a.first_state,
        	count(distinct a.id_bioguide) as cohort_size
        FROM 
        	(
            SELECT distinct 
            	id_bioguide,
            	min(term_start) over (partition by id_bioguide) as first_term,
            	first_value(state) over (partition by id_bioguide 
                                      order by term_start) as first_state
            FROM legislators_terms 
        	) a
        JOIN legislators b 
        	on a.id_bioguide = b.id_bioguide 
        WHERE a.first_term between '1917-01-01' and '1999-12-31' 
        GROUP BY 1,2
		) aa
	JOIN
		(
        SELECT generate_series as period 
        FROM generate_series(0,20,1)
		) cc on 1 = 1
	) aaa
	LEFT JOIN
	(
    SELECT 
    	d.first_state, 
    	g.gender,
    	coalesce(date_part('year',age(f.date,d.first_term)),0) as period,
    	count(distinct d.id_bioguide) as cohort_retained
    FROM
    	(
        SELECT distinct 
        	id_bioguide,
        	min(term_start) over (partition by id_bioguide) as first_term,
        	first_value(state) over (partition by id_bioguide 
                                  order by term_start) as first_state
        FROM legislators_terms 
    	) d
    JOIN legislators_terms e 
    	on d.id_bioguide = e.id_bioguide 
    LEFT JOIN date_dim f 
    	on f.date between e.term_start and e.term_end 
    	and f.month_name = 'December' 
    	and f.day_of_month = 31
    JOIN legislators g 
    	on d.id_bioguide = g.id_bioguide
    WHERE d.first_term between '1917-01-01' and '1999-12-31'
    GROUP BY 1,2,3
	) ddd 
	on aaa.gender = ddd.gender 
		and aaa.first_state = ddd.first_state 
		and aaa.period = ddd.period
ORDER BY 1,2,3;




https://www.youtube.com/watch?v=3USvTRwwAPc
-- mesmo de cima, com agrupamento
SELECT gender, first_state, cohort_size
,max(case when period = 0 then pct_retained end) as yr0
,max(case when period = 2 then pct_retained end) as yr2
,max(case when period = 4 then pct_retained end) as yr4
,max(case when period = 6 then pct_retained end) as yr6
,max(case when period = 8 then pct_retained end) as yr8
,max(case when period = 10 then pct_retained end) as yr10
FROM
(
        SELECT aaa.gender, aaa.first_state, aaa.period, aaa.cohort_size
        ,coalesce(ddd.cohort_retained,0) as cohort_retained
        ,coalesce(ddd.cohort_retained,0) * 1.0 / aaa.cohort_size as pct_retained
        FROM
        (
        SELECT aa.gender, aa.first_state, cc.period, aa.cohort_size
        FROM
        (
                SELECT b.gender, a.first_state
                ,count(distinct a.id_bioguide) as cohort_size
                FROM 
                (
                        SELECT distinct id_bioguide
                        ,min(term_start) over (partition by id_bioguide) as first_term
                        ,first_value(state) over (partition by id_bioguide 
                                                  order by term_start) as first_state
                        FROM legislators_terms 
                ) a
                JOIN legislators b on a.id_bioguide = b.id_bioguide 
                WHERE a.first_term between '1917-01-01' and '1999-12-31' 
                GROUP BY 1,2
        ) aa
        JOIN
        (
                SELECT generate_series as period 
                FROM generate_series(0,20,1)
        ) cc on 1 = 1
        ) aaa
        LEFT JOIN
        (
                SELECT d.first_state, g.gender
                ,coalesce(date_part('year',age(f.date,d.first_term)),0) as period
                ,count(distinct d.id_bioguide) as cohort_retained
                FROM
                (
                        SELECT distinct id_bioguide
                        ,min(term_start) over (partition by id_bioguide) as first_term
                        ,first_value(state) over (partition by id_bioguide 
                                                  order by term_start) as first_state
                        FROM legislators_terms 
                ) d
                JOIN legislators_terms e on d.id_bioguide = e.id_bioguide 
                LEFT JOIN date_dim f on f.date between e.term_start and e.term_end 
                and f.month_name = 'December' and f.day_of_month = 31
                JOIN legislators g on d.id_bioguide = g.id_bioguide
                WHERE d.first_term between '1917-01-01' and '1999-12-31'
                GROUP BY 1,2,3
        ) ddd on aaa.gender = ddd.gender and aaa.first_state = ddd.first_state 
        and aaa.period = ddd.period
) a
GROUP BY 1,2,3
;

----------- Defining cohorts from dates other than the first date ----------------------------------

SELECT distinct 
	id_bioguide, 
	term_type, 
	date('2000-01-01') as first_term,
	min(term_start) as min_start
FROM legislators_terms 
WHERE term_start <= '2000-12-31' and term_end >= '2000-01-01' --- considera se esteve presente em 2000
GROUP BY 1,2,3;


-- Mesmo código de retenção, com critério adicional de join para ter mandatos após data de min_Start ou depois dela e date_dim com datas >= ano 2000

SELECT 
	term_type, 
	period,
	first_value(cohort_retained) over (partition by term_type order by period) as cohort_size,
	cohort_retained,
	cohort_retained * 1.0 / 
 		first_value(cohort_retained) over (partition by term_type order by period) as pct_retained
FROM
	(
    SELECT a.term_type
    ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
    ,count(distinct a.id_bioguide) as cohort_retained
    FROM
	    (
	            SELECT distinct id_bioguide, term_type, date('2000-01-01') as first_term
	            FROM legislators_terms 
	            WHERE term_start <= '2000-12-31' and term_end >= '2000-01-01'
	    ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide --and b.term_start >= a.first_term
        LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
        and c.month_name = 'December' and c.day_of_month = 31 and c.year >= 2000
        GROUP BY 1,2
) aa
;

-- ajustando o mesmo código com lógica de CTE -- testar e ver a diferença entre segmentos de varejo e emp com base na foto de mai/22 -para CP e DDN

with TB_DATA_MIN as
	(
    SELECT distinct 
    	id_bioguide, 
    	term_type, 
    	date('2000-01-01') as first_term
    FROM legislators_terms 
    WHERE term_start <= '2000-12-31' and term_end >= '2000-01-01'
	),
TB_CALC_RETENCAO as 
	(
	SELECT 
		a.term_type,
    	coalesce(date_part('year',age(c.date,a.first_term)),0) as period,
    	count(distinct a.id_bioguide) as cohort_retained
    FROM TB_DATA_MIN a
    JOIN legislators_terms b 
    	on a.id_bioguide = b.id_bioguide --and b.term_start >= a.first_term
    LEFT JOIN date_dim c 
    	on c.date between b.term_start and b.term_end 
        	and c.month_name = 'December' 
        	and c.day_of_month = 31 
        	and c.year >= 2000
        GROUP BY 1,2
	)
SELECT 
	term_type, 
	period,
	first_value(cohort_retained) over (partition by term_type order by period) as cohort_size,
	cohort_retained,
	cohort_retained * 1.0 / 
 		first_value(cohort_retained) over (partition by term_type order by period) as pct_retained
from TB_CALC_RETENCAO




----------- Survivorship ----------------------------------
SELECT 
	id_bioguide
	,min(term_start) as first_term
	,max(term_start) as last_term
FROM legislators_terms
GROUP BY 1;


SELECT id_bioguide
,date_part('century',min(term_start)) as first_century
,min(term_start) as first_term
,max(term_start) as last_term
,date_part('year',age(max(term_start),min(term_start))) as tenure
FROM legislators_terms
GROUP BY 1
;


SELECT 
	first_century
	,count(distinct id_bioguide) as cohort_size
	,count(distinct case when tenure >= 10 then id_bioguide end) as survived_10
	,count(distinct case when tenure >= 10 then id_bioguide end) * 1.0 
 		/ count(distinct id_bioguide) as pct_survived_10
FROM
	(
    SELECT 
    	id_bioguide
    	,date_part('century',min(term_start)) as first_century
    	,min(term_start) as first_term
    	,max(term_start) as last_term
    	,date_part('year',age(max(term_start),min(term_start))) as tenure
    FROM legislators_terms
    GROUP BY 1
	) a
GROUP BY 1
;
-- mesmo acima com CTE
with TB_A as
	(
    SELECT 
    	id_bioguide
    	,date_part('century',min(term_start)) as first_century
    	,min(term_start) as first_term
    	,max(term_start) as last_term
    	,date_part('year',age(max(term_start),min(term_start))) as tenure
    FROM legislators_terms
    GROUP BY 1
    )
SELECT 
	first_century
	,count(distinct id_bioguide) as cohort_size
	,count(distinct case when tenure >= 10 then id_bioguide end) as survived_10
	,count(distinct case when tenure >= 10 then id_bioguide end) * 1.0 
 		/ count(distinct id_bioguide) as pct_survived_10
from TB_A
GROUP BY 1;



SELECT id_bioguide
,date_part('century',min(term_start)) as first_century
,min(term_start) as first_term
,max(term_start) as last_term
,date_part('year',age(max(term_start),min(term_start))) as tenure
FROM legislators_terms
GROUP BY 1
;

-- MANDATOS NÃO NECESSARIAMENTE SÃO CONSEGUCITVOS -- VER QUEM SOBREVIVEU >= 5 MANDATOS
SELECT 
	first_century
	,count(distinct id_bioguide) as cohort_size
	,count(distinct case when total_terms >= 5 then id_bioguide end) as survived_5
	,count(distinct case when total_terms >= 5 then id_bioguide end) * 1.0
 		/ count(distinct id_bioguide) as pct_survived_5_terms
FROM
	(
    SELECT id_bioguide
    ,date_part('century',min(term_start)) as first_century
    ,count(term_start) as total_terms
    FROM legislators_terms
    GROUP BY 1
	) a
GROUP BY 1;


-- verificar de 1 a 20 mandatos utilizando uma série gerada e uma join cartesiana

SELECT 
	a.first_century
	,b.terms
	,count(distinct id_bioguide) as cohort
	,count(distinct case when a.total_terms >= b.terms then id_bioguide end) as cohort_survived
	,count(distinct case when a.total_terms >= b.terms then id_bioguide end) * 1.0 
 		/ count(distinct id_bioguide) as pct_survived
FROM
	(
    SELECT id_bioguide
    ,date_part('century',min(term_start)) as first_century
    ,count(term_start) as total_terms
    FROM legislators_terms
    GROUP BY 1
	) a
JOIN
	(
    SELECT generate_series as terms 
    FROM generate_series(1,20,1)
	) b on 1 = 1
GROUP BY 1,2;

-- utilizando cte


with tb_ids_per_terms_per_centuries as
	(
	SELECT 
		id_bioguide
    	,date_part('century',min(term_start)) as first_century
    	,count(term_start) as total_terms
    FROM legislators_terms
    GROUP BY 1
	),
tb_serie_20 as 
	(
	SELECT 
		generate_series as terms 
    FROM generate_series(1,20,1)
	)
SELECT 
	a.first_century
	,b.terms
	,count(distinct id_bioguide) as cohort
	,count(distinct case when a.total_terms >= b.terms then id_bioguide end) as cohort_survived
	,count(distinct case when a.total_terms >= b.terms then id_bioguide end) * 1.0 
 		/ count(distinct id_bioguide) as pct_survived
 from tb_ids_per_terms_per_centuries a
 	left join tb_serie_20 b	
 		on 1=1
GROUP BY 1,2;



----------- Returnship / repeat purchase behavior ----------------------------------
SELECT 
	date_part('century',a.first_term)::int as cohort_century
	,count(id_bioguide) as reps
FROM
	(
    SELECT 
    	id_bioguide, 
    	min(term_start) as first_term
    FROM legislators_terms
    WHERE term_type = 'rep'
    GROUP BY 1
	) a
GROUP BY 1
order by 1;

-- checar quais reps se tornaram senadores


SELECT 
	aa.cohort_century
	,bb.rep_and_sen * 1.0 / aa.reps as pct_rep_and_sen
FROM
	(
    SELECT 
    	date_part('century',a.first_term) as cohort_century
    	,count(id_bioguide) as reps
    FROM
        	(
            SELECT id_bioguide, min(term_start) as first_term
            FROM legislators_terms
            WHERE term_type = 'rep'
            GROUP BY 1
        	) a
   GROUP BY 1
) aa

LEFT JOIN
	(
     SELECT 
     	date_part('century',b.first_term) as cohort_century
        ,count(distinct b.id_bioguide) as rep_and_sen
     FROM
        (
        SELECT 
        	id_bioguide, 
        	min(term_start) as first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY 1
        ) b
     JOIN legislators_terms c 
     	on b.id_bioguide = c.id_bioguide
        and c.term_type = 'sen' 
        and c.term_start > b.first_term
        GROUP BY 1
) bb on aa.cohort_century = bb.cohort_century
;


--- ajustando em CTE PARA MELHOR ENTENDIMENTO

with TB_REPS as
	(
    SELECT 
    	id_bioguide, 
    	min(term_start) as first_term
    FROM legislators_terms
    WHERE term_type = 'rep'
    GROUP BY 1
	),
TB_CONTAGEM_rEPS as 
	(
	SELECT 
    	date_part('century',a.first_term) as cohort_century
    	,count(id_bioguide) as reps
    from TB_REPS a
   GROUP BY 1
	),
TB_SENS as 
	(
    SELECT 
    	id_bioguide, 
    	min(term_start) as first_term
    FROM legislators_terms
    WHERE term_type = 'rep'
    GROUP BY 1
    ),
TB_CONTAGEM_SENS as
	(
	 SELECT 
     	date_part('century',b.first_term) as cohort_century
        ,count(distinct b.id_bioguide) as rep_and_sen
     from TB_SENS B
          JOIN legislators_terms c 
     	on b.id_bioguide = c.id_bioguide
        and c.term_type = 'sen' 
        and c.term_start > b.first_term
        GROUP BY 1
     )
    
SELECT 
	aa.cohort_century
	,bb.rep_and_sen * 1.0 / aa.reps as pct_rep_and_sen
from TB_CONTAGEM_rEPS AA
	left join TB_CONTAGEM_SENS bb
		on AA.COHORT_CENTURY = BB.COHORT_CENTURY


		
		
		
		
		
SELECT aa.cohort_century
,bb.rep_and_sen * 1.0 / aa.reps as pct_rep_and_sen
FROM
(
        SELECT date_part('century',a.first_term) as cohort_century
        ,count(id_bioguide) as reps
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) a
        WHERE first_term <= '2009-12-31'
        GROUP BY 1
) aa
LEFT JOIN
(
        SELECT date_part('century',b.first_term) as cohort_century
        ,count(distinct b.id_bioguide) as rep_and_sen
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) b
        JOIN legislators_terms c on b.id_bioguide = c.id_bioguide
        and c.term_type = 'sen' and c.term_start > b.first_term
        WHERE age(c.term_start, b.first_term) <= interval '10 years'
        GROUP BY 1
) bb on aa.cohort_century = bb.cohort_century
;


SELECT aa.cohort_century::int as cohort_century
,round(bb.rep_and_sen_5_yrs * 1.0 / aa.reps,4) as pct_5_yrs
,round(bb.rep_and_sen_10_yrs * 1.0 / aa.reps,4) as pct_10_yrs
,round(bb.rep_and_sen_15_yrs * 1.0 / aa.reps,4) as pct_15_yrs
FROM
(
        SELECT date_part('century',a.first_term) as cohort_century
        ,count(id_bioguide) as reps
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) a
        WHERE first_term <= '2009-12-31'
        GROUP BY 1
) aa
LEFT JOIN
(
        SELECT date_part('century',b.first_term) as cohort_century
        ,count(distinct case when age(c.term_start, b.first_term) <= interval '5 years' then b.id_bioguide end) as rep_and_sen_5_yrs
        ,count(distinct case when age(c.term_start, b.first_term) <= interval '10 years' then b.id_bioguide end) as rep_and_sen_10_yrs
        ,count(distinct case when age(c.term_start, b.first_term) <= interval '15 years' then b.id_bioguide end) as rep_and_sen_15_yrs
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) b
        JOIN legislators_terms c on b.id_bioguide = c.id_bioguide
        and c.term_type = 'sen' and c.term_start > b.first_term
        GROUP BY 1
) bb on aa.cohort_century = bb.cohort_century
;

----------- Cumulative calculations ----------------------------------
SELECT date_part('century',a.first_term)::int as century
,first_type
,count(distinct a.id_bioguide) as cohort
,count(b.term_start) as terms
FROM
(
        SELECT distinct id_bioguide
        ,first_value(term_type) over (partition by id_bioguide order by term_start) as first_type
        ,min(term_start) over (partition by id_bioguide) as first_term
        ,min(term_start) over (partition by id_bioguide) + interval '10 years' as first_plus_10
        FROM legislators_terms
) a
LEFT JOIN legislators_terms b on a.id_bioguide = b.id_bioguide and b.term_start between a.first_term and a.first_plus_10
GROUP BY 1,2
;

SELECT century
,max(case when first_type = 'rep' then cohort end) as rep_cohort
,max(case when first_type = 'rep' then terms_per_leg end) as avg_rep_terms
,max(case when first_type = 'sen' then cohort end) as sen_cohort
,max(case when first_type = 'sen' then terms_per_leg end) as avg_sen_terms
FROM
(
        SELECT date_part('century',a.first_term)::int as century
        ,first_type
        ,count(distinct a.id_bioguide) as cohort
        ,count(b.term_start) as terms
        ,count(b.term_start) * 1.0 / count(distinct a.id_bioguide) as terms_per_leg
        FROM
        (
                SELECT distinct id_bioguide
                ,first_value(term_type) over (partition by id_bioguide order by term_start) as first_type
                ,min(term_start) over (partition by id_bioguide) as first_term
                ,min(term_start) over (partition by id_bioguide) + interval '10 years' as first_plus_10
                FROM legislators_terms
        ) a
        LEFT JOIN legislators_terms b on a.id_bioguide = b.id_bioguide and b.term_start between a.first_term and a.first_plus_10
        GROUP BY 1,2
) aa
GROUP BY 1
;

----------- Cross-section analysis, with a cohort lens ----------------------------------
SELECT b.date, count(distinct a.id_bioguide) as legislators
FROM legislators_terms a
JOIN date_dim b on b.date between a.term_start and a.term_end
and b.month_name = 'December' 
and b.day_of_month = 31
and b.year <= 2019
GROUP BY 1
;

SELECT b.date
,date_part('century',first_term)::int as century
,count(distinct a.id_bioguide) as legislators
FROM legislators_terms a
JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
JOIN
(
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms
        GROUP BY 1
) c on a.id_bioguide = c.id_bioguide        
GROUP BY 1,2
;

SELECT date
,century
,legislators
,sum(legislators) over (partition by date) as cohort
,legislators * 100.0 / sum(legislators) over (partition by date) as pct_century
FROM
(
        SELECT b.date
        ,date_part('century',first_term)::int as century
        ,count(distinct a.id_bioguide) as legislators
        FROM legislators_terms a
        JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
        JOIN
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                GROUP BY 1
        ) c on a.id_bioguide = c.id_bioguide        
        GROUP BY 1,2
) a
ORDER BY 1,2
;

SELECT date
,coalesce(sum(case when century = 18 then legislators end) * 100.0 / sum(legislators),0) as pct_18
,coalesce(sum(case when century = 19 then legislators end) * 100.0 / sum(legislators),0) as pct_19
,coalesce(sum(case when century = 20 then legislators end) * 100.0 / sum(legislators),0) as pct_20
,coalesce(sum(case when century = 21 then legislators end) * 100.0 / sum(legislators),0) as pct_21
FROM
(
        SELECT b.date
        ,date_part('century',first_term)::int as century
        ,count(distinct a.id_bioguide) as legislators
        FROM legislators_terms a
        JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
        JOIN
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                GROUP BY 1
        ) c on a.id_bioguide = c.id_bioguide        
        GROUP BY 1,2
) aa
GROUP BY 1
ORDER BY 1
;

SELECT id_bioguide, date
,count(date) over (partition by id_bioguide order by date rows between unbounded preceding and current row) as cume_years
FROM
(
        SELECT distinct a.id_bioguide, b.date
        FROM legislators_terms a
        JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
) a
;

SELECT date, cume_years
,count(distinct id_bioguide) as legislators
FROM
(
    SELECT id_bioguide, date
    ,count(date) over (partition by id_bioguide order by date rows between unbounded preceding and current row) as cume_years
    FROM
    (
        SELECT distinct a.id_bioguide, b.date
        FROM legislators_terms a
        JOIN date_dim b on b.date between a.term_start and a.term_end
        and b.month_name = 'December' and b.day_of_month = 31
        and b.year <= 2019
        GROUP BY 1,2
    ) aa
) aaa
GROUP BY 1,2
;

SELECT date, count(*) as tenures
FROM 
(
        SELECT date, cume_years
        ,count(distinct id_bioguide) as legislators
        FROM
        (
                SELECT id_bioguide, date
                ,count(date) over (partition by id_bioguide order by date rows between unbounded preceding and current row) as cume_years
                FROM
                (
                        SELECT distinct a.id_bioguide, b.date
                        FROM legislators_terms a
                        JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
                        GROUP BY 1,2
                ) aa
        ) aaa
        GROUP BY 1,2
) aaaa
GROUP BY 1
;

SELECT date, tenure
,legislators * 100.0 /
 sum(legislators) over (partition by date) as pct_legislators 
FROM
(
        SELECT date
        ,case when cume_years <= 4 then '1 to 4'
              when cume_years <= 10 then '5 to 10'
              when cume_years <= 20 then '11 to 20'
              else '21+' end as tenure
        ,count(distinct id_bioguide) as legislators
        FROM
        (
                SELECT id_bioguide, date
                ,count(date) over (partition by id_bioguide order by date rows between unbounded preceding and current row) as cume_years
                FROM
                (
                        SELECT distinct a.id_bioguide, b.date
                        FROM legislators_terms a
                        JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
                        GROUP BY 1,2
                ) a
        ) aa
        GROUP BY 1,2
) aaa
;











