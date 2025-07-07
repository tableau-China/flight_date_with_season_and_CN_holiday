-- 腾讯云版本 
--SHOW search_path;

SET search_path TO xilejun;
-- 第一步，创建日期表

DROP TABLE if exists d_date;
CREATE TABLE xilejun.d_date  -- ERROR: no schema has been selected to create in
(
  id						INT NOT NULL,
  "date"					DATE NOT NULL,
  --formatted_date			VARCHAR(10) NOT NULL,
  --full_date					varchar(20) not null,
  day_of_week				INT NOT NULL,
  is_weekend				BOOLEAN NOT NULL,  -- 修改位置到前面
  --day_of_month				INT NOT NULL,
  --day_of_year				INT NOT NULL,
  --week_of_month				INT NOT NULL,
  --week_of_year				INT NOT NULL,
  week_of_year_iso			CHAR(12) NOT NULL,
  "month"					INT NOT NULL,
  --month_name_cn				VARCHAR(9) NOT NULL,
  --month_name_en				CHAR(5) ,
  "year"					INT NOT NULL
);

ALTER TABLE xilejun.d_date ADD CONSTRAINT pk_d_date PRIMARY KEY (id);
----CREATE INDEX pk_d_date
 -- ON d_date("date");
 
COMMIT;



-- 第二步，插入基础数据，这里只是关于日期本书的自定义属性

INSERT INTO xilejun.d_date
SELECT TO_CHAR(datum, 'yyyymmdd')::INT AS id,
       datum AS "date",
       --TO_CHAR(datum, 'dd/mm/yyyy') AS formatted_date,   
       EXTRACT(ISODOW FROM datum) AS day_of_week,  -- Day of week based on ISO 8601 Monday (1) to Sunday (7)
		CASE   WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN  true
           ELSE false
           END AS is_weekend ,
       --EXTRACT(DAY FROM datum) AS day_of_month,
       --datum - DATE_TRUNC('quarter', datum)::DATE + 1 AS day_of_quarter,
       --EXTRACT(DOY FROM datum) AS day_of_year,
       --TO_CHAR(datum, 'W')::INT AS week_of_month,
       --EXTRACT(WEEK FROM datum)::INT AS week_of_year,
		EXTRACT(ISOYEAR FROM datum) || TO_CHAR(datum, '"-W"IW-') || EXTRACT(ISODOW FROM datum) AS week_of_year_iso,  -- ISO 8601 week number of year */
       cast(EXTRACT(MONTH FROM datum) as INTEGER)  AS "month",
       EXTRACT(YEAR FROM datum) AS "year"
      /* 
      datum + (1 - EXTRACT(ISODOW FROM datum))::INT AS first_day_of_week,
      datum + (7 - EXTRACT(ISODOW FROM datum))::INT AS last_day_of_week,
       datum + (1 - EXTRACT(DAY FROM datum))::INT AS first_day_of_month,
      DATE_TRUNC('MONTH', datum) + INTERVAL '1 MONTH - 1 day')::DATE AS last_day_of_month,
       DATE_TRUNC('quarter', datum)::DATE AS first_day_of_quarter,
      (DATE_TRUNC('quarter', datum) + INTERVAL '3 MONTH - 1 day')::DATE AS last_day_of_quarter,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-01-01', 'YYYY-MM-DD') AS first_day_of_year,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-12-31', 'YYYY-MM-DD') AS last_day_of_year,
		 */
FROM (SELECT '2020-01-01'::DATE + SEQUENCE.DAY AS datum  -- 原来从时间戳开始  SELECT '1970-01-01'::DATE + SEQUENCE.DAY AS datum
      FROM  GENERATE_SERIES(0, 365*25)  AS  SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

COMMIT;



-- ————————


-- 第三步  创建 节假日表

SET search_path TO xilejun;
DROP TABLE if exists  xilejun.d_holiday;
CREATE TABLE xilejun.d_holiday
(
    -- id					INT NOT NULL,
    "date"				DATE NOT NULL  -- 主键
    , Chinese_holiday  	CHAR(10) 		-- 新增，是否中国节假日
	,is_chinese_holiday 	BOOLEAN 	 -- 新增，是否工作日，t 是，包含调休
	--,factor_workday		INT  		 -- 加班因子，工资两倍或者三倍
);

ALTER TABLE xilejun.d_holiday ADD CONSTRAINT pk_holiday_d_date PRIMARY KEY (date);
----CREATE INDEX pk_d_date ON d_date("date");

-- 第四步 解析 json 并写入日期表

WITH cte_Chinese_holidays AS (
SELECT 
    (h.value->>'date')::DATE AS date,
    (h.value->>'holiday')::BOOLEAN AS is_chinese_holiday,
    h.value->>'name' AS chinese_holiday,
    (h.value->>'wage')::INTEGER AS factor_workday
    --(h.value->>'rest')::INTEGER as rest_cnt

 /* from     -- 2025年
  json_each('{
 	"01-01":{"holiday":true,"name":"元旦","wage":3,"date":"2025-01-01","rest":22},
   		"01-26":{"holiday":false,"name":"春节前补班","wage":1,"after":false,"target":"春节","date":"2025-01-26","rest":25},
   		"01-28":{"holiday":true,"name":"除夕","wage":2,"date":"2025-01-28","rest":27},
		"01-29":{"holiday":true,"name":"初一","wage":3,"date":"2025-01-29","rest":1},
		"01-30":{"holiday":true,"name":"初二","wage":3,"date":"2025-01-30","rest":1},"01-31":{"holiday":true,"name":"初三","wage":3,"date":"2025-01-31","rest":1},"02-01":{"holiday":true,"name":"初四","wage":2,"date":"2025-02-01","rest":1},"02-02":{"holiday":true,"name":"初五","wage":2,"date":"2025-02-02","rest":1},"02-03":{"holiday":true,"name":"初六","wage":2,"date":"2025-02-03","rest":1},"02-04":{"holiday":true,"name":"初七","wage":2,"date":"2025-02-04","rest":1},"02-08":{"holiday":false,"name":"春节后补班","wage":1,"target":"春节","after":true,"date":"2025-02-08","rest":4},"04-04":{"holiday":true,"name":"清明节","wage":3,"date":"2025-04-04","rest":20},"04-05":{"holiday":true,"name":"清明节","wage":2,"date":"2025-04-05","rest":1},"04-06":{"holiday":true,"name":"清明节","wage":2,"date":"2025-04-06","rest":1},"04-27":{"holiday":false,"name":"劳动节前补班","wage":1,"target":"劳动节","after":false,"date":"2025-04-27","rest":12},"05-01":{"holiday":true,"name":"劳动节","wage":3,"date":"2025-05-01","rest":16},"05-02":{"holiday":true,"name":"劳动节","wage":2,"date":"2025-05-02","rest":1},"05-03":{"holiday":true,"name":"劳动节","wage":3,"date":"2025-05-03","rest":1},"05-04":{"holiday":true,"name":"劳动节","wage":3,"date":"2025-05-04","rest":1},"05-05":{"holiday":true,"name":"劳动节","wage":3,"date":"2025-05-05","rest":1},"05-31":{"holiday":true,"name":"端午节","wage":3,"date":"2025-05-31","rest":20},"06-01":{"holiday":true,"name":"端午节","wage":2,"date":"2025-06-01","rest":1},"06-02":{"holiday":true,"name":"端午节","wage":2,"date":"2025-06-02","rest":1},"09-28":{"holiday":false,"name":"国庆节前补班","after":false,"wage":1,"target":"国庆节","date":"2025-09-28","rest":58},"10-01":{"holiday":true,"name":"国庆节","wage":3,"date":"2025-10-01","rest":61},"10-02":{"holiday":true,"name":"国庆节","wage":3,"date":"2025-10-02","rest":1},"10-03":{"holiday":true,"name":"国庆节","wage":3,"date":"2025-10-03","rest":1},"10-04":{"holiday":true,"name":"国庆节","wage":2,"date":"2025-10-04","rest":1},"10-05":{"holiday":true,"name":"国庆节","wage":2,"date":"2025-10-05","rest":1},"10-06":{"holiday":true,"name":"中秋节","wage":2,"date":"2025-10-06","rest":1},"10-07":{"holiday":true,"name":"国庆节","wage":2,"date":"2025-10-07","rest":1},"10-08":{"holiday":true,"name":"国庆节","wage":2,"date":"2025-10-08","rest":1},
		"10-11":{"holiday":false,"after":true,"wage":1,"name":"国庆节后补班","target":"国庆节","date":"2025-10-11"}
    }'::json) AS h(key, value)
   )
  */ 
     
FROM    -- 2024年  -- 2023年、2022年、2021年 
    json_each('{

  "01-01":{"holiday":true,"name":"元旦","wage":3,"date":"2024-01-01"},
	"02-04":{"holiday":false,"name":"春节前补班","wage":1,"after":false,"target":"春节","date":"2024-02-04","rest":29},
	"02-10":{"holiday":true,"name":"初一","wage":3,"date":"2024-02-10","rest":35},
	"02-11":{"holiday":true,"name":"初二","wage":3,"date":"2024-02-11"},
	"02-12":{"holiday":true,"name":"初三","wage":3,"date":"2024-02-12","rest":1},
	"02-13":{"holiday":true,"name":"初四","wage":2,"date":"2024-02-13"},
	"02-14":{"holiday":true,"name":"初五","wage":2,"date":"2024-02-14","rest":1},
	"02-15":{"holiday":true,"name":"初六","wage":2,"date":"2024-02-15"},
	"02-16":{"holiday":true,"name":"初七","wage":2,"date":"2024-02-16"},
	"02-17":{"holiday":true,"name":"初八","wage":2,"date":"2024-02-17","rest":1},
	"02-18":{"holiday":false,"name":"春节后补班","wage":1,"after":true,"target":"春节","date":"2024-02-18"},
	"04-04":{"holiday":true,"name":"清明节","wage":3,"date":"2024-04-04","rest":3},
"04-05":{"holiday":true,"name":"清明节","wage":2,"date":"2024-04-05","rest":1},
"04-06":{"holiday":true,"name":"清明节","wage":2,"date":"2024-04-06"},
"04-07":{"holiday":false,"name":"清明节后补班","wage":1,"target":"清明节","after":true,"date":"2024-04-07"},
"04-28":{"holiday":false,"name":"劳动节前补班","wage":1,"target":"劳动节","after":false,"date":"2024-04-28","rest":8},
"05-01":{"holiday":true,"name":"劳动节","wage":3,"date":"2024-05-01","rest":11},
"05-02":{"holiday":true,"name":"劳动节","wage":2,"date":"2024-05-02","rest":1},
"05-03":{"holiday":true,"name":"劳动节","wage":3,"date":"2024-05-03"},
"05-04":{"holiday":true,"name":"劳动节","wage":3,"date":"2024-05-04"},
"05-05":{"holiday":true,"name":"劳动节","wage":3,"date":"2024-05-05"},
"05-11":{"holiday":false,"name":"劳动节后补班","after":true,"wage":1,"target":"劳动节","date":"2024-05-11"},
"06-08":{"holiday":true,"name":"端午节","wage":2,"date":"2024-06-08","rest":25},
"06-09":{"holiday":true,"name":"端午节","wage":2,"date":"2024-06-09","rest":1},
"06-10":{"holiday":true,"name":"端午节","wage":3,"date":"2024-06-10","rest":1},
"09-14":{"holiday":false,"name":"中秋节前补班","after":false,"wage":1,"target":"中秋节","date":"2024-09-14","rest":40},
"09-15":{"holiday":true,"name":"中秋节","wage":2,"date":"2024-09-15","rest":41},
"09-16":{"holiday":true,"name":"中秋节","wage":2,"date":"2024-09-16","rest":1},
"09-17":{"holiday":true,"name":"中秋节","wage":3,"date":"2024-09-17","rest":1},
"09-29":{"holiday":false,"name":"国庆节前补班","after":false,"wage":1,"target":"国庆节","date":"2024-09-29","rest":3},
"10-01":{"holiday":true,"name":"国庆节","wage":3,"date":"2024-10-01","rest":5},
"10-02":{"holiday":true,"name":"国庆节","wage":3,"date":"2024-10-02","rest":1},
"10-03":{"holiday":true,"name":"国庆节","wage":3,"date":"2024-10-03"},
"10-04":{"holiday":true,"name":"国庆节","wage":2,"date":"2024-10-04"},
"10-05":{"holiday":true,"name":"国庆节","wage":2,"date":"2024-10-05","rest":1},
"10-06":{"holiday":true,"name":"国庆节","wage":2,"date":"2024-10-06","rest":1},
"10-07":{"holiday":true,"name":"国庆节","wage":2,"date":"2024-10-07","rest":1},
"10-12":{"holiday":false,"after":true,"wage":1,"name":"国庆节后补班","target":"国庆节","date":"2024-10-12","rest":4}
    
	,
	"01-01":{"holiday":true,"name":"元旦","wage":3,"date":"2023-01-01"},
	"01-02":{"holiday":true,"name":"元旦","wage":2,"date":"2023-01-02","rest":1},
	"01-21":{"holiday":true,"name":"除夕","wage":3,"date":"2023-01-21"},
	"01-22":{"holiday":true,"name":"初一","wage":3,"date":"2023-01-22"},"01-23":{"holiday":true,"name":"初二","wage":3,"date":"2023-01-23"},"01-24":{"holiday":true,"name":"初三","wage":3,"date":"2023-01-24"},"01-25":{"holiday":true,"name":"初四","wage":2,"date":"2023-01-25"},
	"01-26":{"holiday":true,"name":"初五","wage":2,"date":"2023-01-26"},
	"01-27":{"holiday":true,"name":"初六","wage":2,"date":"2023-01-27"},
	"01-28":{"holiday":false,"name":"春节后补班","wage":1,"after":true,"target":"春节","date":"2023-01-28"},
	"01-29":{"holiday":false,"name":"春节后补班","wage":1,"after":true,"target":"春节","date":"2023-01-29",
	"rest":1},"04-05":{"holiday":true,"name":"清明节","wage":3,"date":"2023-04-05","rest":63},
	"04-23":{"holiday":false,"name":"劳动节前补班","wage":1,"target":"劳动节","after":false,"date":"2023-04-23"},"04-29":{"holiday":true,"name":"劳动节","wage":2,"date":"2023-04-29","rest":1},"04-30":{"holiday":true,"name":"劳动节","wage":2,"date":"2023-04-30"},"05-01":{"holiday":true,"name":"劳动节","wage":3,"date":"2023-05-01"},"05-02":{"holiday":true,"name":"劳动节","wage":3,"date":"2023-05-02","rest":1},"05-03":{"holiday":true,"name":"劳动节","wage":3,"date":"2023-05-03"},"05-06":{"holiday":false,"name":"劳动节后补班","after":true,"wage":1,"target":"劳动节","date":"2023-05-06"},"06-22":{"holiday":true,"name":"端午节","wage":3,"date":"2023-06-22","rest":21},"06-23":{"holiday":true,"name":"端午节","wage":3,"date":"2023-06-23"},"06-24":{"holiday":true,"name":"端午节","wage":2,"date":"2023-06-24"},"06-25":{"holiday":false,"name":"端午节后补班","wage":1,"target":"端午节","after":true,"date":"2023-06-25"},"09-29":{"holiday":true,"name":"中秋节","wage":3,"date":"2023-09-29","rest":90},"09-30":{"holiday":true,"name":"中秋节","wage":3,"date":"2023-09-30"},"10-01":{"holiday":true,"name":"国庆节","wage":3,"date":"2023-10-01"},"10-02":{"holiday":true,"name":"国庆节","wage":3,"date":"2023-10-02","rest":1},"10-03":{"holiday":true,"name":"国庆节","wage":2,"date":"2023-10-03"},"10-04":{"holiday":true,"name":"国庆节","wage":2,"date":"2023-10-04"},"10-05":{"holiday":true,"name":"国庆节","wage":2,"date":"2023-10-05"},"10-06":{"holiday":true,"name":"国庆节","wage":2,"date":"2023-10-06"},"10-07":{"holiday":false,"after":true,"wage":1,"name":"国庆节后补班","target":"国庆节","date":"2023-10-07"},"10-08":{"holiday":false,"after":true,"wage":1,"name":"国庆节后补班","target":"国庆节","date":"2023-10-08"},
	"12-30":{"holiday":true,"name":"元旦","wage":2,"date":"2023-12-30","rest":29},
	"12-31":{"holiday":true,"name":"元旦","wage":2,"date":"2023-12-31"}

	,
	"01-01":{"holiday":true,"name":"元旦","wage":3,"date":"2022-01-01","rest":31}, 
	"01-02":{"holiday":true,"name":"元旦","wage":2,"date":"2022-01-02","rest":1},"01-03":{"holiday":true,"name":"元旦","wage":2,"date":"2022-01-03"},"01-29":{"holiday":false,"name":"春节前补班","after":false,"wage":1,"target":"春节","date":"2022-01-29"},"01-30":{"holiday":false,"name":"春节前补班","after":false,"wage":1,"target":"春节","date":"2022-01-30"},"01-31":{"holiday":true,"name":"除夕","wage":2,"date":"2022-01-31"},"02-01":{"holiday":true,"name":"初一","wage":3,"date":"2022-02-01"},"02-02":{"holiday":true,"name":"初二","wage":3,"date":"2022-02-02","rest":1},"02-03":{"holiday":true,"name":"初三","wage":3,"date":"2022-02-03"},"02-04":{"holiday":true,"name":"初四","wage":2,"date":"2022-02-04"},"02-05":{"holiday":true,"name":"初五","wage":2,"date":"2022-02-05"},"02-06":{"holiday":true,"name":"初六","wage":2,"date":"2022-02-06"},"04-02":{"holiday":false,"name":"清明节前补班","after":false,"wage":1,"target":"清明节","date":"2022-04-02","rest":32},"04-03":{"holiday":true,"name":"清明节","wage":2,"date":"2022-04-03","rest":33},"04-04":{"holiday":true,"name":"清明节","wage":2,"date":"2022-04-04"},"04-05":{"holiday":true,"name":"清明节","wage":3,"date":"2022-04-05"},"04-24":{"holiday":false,"name":"劳动节前补班","after":false,"wage":1,"target":"劳动节","date":"2022-04-24"},"04-30":{"holiday":true,"name":"劳动节","wage":2,"date":"2022-04-30"},"05-01":{"holiday":true,"name":"劳动节","wage":3,"date":"2022-05-01"},"05-02":{"holiday":true,"name":"劳动节","wage":2,"date":"2022-05-02","rest":1},"05-03":{"holiday":true,"name":"劳动节","wage":2,"date":"2022-05-03"},"05-04":{"holiday":true,"name":"劳动节","wage":2,"date":"2022-05-04"},"05-07":{"holiday":false,"name":"劳动节后补班","after":true,"wage":1,"target":"劳动节","date":"2022-05-07"},"06-03":{"holiday":true,"name":"端午节","wage":3,"date":"2022-06-03","rest":2},"06-04":{"holiday":true,"name":"端午节","wage":2,"date":"2022-06-04"},"06-05":{"holiday":true,"name":"端午节","wage":2,"date":"2022-06-05"},"09-10":{"holiday":true,"name":"中秋节","wage":3,"date":"2022-09-10","rest":9},"09-11":{"holiday":true,"name":"中秋节","wage":2,"date":"2022-09-11"},"09-12":{"holiday":true,"name":"中秋节","wage":2,"date":"2022-09-12"},"10-01":{"holiday":true,"name":"国庆节","wage":3,"date":"2022-10-01"},"10-02":{"holiday":true,"name":"国庆节","wage":3,"date":"2022-10-02","rest":1},"10-03":{"holiday":true,"name":"国庆节","wage":3,"date":"2022-10-03"},"10-04":{"holiday":true,"name":"国庆节","wage":2,"date":"2022-10-04"},"10-05":{"holiday":true,"name":"国庆节","wage":2,"date":"2022-10-05"},"10-06":{"holiday":true,"name":"国庆节","wage":2,"date":"2022-10-06"},"10-07":{"holiday":true,"name":"国庆节","wage":2,"date":"2022-10-07"},"10-08":{"holiday":false,"after":true,"wage":1,"name":"国庆节后补班","target":"国庆节","date":"2022-10-08"},
	"10-09":{"holiday":false,"after":true,"wage":1,"name":"国庆节后补班","target":"国庆节","date":"2022-10-09"},
	"12-31":{"holiday":true,"name":"元旦","wage":2,"date":"2022-12-31","rest":60}
			
,
	"01-01":{"holiday":true,"name":"元旦","wage":3,"date":"2021-01-01","rest":31},
	"01-02":{"holiday":true,"name":"元旦","wage":2,"date":"2021-01-02","rest":1},"01-03":{"holiday":true,"name":"元旦","wage":2,"date":"2021-01-03"},"02-07":{"holiday":false,"name":"春节前补班","after":false,"wage":1,"target":"春节","date":"2021-02-07","rest":6},"02-11":{"holiday":true,"name":"除夕","wage":2,"date":"2021-02-11","rest":10},"02-12":{"holiday":true,"name":"初一","wage":3,"date":"2021-02-12"},"02-13":{"holiday":true,"name":"初二","wage":3,"date":"2021-02-13"},"02-14":{"holiday":true,"name":"初三","wage":3,"date":"2021-02-14"},"02-15":{"holiday":true,"name":"初四","wage":2,"date":"2021-02-15"},"02-16":{"holiday":true,"name":"初五","wage":2,"date":"2021-02-16"},"02-17":{"holiday":true,"name":"初六","wage":2,"date":"2021-02-17"},"02-20":{"holiday":false,"name":"春节后补班","after":true,"wage":1,"target":"春节","date":"2021-02-20"},"04-03":{"holiday":true,"name":"清明节","wage":2,"date":"2021-04-03","rest":2},"04-04":{"holiday":true,"name":"清明节","wage":3,"date":"2021-04-04"},"04-05":{"holiday":true,"name":"清明节","wage":2,"date":"2021-04-05"},"04-25":{"holiday":false,"name":"劳动节前补班","after":false,"wage":1,"target":"劳动节","date":"2021-04-25"},"05-01":{"holiday":true,"name":"劳动节","wage":3,"date":"2021-05-01"},"05-02":{"holiday":true,"name":"劳动节","wage":2,"date":"2021-05-02","rest":1},"05-03":{"holiday":true,"name":"劳动节","wage":2,"date":"2021-05-03"},"05-04":{"holiday":true,"name":"劳动节","wage":2,"date":"2021-05-04"},"05-05":{"holiday":true,"name":"劳动节","wage":2,"date":"2021-05-05"},"05-08":{"holiday":false,"name":"劳动节后补班","after":true,"wage":1,"target":"劳动节","date":"2021-05-08"},"06-12":{"holiday":true,"name":"端午节","wage":2,"date":"2021-06-12","rest":11},"06-13":{"holiday":true,"name":"端午节","wage":2,"date":"2021-06-13"},"06-14":{"holiday":true,"name":"端午节","wage":3,"date":"2021-06-14"},"09-18":{"holiday":false,"after":false,"name":"中秋节前补班","wage":1,"target":"中秋节","date":"2021-09-18","rest":79},"09-19":{"holiday":true,"name":"中秋节","wage":2,"date":"2021-09-19","rest":80},"09-20":{"holiday":true,"name":"中秋节","wage":2,"date":"2021-09-20"},"09-21":{"holiday":true,"name":"中秋节","wage":3,"date":"2021-09-21"},"09-26":{"holiday":false,"after":false,"name":"国庆节前补班","wage":1,"target":"国庆节","date":"2021-09-26"},"10-01":{"holiday":true,"name":"国庆节","wage":3,"date":"2021-10-01"},"10-02":{"holiday":true,"name":"国庆节","wage":3,"date":"2021-10-02","rest":1},"10-03":{"holiday":true,"name":"国庆节","wage":3,"date":"2021-10-03"},"10-04":{"holiday":true,"name":"国庆节","wage":2,"date":"2021-10-04"},"10-05":{"holiday":true,"name":"国庆节","wage":2,"date":"2021-10-05"},"10-06":{"holiday":true,"name":"国庆节","wage":2,"date":"2021-10-06"},
	"10-07":{"holiday":true,"name":"国庆节","wage":2,"date":"2021-10-07"},
	"10-09":{"holiday":false,"name":"国庆节后补班","after":true,"wage":1,"target":"国庆节","date":"2021-10-09"}

    }'::json) AS h(key, value)
   )

   
    -- 解析 JSON 数据并插入到临时表中，2024年 
insert   into d_holiday  (date,is_chinese_workday,chinese_holiday)
select  
    hol.date,
	hol.is_chinese_holiday, 	 -- chinese_holiday, factor_workday)(h.value->>'holiday')::BOOLEAN  , 
	hol.chinese_holiday 	 	 -- h.value->>'name' ,
	--hol.factor_workday 			 -- (h.value->>'wage')::INTEGER
FROM 
    cte_Chinese_holidays hol
    
    
  -- 第五步， 使用 view 查询航季信息(夏季分割点)
    select 
    	dd.date,
    	dd.day_of_week,
    	make_date(dd.year,3,31)   ,
    	extract(isodow from make_date(dd.year,3,31)  )  as isodow_,
    	make_date(dd.year,3,31)  - ((extract(isodow from make_date(dd.year, 3, 31))::int+1)%7)  as last_Sat_Mar
    from xilejun.d_date dd 
    where  dd.year >= 2018 and dd.month =3  
    	  and dd.date  in ('2018-03-31','2019-03-31','2020-03-31','2021-03-31','2022-03-31','2023-03-31','2024-03-31','2025-03-31')
    	  
      -- 第五步 -2 ， 使用 view 查询航季信息,增加夏季和秋季航季节点并判断
    select 
    	dd.date,
    	dd.day_of_week,
    	make_date(dd.year,3,31)  as Summer_indicator  ,
    	extract(isodow from make_date(dd.year,3,31)  )  as isodow_0331,
    	make_date(dd.year,3,31)  - ((extract(isodow from make_date(dd.year, 3, 31))::int+1)%7)  as last_Sat_Mar,
    	
    	make_date(dd.year,10,30) as  winter_indicator ,
    	extract(isodow from make_date(dd.year,10,30)  )  as isodow_1030,
    	make_date(dd.year,10,30)  - ((extract(isodow from make_date(dd.year, 10,30))::int+1)%7)  as last_Sat_Oct
    from xilejun.d_date dd 
    where  dd.year >= 2018 and dd.month =3  
    	 -- and dd.date  in ('2018-03-31','2019-03-31','2020-03-31','2021-03-31','2022-03-31','2023-03-31','2024-03-31','2025-03-31',	'2026-03-31','2027-03-31','2028-03-31','2029-03-31'
    	 -- , '2018-10-30','2019-10-30','2020-10-30','2021-10-30','2022-10-30','2023-10-30','2024-10-30','2025-10-30'	,	'2026-10-30','2027-10-30','2028-10-30','2029-10-30'
    	  --		)
    	  		
    -- 第六步 基于上述逻辑，构建 view 
 
    --error 	  		      
    select 
    	dd.date,
    	dd.day_of_week,
    	make_date(dd.year,3,31)   ,
    	extract(isodow from make_date(dd.year,3,31)  )  as isodow_0331,
    	make_date(dd.year,3,31)  - ((extract(isodow from make_date(dd.year, 3, 31))::int+1)%7)  as last_Sat_Mar,
    	make_date(dd.year,10,30)   ,
    	extract(isodow from make_date(dd.year,10,30)  )  as isodow_1030,
    	make_date(dd.year,10,30)  - ((extract(isodow from make_date(dd.year, 10,30))::int+1)%7)  as last_Sat_Oct,
    	case when dd.date >=last_Sat_Mar and dd.date < last_Sat_Oct then 'Summer' else  'winter' end  season
    from xilejun.d_date dd 
    where  dd.year >= 2018 and dd.month =3  
    	  --and dd.date  in ('2018-03-31','2019-03-31','2020-03-31','2021-03-31','2022-03-31','2023-03-31','2024-03-31','2025-03-31',	'2026-03-31','2027-03-31','2028-03-31','2029-03-31'
    	  --, '2018-10-30','2019-10-30','2020-10-30','2021-10-30','2022-10-30','2023-10-30','2024-10-30','2025-10-30'	,	'2026-10-30','2027-10-30','2028-10-30','2029-10-30'
    	  --		)
    
    --CTE 
    with season as (	  		      
    select 
    	dd.date,
    	dd.day_of_week,
    	dd.year,
    	make_date(dd.year,3,31)   ,
    	extract(isodow from make_date(dd.year,3,31)  )  as isodow_0331,
    	make_date(dd.year,3,31)  - ((extract(isodow from make_date(dd.year, 3, 31))::int+1)%7)  as last_Sat_Mar,
    	make_date(dd.year,10,30)   ,
    	extract(isodow from make_date(dd.year,10,30)  )  as isodow_1030,
    	make_date(dd.year,10,30)  - ((extract(isodow from make_date(dd.year, 10,30))::int+1)%7)  as last_Sat_Oct
    from xilejun.d_date dd 
    where  dd.year >= 2020  
    	 )
   select 
   		season.date,
   		season.day_of_week,
   		season.last_Sat_Oct,
   		case when season.date >=last_Sat_Mar and season.date < last_Sat_Oct then 'Summer' else  'Winter' end  flight_season,
   		case when season.date <last_Sat_Mar  then season."year" -1  else season."year" end  flight_season_year
   		-- case when season.date >=last_Sat_Mar and season.date < last_Sat_Oct then  season."year" else extract(YEAR from season.last_Sat_Oct)  end  flight_season_year
   	from season 
   	
--    	第七，合并日期、航季和节假日数据，构建 view 
   		--指定 schema= xilejun
CREATE OR REPLACE VIEW xilejun.v_flight_date as (
    --CTE 
    with season as (	  		      
    select 
    	dd.date,
    	dd.day_of_week,
    	dd.year,
    	make_date(dd.year,3,31)   ,
    	extract(isodow from make_date(dd.year,3,31)  )  as isodow_0331,
    	make_date(dd.year,3,31)  - ((extract(isodow from make_date(dd.year, 3, 31))::int+1)%7)  as last_Sat_Mar,
    	make_date(dd.year,10,30)   ,
    	extract(isodow from make_date(dd.year,10,30)  )  as isodow_1030,
    	make_date(dd.year,10,30)  - ((extract(isodow from make_date(dd.year, 10,30))::int+1)%7)  as last_Sat_Oct
    from xilejun.d_date dd 
    where  dd.year >= 2021  and   dd.year <= extract(year from current_date )-- 2021年之后，到今天年度才有 holiday 信息  
    	 )
   select 
   		season.date,
   		season.day_of_week,
   		season.last_Sat_Oct,
   		case when season.date >=last_Sat_Mar and season.date < last_Sat_Oct then 'Summer' else  'Winter' end  flight_season,
   		case when season.date <last_Sat_Mar  then season."year" -1  else season."year" end  flight_season_year
   		-- case when season.date >=last_Sat_Mar and season.date < last_Sat_Oct then  season."year" else extract(YEAR from season.last_Sat_Oct)  end  flight_season_year
   		,d_holiday.chinese_holiday
   		,d_holiday.is_chinese_holiday
   		from season 
   		left join xilejun.d_holiday on season.date = d_holiday.date
    )
    
   -- 验证逻辑视图的查询效率，非常慢 17秒报错。
    select * from xilejun.v_flight_date
    
   -- 第八步，创建物化视图
        --第七，合并日期、航季和节假日数据，构建 view 
   		--指定 schema= xilejun
CREATE  MATERIALIZED VIEW xilejun.mv_flight_date as (
    --CTE 
    with season as (	  		      
    select 
    	dd.date,
    	dd.day_of_week,
    	dd.year,
    	make_date(dd.year,3,31)   ,
    	extract(isodow from make_date(dd.year,3,31)  )  as isodow_0331,
    	make_date(dd.year,3,31)  - ((extract(isodow from make_date(dd.year, 3, 31))::int+1)%7)  as last_Sat_Mar,
    	make_date(dd.year,10,30)   ,
    	extract(isodow from make_date(dd.year,10,30)  )  as isodow_1030,
    	make_date(dd.year,10,30)  - ((extract(isodow from make_date(dd.year, 10,30))::int+1)%7)  as last_Sat_Oct
    from xilejun.d_date dd 
    where  dd.year >= 2021  and   dd.year <= extract(year from current_date )-- 2021年之后，到今天年度才有 holiday 信息  
    	 )
   select 
   		season.date,
   		season.day_of_week,
   		season.last_Sat_Oct,
   		case when season.date >=last_Sat_Mar and season.date < last_Sat_Oct then 'Summer' else  'Winter' end  flight_season,
   		case when season.date <last_Sat_Mar  then season."year" -1  else season."year" end  flight_season_year
   		-- case when season.date >=last_Sat_Mar and season.date < last_Sat_Oct then  season."year" else extract(YEAR from season.last_Sat_Oct)  end  flight_season_year
   		,d_holiday.chinese_holiday
   		,d_holiday.is_chinese_holiday
   		from season 
   		left join xilejun.d_holiday on season.date = d_holiday.date
    )
    
