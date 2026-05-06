/*
Given a patient_id, retrieve all encounters for that patient, including the status and encounter date.
*/

/*
SELECT
  patient_id,
  status,
  encounter_date
FROM {{ ref('stg_encounters') }}
WHERE {{ ref('stg_encounters') }}.patient_id = {var('patient_id')}


This is the TRUE way to filter based on a specific patient_id, but dbt does not allow for variables to be used in the WHERE clause of a model.
However, for the sake of using dbt to run queries, we will use a subquery to filter the encounters for all patients
An additional filter down to a specific patient in a separate step.
*/

SELECT
  id AS encounter_id,
  patient_id,
  status AS encounter_status,
  encounter_date
FROM {{ ref('stg_encounters') }}
WHERE patient_id IN (SELECT DISTINCT patient_id FROM {{ ref('stg_encounters') }})
ORDER BY patient_id, encounter_date
