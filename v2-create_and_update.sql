
-- This is based on https://gist.github.com/duffn/38449526e00abb47f4ec292f0491313d#file-creating_a_date_dimension_table_in_postgresql-sql


-- 第一步，创建日期表
DROP TABLE if exists d_date;
CREATE TABLE d_date
(
  id						INT NOT NULL,
  "date"					DATE NOT NULL,
  --formatted_date			VARCHAR(10) NOT NULL,
  --full_date					varchar(20) not null,
 -- day_name					VARCHAR(12) NOT NULL, -- 之前是7位，改为12位，
 -- day_name_short			VARCHAR(3) NOT NULL,
  day_of_week				INT NOT NULL,
  is_weekend				BOOLEAN NOT NULL,  -- 修改位置到前面
  --day_of_month				INT NOT NULL,
  --day_of_quarter			INT NOT NULL,
  --day_of_year				INT NOT NULL,
  --week_of_month				INT NOT NULL,
  week_of_year				INT NOT NULL,
  week_of_year_iso			CHAR(12) NOT NULL,
  "month"					INT NOT NULL,
  month_name_cn				VARCHAR(9) NOT NULL,
  month_name_en				CHAR(5) ,
 -- "quarter"					INT NOT NULL,
 -- quarter_name				CHAR(2) NOT NULL,
  "year"					INT NOT NULL,
 -- year_month				VARCHAR(12) not null,
 -- year_quarter				VARCHAR(12) not null,
  --first_day_of_week			DATE NOT NULL,
  --last_day_of_week			DATE NOT NULL,
  --first_day_of_month		DATE NOT NULL,
  --last_day_of_month			DATE NOT NULL,
  --first_day_of_quarter		DATE NOT NULL,
  --last_day_of_quarter		DATE NOT NULL,
  --first_day_of_year			DATE NOT NULL,
  --last_day_of_year			DATE NOT NULL,
    is_flight_season_interval  BOOLEAN,   -- 三月和十月，每月的最后一个周日，标记为 true 
    flight_season_year		VARCHAR(4) ,
 	flight_season			VARCHAR(4) ,
	is_Chinese_holiday  BOOLEAN, 	 -- 新增，是否中国节假日
	Chinese_holiday  	 CHAR(5) ,-- 新增，是否中国节假日
	is_Chinese_workday BOOLEAN, 	 -- 新增，是否工作日，t 是，包含调休
	factor_workday	INT   -- 加班因子，工资两倍或者三倍
);

ALTER TABLE public.d_date ADD CONSTRAINT pk_d_date PRIMARY KEY (id);
----CREATE INDEX pk_d_date
 -- ON d_date("date");
 
COMMIT;


-- 第二步，插入基础数据，这里只是关于日期本书的自定义属性

INSERT INTO d_date
SELECT TO_CHAR(datum, 'yyyymmdd')::INT AS id,
       datum AS "date",
       --TO_CHAR(datum, 'dd/mm/yyyy') AS formatted_date,   
       --TO_CHAR(datum, 'DD ') || TO_CHAR(datum, 'TMMonth ') || ' ' || TO_CHAR(datum, 'yyyy') AS full_date, -- delete “de”
       --TO_CHAR(datum, 'fmDDth') AS day_suffix,
       --TO_CHAR(datum, 'TMDay')  AS day_name,
       --TO_CHAR(datum, 'TMDy')   AS day_name_short,
       EXTRACT(ISODOW FROM datum) AS day_of_week,  -- Day of week based on ISO 8601 Monday (1) to Sunday (7)
		CASE   WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN  true
           ELSE false
           END AS is_weekend ,
       --EXTRACT(DAY FROM datum) AS day_of_month,
       --datum - DATE_TRUNC('quarter', datum)::DATE + 1 AS day_of_quarter,
       --EXTRACT(DOY FROM datum) AS day_of_year,
       --TO_CHAR(datum, 'W')::INT AS week_of_month,
       EXTRACT(WEEK FROM datum)::INT AS week_of_year,
		EXTRACT(ISOYEAR FROM datum) || TO_CHAR(datum, '"-W"IW-') || EXTRACT(ISODOW FROM datum) AS week_of_year_iso,  -- ISO 8601 week number of year */
       cast(EXTRACT(MONTH FROM datum) as INTEGER)  AS "month",
	  case 
					when EXTRACT(MONTH FROM datum) = 1 then '一月' 
			 		when EXTRACT(MONTH FROM datum) = 2 then '二月' 
					when EXTRACT(MONTH FROM datum) = 3 then '三月' 
					when EXTRACT(MONTH FROM datum) = 4 then '四月' 
					when EXTRACT(MONTH FROM datum) = 5 then '五月' 
					when EXTRACT(MONTH FROM datum) = 6 then '六月' 
					when EXTRACT(MONTH FROM datum) = 7 then '七月' 
			 		when EXTRACT(MONTH FROM datum) = 8 then '八月' 
					when EXTRACT(MONTH FROM datum) = 9 then '九月' 
					when EXTRACT(MONTH FROM datum) = 10 then '十月' 
					when EXTRACT(MONTH FROM datum) = 11 then '十一月' 
					when EXTRACT(MONTH FROM datum) = 12 then '十二月' 
			 END  AS month_name_cn,
       TO_CHAR(datum, 'TMMon') AS month_name_en ,
    /*
       EXTRACT(QUARTER FROM datum) AS quarter,
       CASE
           WHEN EXTRACT(QUARTER FROM datum) = 1 THEN 'Q1'
           WHEN EXTRACT(QUARTER FROM datum) = 2 THEN 'Q2'
           WHEN EXTRACT(QUARTER FROM datum) = 3 THEN 'Q3'
           WHEN EXTRACT(QUARTER FROM datum) = 4 THEN 'Q4'
           END AS quarter_name,*/
       EXTRACT(YEAR FROM datum) AS "year"
      /*  TO_CHAR(datum, 'yyyy-mm') AS year_month,
       EXTRACT(YEAR FROM datum) || '-' || CASE
           WHEN EXTRACT(QUARTER FROM datum) = 1 THEN 'Q1'
           WHEN EXTRACT(QUARTER FROM datum) = 2 THEN 'Q2'
           WHEN EXTRACT(QUARTER FROM datum) = 3 THEN 'Q3'
           WHEN EXTRACT(QUARTER FROM datum) = 4 THEN 'Q4'
           END AS year_quarter
      datum + (1 - EXTRACT(ISODOW FROM datum))::INT AS first_day_of_week,
      datum + (7 - EXTRACT(ISODOW FROM datum))::INT AS last_day_of_week,
       datum + (1 - EXTRACT(DAY FROM datum))::INT AS first_day_of_month,
      DATE_TRUNC('MONTH', datum) + INTERVAL '1 MONTH - 1 day')::DATE AS last_day_of_month,
       DATE_TRUNC('quarter', datum)::DATE AS first_day_of_quarter,
      (DATE_TRUNC('quarter', datum) + INTERVAL '3 MONTH - 1 day')::DATE AS last_day_of_quarter,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-01-01', 'YYYY-MM-DD') AS first_day_of_year,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-12-31', 'YYYY-MM-DD') AS last_day_of_year,
		 */
FROM (SELECT '2010-01-01'::DATE + SEQUENCE.DAY AS datum  -- 原来从时间戳开始  SELECT '1970-01-01'::DATE + SEQUENCE.DAY AS datum
      FROM  GENERATE_SERIES(0, 365*25)  AS  SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

COMMIT;
