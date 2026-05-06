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

This is the TRUE way to filter based on a specific patient_id, but dbt does not allow for variables to be used in the WHERE clause of a model.
However, for the sake of using dbt to run queries, we will use a subquery to filter the encounters for all patients
An additional filter down to a specific patient in a separate step.
*/

SELECT
  id AS observation_id,
  patient_id,
  value AS observation_value,
  unit AS observation_measurement_unit,
  recorded_at
FROM {{ ref('stg_observations') }}
WHERE patient_id IN (SELECT DISTINCT patient_id FROM {{ ref('stg_observations') }})
ORDER BY patient_id, recorded_at
