/*
Write a query to fetch all observations for a given patient_id, showing the observation type, value, unit, and recorded date.
*/

SELECT
  patient_id,
  type,
  value,
  unit,
  recorded_at
FROM {{ source('fhir', 'Patient') }}
JOIN {{ source('fhir', 'Observation') }}
    ON {{ source('fhir', 'Patient') }}.id = {{ source('fhir', 'Observation') }}.patient_id
WHERE {{ source('fhir', 'Patient') }}.id = {{ var('id') }}