/*
Given a patient_id, retrieve all encounters for that patient, including the status and encounter date.
*/

SELECT
  id,
  status,
  encounter_date
FROM {{ source('fake_data', 'Patient') }}
JOIN {{ source('fake_data', 'Encounter') }}
    ON {{ source('fake_data', 'Patient') }}.id = {{ source('fake_data', 'Encounter') }}.patient_id
WHERE {{ source('fake_data', 'Patient') }}.id = {var('patient_id')}
