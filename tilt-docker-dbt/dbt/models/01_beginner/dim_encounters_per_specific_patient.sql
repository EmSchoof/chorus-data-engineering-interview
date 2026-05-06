/*
Given a patient_id, retrieve all encounters for that patient, including the status and encounter date.
*/

/*
SELECT
  patient_id,
  status,
  encounter_date
FROM {{ source('fake_data', 'Encounter') }}
WHERE {{ source('fake_data', 'Encounter') }}.patient_id = {var('patient_id')}
*/

SELECT
  patient_id,
  status,
  encounter_date
FROM {{ ref('stg_encounters') }}
WHERE patient_id IN (SELECT DISTINCT patient_id FROM {{ ref('stg_encounters') }})
ORDER BY patient_id, encounter_date
