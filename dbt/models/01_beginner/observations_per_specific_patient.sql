/*
Write a query to fetch all observations for a given patient_id, showing the observation type, value, unit, and recorded date.
*/

SELECT
  patient_id,
  type,
  value,
  unit,
  recorded_at
FROM {{ source('fake_data', 'Patient') }}
JOIN {{ source('fake_data', 'Observation') }}
    ON {{ source('fake_data', 'Patient') }}.id = {{ source('fake_data', 'Observation') }}.patient_id
WHERE {{ source('fake_data', 'Patient') }}.id = {var('patient_id')}
