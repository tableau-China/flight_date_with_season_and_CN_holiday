
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



--V4 2025-06-24  使用函数
SET search_path TO public;
CREATE OR REPLACE FUNCTION get_air_season(input_date DATE)
RETURNS TEXT AS $$
DECLARE
  year_part INTEGER := EXTRACT(YEAR FROM input_date);
  last_sunday_march DATE;
  last_sunday_nov DATE;
BEGIN
  -- 计算当年3月最后一个周日
  last_sunday_march := date_trunc('month', make_date(year_part, 3, 1)) + interval '1 month -1 day';
  WHILE EXTRACT(DOW FROM last_sunday_march)::INT <> 0 LOOP
    last_sunday_march := last_sunday_march - INTERVAL '1 day';
  END LOOP;

  -- 计算当年11月最后一个周日
  last_sunday_nov := date_trunc('month', make_date(year_part, 11, 1)) + interval '1 month -1 day';
  WHILE EXTRACT(DOW FROM last_sunday_nov)::INT <> 0 LOOP
    last_sunday_nov := last_sunday_nov - INTERVAL '1 day';
  END LOOP;

  IF input_date >= last_sunday_nov THEN
    RETURN 'Winter';
  ELSIF input_date < last_sunday_march THEN
    -- 属于上一年 Winter
    RETURN 'Winter';
  ELSE
    RETURN 'Summer';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT
  date,
  get_air_season(date) AS air_season
FROM public.d_date;

-- V3 找到航季日期的新方法：使用 day_of_week= EXTRACT(ISODOW FROM datum) 函数代替 EXTRACT(DOW FROM "date")
-- 找到每年三月和11月的最后一个周日
WITH Week_Starts AS (
    -- 找到每年4月1日和11月1日的日期，然后倒推所在周的天数，即可获得3月和10月最后一个周日的日期。
    SELECT
        "date" AS start_date,
        "year",
        --TO_CHAR( "date", '"W"IW'),
        -- EXTRACT(DOW FROM "date")  as dow,     -- 本周的第几天？ 倒推可以获得上周日的日期，周一默认是第0天。因此下面的计算错误
        -- "date"-  EXTRACT(DOW FROM "date")::int as Last_sunday_error,
        day_of_week,   --周几，相当于下面的 dow 值，但是有所不同。 周日，day_of_week=EXTRACT(ISODOW FROM datum)=7，而 EXTRACT(DOW FROM "date")  =0 
        "date" -  day_of_week::int as Last_sunday ,
        EXTRACT(ISODOW FROM "date" -  day_of_week::int)   --都是 Sunday 周日，每年的两个日期，就是冬季和夏季的分割点。
    FROM d_date
    WHERE ("month" = 4 or "month" = 11 ) AND EXTRACT(DAY FROM "date") = 1  --每个月月初，即每个月保留一行。
),

Season_Boundaries AS (   -- 数据转置，每一年都获得两个时间点：start_summer 和 end_summer 
    SELECT 
        "year",
        MAX(CASE WHEN EXTRACT(MONTH FROM Last_sunday) = 3   THEN Last_sunday  END) AS start_summer,
        MAX(CASE WHEN EXTRACT(MONTH FROM Last_sunday) = 10  THEN Last_sunday  END) AS end_summer ,
        LAG(MAX(CASE when EXTRACT(MONTH FROM Last_sunday) = 3   THEN Last_sunday  END)) OVER (ORDER BY year) AS prev_start_summer  --上一年度
    FROM  Week_Starts
    GROUP BY "year"
)
-- 更新操作，标记航季分割点
--UPDATE d_date


-- 更新操作，标记航季区间和年度
UPDATE d_date d
SET 
    is_flight_season_interval = true,
    flight_season = CASE    -- 更新夏季 和冬季字段
                        WHEN d."date"  >= sb.start_summer AND d."date"  < sb.end_summer THEN '夏季'
                        ELSE '冬季'
                    END,
    flight_season_year = case  -- 更新航空年度
                            WHEN d."date"  >= sb.start_summer THEN sb.year
                            ELSE sb.year - 1
                         END
FROM 
    Season_Boundaries sb
WHERE 
    d.year = sb.year OR d.year = sb.year - 1
    AND (d."date"  >= sb.prev_start_summer OR sb.prev_start_summer IS NULL);
-- 提交更新
COMMIT;




    
-- 从 json 中查询数据，INTO chinese_holidays (date, is_chinese_holiday, chinese_holiday, factor_workday)
WITH cte_Chinese_holidays AS (
SELECT 
    (h.value->>'date')::DATE AS date,
    (h.value->>'holiday')::BOOLEAN AS is_chinese_holiday,
    h.value->>'name' AS chinese_holiday,
    (h.value->>'wage')::INTEGER AS factor_workday
    --(h.value->>'rest')::INTEGER as rest_cnt

  from     -- 2025年
  json_each('{
 	"01-01":{"holiday":true,"name":"元旦","wage":3,"date":"2025-01-01","rest":22},
   		"01-26":{"holiday":false,"name":"春节前补班","wage":1,"after":false,"target":"春节","date":"2025-01-26","rest":25},
   		"01-28":{"holiday":true,"name":"除夕","wage":2,"date":"2025-01-28","rest":27},
		"01-29":{"holiday":true,"name":"初一","wage":3,"date":"2025-01-29","rest":1},
		"01-30":{"holiday":true,"name":"初二","wage":3,"date":"2025-01-30","rest":1},"01-31":{"holiday":true,"name":"初三","wage":3,"date":"2025-01-31","rest":1},"02-01":{"holiday":true,"name":"初四","wage":2,"date":"2025-02-01","rest":1},"02-02":{"holiday":true,"name":"初五","wage":2,"date":"2025-02-02","rest":1},"02-03":{"holiday":true,"name":"初六","wage":2,"date":"2025-02-03","rest":1},"02-04":{"holiday":true,"name":"初七","wage":2,"date":"2025-02-04","rest":1},"02-08":{"holiday":false,"name":"春节后补班","wage":1,"target":"春节","after":true,"date":"2025-02-08","rest":4},"04-04":{"holiday":true,"name":"清明节","wage":3,"date":"2025-04-04","rest":20},"04-05":{"holiday":true,"name":"清明节","wage":2,"date":"2025-04-05","rest":1},"04-06":{"holiday":true,"name":"清明节","wage":2,"date":"2025-04-06","rest":1},"04-27":{"holiday":false,"name":"劳动节前补班","wage":1,"target":"劳动节","after":false,"date":"2025-04-27","rest":12},"05-01":{"holiday":true,"name":"劳动节","wage":3,"date":"2025-05-01","rest":16},"05-02":{"holiday":true,"name":"劳动节","wage":2,"date":"2025-05-02","rest":1},"05-03":{"holiday":true,"name":"劳动节","wage":3,"date":"2025-05-03","rest":1},"05-04":{"holiday":true,"name":"劳动节","wage":3,"date":"2025-05-04","rest":1},"05-05":{"holiday":true,"name":"劳动节","wage":3,"date":"2025-05-05","rest":1},"05-31":{"holiday":true,"name":"端午节","wage":3,"date":"2025-05-31","rest":20},"06-01":{"holiday":true,"name":"端午节","wage":2,"date":"2025-06-01","rest":1},"06-02":{"holiday":true,"name":"端午节","wage":2,"date":"2025-06-02","rest":1},"09-28":{"holiday":false,"name":"国庆节前补班","after":false,"wage":1,"target":"国庆节","date":"2025-09-28","rest":58},"10-01":{"holiday":true,"name":"国庆节","wage":3,"date":"2025-10-01","rest":61},"10-02":{"holiday":true,"name":"国庆节","wage":3,"date":"2025-10-02","rest":1},"10-03":{"holiday":true,"name":"国庆节","wage":3,"date":"2025-10-03","rest":1},"10-04":{"holiday":true,"name":"国庆节","wage":2,"date":"2025-10-04","rest":1},"10-05":{"holiday":true,"name":"国庆节","wage":2,"date":"2025-10-05","rest":1},"10-06":{"holiday":true,"name":"中秋节","wage":2,"date":"2025-10-06","rest":1},"10-07":{"holiday":true,"name":"国庆节","wage":2,"date":"2025-10-07","rest":1},"10-08":{"holiday":true,"name":"国庆节","wage":2,"date":"2025-10-08","rest":1},
		"10-11":{"holiday":false,"after":true,"wage":1,"name":"国庆节后补班","target":"国庆节","date":"2025-10-11"}
    }'::json) AS h(key, value)
   )
   
/*FROM    -- 2024年  -- 2023年、2022年、2021年 
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
*/

 -- 解析 JSON 数据并插入到临时表中，2024年 
update d_date d
SET 
    is_chinese_holiday =  hol.is_chinese_holiday, 	 -- chinese_holiday, factor_workday)(h.value->>'holiday')::BOOLEAN  , 
	chinese_holiday =  hol.chinese_holiday, 	 	 -- h.value->>'name' ,
	factor_workday =   hol.factor_workday 			 -- (h.value->>'wage')::INTEGER
FROM 
    cte_Chinese_holidays hol
where  d."date"  = hol.date ;
-- 提交更新
COMMIT;


-- public.d_date_view source
 -- 创建一个简化视图 
 
CREATE OR REPLACE VIEW public.d_date_view
AS SELECT dd.date,
    dd.year,
    dd.day_of_week,
    dd.flight_season_year,
    dd.flight_season,
    dd.is_chinese_holiday,
    dd.chinese_holiday
   FROM d_date dd
  WHERE dd.date >= '2022-01-01'::date AND dd.year <= EXTRACT(YEAR FROM  CURRENT_TIMESTAMP::date );




 -- 如下内容废弃 

-- 更新表中的节假日信息，该方式已经被后面的 json 方式替换
/*
UPDATE d_date
SET 
   	    is_Chinese_holiday = true,
		is_Chinese_workday = false, 	 -- 新增，是否工作日，t 是，包含调休

    Chinese_holiday = 
		CASE
			  WHEN "date" BETWEEN '2022-01-01' AND '2022-01-03' THEN '元旦'
        WHEN "date" BETWEEN '2022-01-31' AND '2022-02-06' THEN '春节'
        WHEN "date" BETWEEN '2022-04-03' AND '2022-04-05' THEN '清明节'
        WHEN "date" BETWEEN '2022-04-30' AND '2022-05-04' THEN '劳动节'
        WHEN "date" BETWEEN '2022-06-03' AND '2022-06-05' THEN '端午节'
        WHEN "date" BETWEEN '2022-09-10' AND '2022-09-12' THEN '中秋节'
        WHEN "date" BETWEEN '2022-10-01' AND '2022-10-07' THEN '国庆节'
        WHEN "date" BETWEEN '2023-01-01' AND '2023-01-02' THEN '元旦'
        WHEN "date" BETWEEN '2023-01-21' AND '2023-01-27' THEN '春节'
        WHEN "date" BETWEEN '2023-04-05' AND '2023-04-07' THEN '清明节'
        WHEN "date" BETWEEN '2023-04-29' AND '2023-05-03' THEN '劳动节'
        WHEN "date" BETWEEN '2023-06-22' AND '2023-06-24' THEN '端午节'
        WHEN "date" BETWEEN '2023-09-29' AND '2023-10-01' THEN '中秋节'
        WHEN "date" BETWEEN '2023-10-01' AND '2023-10-07' THEN '国庆节'
        WHEN "date" BETWEEN '2023-12-30' AND '2024-01-01' THEN '元旦'
        WHEN "date" BETWEEN '2024-02-10' AND '2024-02-17' THEN '春节'
        --WHEN datum = '2024-02-09' THEN '除夕' --不放假，建议请假！
        WHEN "date" BETWEEN '2024-04-04' AND '2024-04-06' THEN '清明节'
        WHEN "date" BETWEEN '2024-05-01' AND '2024-05-05' THEN '劳动节'
        WHEN "date" BETWEEN '2024-06-08' AND '2024-06-10' THEN '端午节'
        WHEN "date" BETWEEN '2024-09-15' AND '2024-09-17' THEN '中秋节'
        WHEN "date" BETWEEN '2024-10-01' AND '2024-10-07' THEN '国庆节'
        ELSE NULL
    END
WHERE 
		 "date" BETWEEN '2022-01-01' AND '2022-01-03' or 
         "date" BETWEEN '2022-01-31' AND '2022-02-06' or
         "date" BETWEEN '2022-04-03' AND '2022-04-05' or
         "date" BETWEEN '2022-04-30' AND '2022-05-04' or
         "date" BETWEEN '2022-06-03' AND '2022-06-05' or
         "date" BETWEEN '2022-09-10' AND '2022-09-12' or
         "date" BETWEEN '2022-10-01' AND '2022-10-07' or
         "date" BETWEEN '2023-01-01' AND '2023-01-02' or
         "date" BETWEEN '2023-01-21' AND '2023-01-27' or
         "date" BETWEEN '2023-04-05' AND '2023-04-07' or
         "date" BETWEEN '2023-04-29' AND '2023-05-03' or
         "date" BETWEEN '2023-06-22' AND '2023-06-24' or
         "date" BETWEEN '2023-09-29' AND '2023-10-01' or
         "date" BETWEEN '2023-10-01' AND '2023-10-07' or
         "date" BETWEEN '2023-12-30' AND '2024-01-01' or
         "date" BETWEEN '2024-02-10' AND '2024-02-17' or
        --WHEN datum = '2024-02-09' THEN '除夕' --不放假，建议请假！
         "date" BETWEEN '2024-04-04' AND '2024-04-06' or
         "date" BETWEEN '2024-05-01' AND '2024-05-05' or
         "date" BETWEEN '2024-06-08' AND '2024-06-10' or
         "date" BETWEEN '2024-09-15' AND '2024-09-17' or
         "date" BETWEEN '2024-10-01' AND '2024-10-07' ;
COMMIT;
*/

-- 更新表中的航季和
/*
2022年冬春	10/30/2022	12/31/2022
2022年冬春	1/1/2023	3/25/2023
2023年夏秋	3/26/2023	10/28/2023
2023年冬春	10/29/2023	12/31/2023
2023年冬春	1/1/2024	3/30/2024
2024年夏秋	3/31/2024	10/26/2024
2024年冬春	10/27/2024	12/31/2024
2024年冬春	1/1/2025	3/29/2025
flight_season_year	VARCHAR(4) ,
 	flight_season
 	1.	夏季航季（Summer Season）：从每年三月的最后一个星期日开始，到十月的最后一个星期六结束。
	2.	冬季航季（Winter Season）：从每年十月的最后一个星期日开始，到次年三月的最后一个星期六结束。
*/
-- 手动方式更新  ，该方式已经被后面的自动方式替换
/*
UPDATE d_date
SET 
    flight_season_year = 
    	CASE
		WHEN "date" BETWEEN '2022-10-30' AND '2023-03-25' THEN '2022'
        WHEN "date" BETWEEN '2023-03-26' AND '2023-10-28' THEN '2023'
        WHEN "date" BETWEEN '2023-10-29' AND '2024-03-30' THEN '2023'
        WHEN "date" BETWEEN '2024-03-31' AND '2024-10-26' THEN '2024'
        WHEN "date" BETWEEN '2024-10-27' AND '2025-03-29' THEN '2024'
        --ELSE NULL
    END ,
	flight_season = 
		CASE
		WHEN "date" BETWEEN '2022-10-30' AND '2023-03-25' THEN '冬春'
        WHEN "date" BETWEEN '2023-03-26' AND '2023-10-28' THEN '夏秋'
        WHEN "date" BETWEEN '2023-10-29' AND '2024-03-30' THEN '冬春'
        WHEN "date" BETWEEN '2024-03-31' AND '2024-10-26' THEN '夏秋'
        WHEN "date" BETWEEN '2024-10-27' AND '2025-03-29' THEN '冬春'
        --ELSE NULL
    END ;
COMMIT;
*/







/*
--- V0 查找 航季的分割点
-- 1\ how many sundays in each march each year ?
select  -- distinct 
EXTRACT(YEAR FROM "date") ,
EXTRACT(MONTH FROM "date") ,
--TO_CHAR( "date",'Day' ) ,
--EXTRACT(ISODOW FROM "date"),
count(*)
from d_date dd 
where  EXTRACT(ISODOW FROM "date") =7 and EXTRACT(MONTH FROM "date") in (3,10)
group by 1,2


-- find the last sunday in March and October ?
select  -- distinct 
"date",
EXTRACT(YEAR FROM "date")  as "year",
EXTRACT(MONTH FROM "date") as "month",
TO_CHAR( "date",'Day' )  as "workday",
--EXTRACT(ISODOW FROM "date"),
row_number()  over  (partition by EXTRACT(YEAR FROM "date") ,EXTRACT(MONTH FROM "date") order by "date" ) as "N_in_month"
from d_date dd 
where  EXTRACT(ISODOW FROM "date") =7 and EXTRACT(MONTH FROM "date") in (3,10)

-- 使用已有字段，简化逻辑，构建 子查询。
select  -- distinct 
"year",
"month",
--TO_CHAR( "date",'Day' ) ,
--EXTRACT(ISODOW FROM "date"),
count(*)
from d_date dd 
where day_of_week =7 and "month" in (3,10)
group by 1,2

--第一次嵌套，在三月、十月的每个周日后，增加月内的次序和当月 Sunday 数量
with Sunday_count as (
	select  -- distinct 
	d."year",	
	d."month",
	count(*) as sunday_count
	from d_date d 
	where d.day_of_week =7 and d."month" in (3,10)
	group by 1,2
	)
select  dd."date",dd."year",
		dd."month",dd.day_of_week,
	row_number() over (partition by dd."year",dd."month", dd.day_of_week) as "N_in_month",
	Sunday_count.sunday_count as  "sunday_count"
from d_date dd
join Sunday_count on dd."year" = Sunday_count."year" and dd."month" = Sunday_count."month" 
where dd.day_of_week=7 
order by dd."date"
	


-- 第二次嵌套，保留三月和十月 最后一个周日 
with Sunday_count as (
	select  -- distinct 
	d."year",	
	d."month",
	count(*) as sunday_count
	from d_date d 
	where d.day_of_week =7 and d."month" in (3,10)
	group by 1,2
	)
select  r."date" 
from ( 
	select  dd."date",dd."year",
			dd."month",dd.day_of_week,
		row_number() over (partition by dd."year",dd."month", dd.day_of_week) as "N_in_month",
		Sunday_count.sunday_count as  "sunday_count"
	from d_date dd
	join Sunday_count on dd."year" = Sunday_count."year" and dd."month" = Sunday_count."month" 
	where dd.day_of_week=7 
	order by dd."date"
	) as r
where r."N_in_month" = r.sunday_count


-- 从年度开始，到三月最后一个周日，是否相同？ 大多数是13周，极端情况下第12周。
select  -- distinct 
EXTRACT(YEAR FROM "date")  as "year",
EXTRACT(MONTH FROM "date") as "month",
TO_CHAR( "date",'Day' )  as "workday",
--EXTRACT(ISODOW FROM "date"),
row_number()  over  (partition by EXTRACT(YEAR FROM "date") ) as "N_in_month"
from d_date dd 
where  EXTRACT(ISODOW FROM "date") =7 and EXTRACT(MONTH FROM "date") <=3




--  V1 更新 航季 
/*
-- 找到每年三月和十月的最后一个周日
WITH Sunday_count AS (
    SELECT  
        d.year,	
        d.month,
        COUNT(*) AS sunday_count
    FROM d_date d 
    WHERE d.day_of_week = 7 AND d.month IN (3, 10)
    GROUP BY 1, 2
),

Last_Sundays AS (
    SELECT 
        dd."date",
        dd.year,
        dd.month,
        ROW_NUMBER() OVER (PARTITION BY dd.year, dd.month ORDER BY dd."date" DESC) AS rn
    FROM d_date dd
    JOIN Sunday_count sc 
    ON dd.year = sc.year AND dd.month = sc.month
    WHERE dd.day_of_week = 7
),
Season_Boundaries AS (
    SELECT 
        year,
        MAX(CASE WHEN month = 3 AND rn = 1 THEN "date" END) AS start_summer,
        MAX(CASE WHEN month = 10 AND rn = 1 THEN "date" END) AS end_summer
    FROM Last_Sundays
    GROUP BY year
)
-- 更新操作，标记航季区间
UPDATE d_date d
SET 
    flight_season = 
	    CASE 
	        WHEN d."date" >= sb.start_summer AND d."date" < sb.end_summer THEN '夏季'
	        ELSE '冬季'
	    end,   
FROM 
    Season_Boundaries sb
WHERE 
    d.year = sb.year;
-- 提交更新
COMMIT;
*/


-- V2 更新航季对应的年度（完整版）
/*
-- 假设已经有 d_date 表，并包含 flight_season 和 flight_season_year 字段
ALTER TABLE d_date ADD COLUMN flight_season VARCHAR(10);
ALTER TABLE d_date ADD COLUMN flight_season_year INT;

-- 找到每年三月和十月的最后一个周日
WITH Sunday_count AS (
    SELECT  
        d.year,	
        d.month,
        COUNT(*) AS sunday_count
    FROM d_date d 
    WHERE d.day_of_week = 7 AND d.month IN (3, 10)
    GROUP BY 1, 2
),
Last_Sundays AS (
    SELECT 
        dd."date" ,
        dd.year,
        dd.month,
        ROW_NUMBER() OVER (PARTITION BY dd.year, dd.month ORDER BY dd."date"  DESC) AS rn
    FROM d_date dd
    JOIN Sunday_count sc 
    ON dd.year = sc.year AND dd.month = sc.month
    WHERE dd.day_of_week = 7
),
Season_Boundaries AS (
    SELECT 
        year,
        MAX(CASE WHEN month = 3 AND rn = 1 THEN "date"  END) AS start_summer,
        MAX(CASE WHEN month = 10 AND rn = 1 THEN "date"  END) AS end_summer,
        LAG(MAX(CASE WHEN month = 3 AND rn = 1 THEN "date"  END)) OVER (ORDER BY year) AS prev_start_summer
    FROM Last_Sundays
    GROUP BY year
)
-- 更新操作，标记航季区间和年度
UPDATE d_date d
SET 
    flight_season = CASE 
                        WHEN d."date"  >= sb.start_summer AND d."date"  < sb.end_summer THEN '夏季'
                        ELSE '冬季'
                    END,
    flight_season_year CASE
                            WHEN d."date"  >= sb.start_summer THEN sb.year
                            ELSE sb.year - 1
                         END
FROM 
    Season_Boundaries sb
WHERE 
    d.year = sb.year OR d.year = sb.year - 1
    AND (d."date"  >= sb.prev_start_summer OR sb.prev_start_summer IS NULL);
-- 提交更新
COMMIT;
*/


