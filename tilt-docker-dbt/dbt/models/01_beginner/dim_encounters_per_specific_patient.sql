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
*/

SELECT
  id AS encounter_id,
  patient_id,
  status AS encounter_status,
  encounter_date
FROM {{ ref('stg_encounters') }}
WHERE patient_id IN (SELECT DISTINCT patient_id FROM {{ ref('stg_encounters') }})
ORDER BY patient_id, encounter_date
