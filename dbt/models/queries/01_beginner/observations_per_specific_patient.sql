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
FROM {{ source('fake_data', 'Observation') }}
WHERE {{ source('fake_data', 'Observation') }}.id = {var('patient_id')}
*/

SELECT
  patient_id,
  type,
  value,
  unit,
  recorded_at
FROM {{ source('fake_data', 'Observation') }}
WHERE patient_id IN (SELECT DISTINCT patient_id FROM {{ source('fake_data', 'Observation') }})
ORDER BY patient_id, recorded_at
