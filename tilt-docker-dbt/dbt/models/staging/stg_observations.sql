SELECT
  id,
  patient_id,
  encounter_id,
  value,
  unit,
  recorded_at
FROM {{ source('fake_data', 'Observation') }}
