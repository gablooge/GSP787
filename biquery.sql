SELECT
  date, SUM(cumulative_confirmed) AS country_cases,
  SUM(cumulative_deceased) AS country_deaths
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date BETWEEN '2020-03-15'
  AND '2020-04-30'
  AND country_name ="United States of America"
GROUP BY date