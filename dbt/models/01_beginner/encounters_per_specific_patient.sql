/*
Given a patient_id, retrieve all encounters for that patient, including the status and encounter date.
*/

SELECT
  id,
  status,
  encounter_date
FROM {{ source('fhir', 'Patient') }}
JOIN {{ source('fhir', 'Encounter') }}
    ON {{ source('fhir', 'Patient') }}.id = {{ source('fhir', 'Encounter') }}.patient_id
WHERE {{ source('fhir', 'Patient') }}.id = {var('patient_id')}