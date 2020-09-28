#!/bin/bash
gcloud auth revoke --all

while [[ -z "$(gcloud config get-value core/account)" ]]; 
do echo "waiting login" && sleep 2; 
done

while [[ -z "$(gcloud config get-value project)" ]]; 
do echo "waiting project" && sleep 2; 
done


bq query --nouse_legacy_sql \
'SELECT sum(cumulative_confirmed) as total_cases_worldwide FROM `bigquery-public-data.covid19_open_data.covid19_open_data` where date='"'"'2020-04-15'"'"''

bq query --nouse_legacy_sql \
'SELECT
    COUNT(*) AS count_of_states
FROM (
SELECT
    subregion1_name AS state,
    SUM(cumulative_deceased) AS death_count
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  country_name="United States of America"
  AND date='"'"'2020-04-10'"'"'
  AND subregion1_name IS NOT NULL
GROUP BY
  subregion1_name
)
WHERE death_count > 100'


bq query --nouse_legacy_sql \
'SELECT
    subregion1_name AS state,
    SUM(cumulative_confirmed) AS total_confirmed_cases
FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
    country_name="United States of America"
    AND date = "2020-04-10"
GROUP BY subregion1_name
HAVING total_confirmed_cases > 1000
ORDER BY total_confirmed_cases DESC'

bq query --nouse_legacy_sql \
'SELECT SUM(cumulative_confirmed) AS total_confirmed_cases, SUM(cumulative_deceased) AS total_deaths, (SUM(cumulative_deceased)/SUM(cumulative_confirmed))*100 AS case_fatality_ratio
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE country_name="Italy" AND date BETWEEN "2020-04-01" AND "2020-04-30"'

bq query --nouse_legacy_sql \
'SELECT
 date
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
 country_name = "Italy"
 AND cumulative_deceased > 10000
ORDER BY date
LIMIT 1'

bq query --nouse_legacy_sql \
'WITH india_cases_by_date AS (
  SELECT
    date,
    SUM( cumulative_confirmed ) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name ="India"
    AND date between '"'"'2020-02-21'"'"' and '"'"'2020-03-15'"'"'
  GROUP BY
    date
  ORDER BY
    date ASC 
 )
, india_previous_day_comparison AS 
(SELECT
  date,
  cases,
  LAG(cases) OVER(ORDER BY date) AS previous_day,
  cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases
FROM india_cases_by_date
)

select count(*)
from india_previous_day_comparison
where net_new_cases=0
'

bq query --nouse_legacy_sql \
'WITH us_cases_by_date AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name="United States of America"
    AND date between '"'"'2020-03-22'"'"' and '"'"'2020-04-20'"'"'
  GROUP BY
    date
  ORDER BY
    date ASC 
 )
, us_previous_day_comparison AS 
(SELECT
  date,
  cases,
  LAG(cases) OVER(ORDER BY date) AS previous_day,
  cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases,
  (cases - LAG(cases) OVER(ORDER BY date))*100/LAG(cases) OVER(ORDER BY date) AS percentage_increase
FROM us_cases_by_date
)

select Date, cases as Confirmed_Cases_On_Day, previous_day as Confirmed_Cases_Previous_Day, percentage_increase as Percentage_Increase_In_Cases
from us_previous_day_comparison
where percentage_increase > 10'

bq query --nouse_legacy_sql \
'SELECT
  country_name AS country,
  SUM(cumulative_recovered) AS recovered_cases,
  SUM(cumulative_confirmed) AS confirmed_cases,
  (sum(cumulative_recovered)/sum(cumulative_confirmed))*100 as recovery_rate
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date='"'"'2020-05-10'"'"' AND cumulative_confirmed>50000
GROUP BY country
ORDER BY recovery_rate DESC
LIMIT 10'

bq query --nouse_legacy_sql \
'WITH
  france_cases AS (
  SELECT
    date,
    SUM(cumulative_confirmed) AS total_cases
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_name="France"
    AND date IN ('"'"'2020-01-24'"'"',
      '"'"'2020-05-10'"'"')
  GROUP BY
    date
  ORDER BY
    date)
, summary as (
SELECT
  total_cases AS first_day_cases,
  LEAD(total_cases) OVER(ORDER BY date) AS last_day_cases,
  DATE_DIFF(LEAD(date) OVER(ORDER BY date),date, day) AS days_diff
FROM
  france_cases
LIMIT 1
)

select first_day_cases, last_day_cases, days_diff, POW((last_day_cases/first_day_cases),(1/days_diff))-1 as cdgr
from summary
'


export PROJECT_ID=$(gcloud info --format='value(config.project)')
open "https://console.cloud.google.com/bigquery?project=$PROJECT_ID"

# Copy paste run bigquery.sql in console then explore with Datastudio report

