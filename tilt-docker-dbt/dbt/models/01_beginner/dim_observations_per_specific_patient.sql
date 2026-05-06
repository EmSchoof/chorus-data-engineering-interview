/*
Write a query to fetch all observations for a given patient_id, showing the observation type, value, unit, and recorded date.
*/

/*
SELECT
  patient_id,
  type,
  value,
  unit,
  recorded_at
FROM {{ ref('stg_observations') }}
WHERE {{ ref('stg_observations') }}.patient_id = {var('patient_id')}
*/

SELECT
  patient_id,
  value,
  unit,
  recorded_at
FROM {{ ref('stg_observations') }}
WHERE patient_id IN (SELECT DISTINCT patient_id FROM {{ ref('stg_observations') }})
ORDER BY patient_id, recorded_at
