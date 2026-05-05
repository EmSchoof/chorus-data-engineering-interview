SELECT
  id,
  patient_id,
  practitioner_id,
  status,
  encounter_date,
  reason,
  created_at
FROM {{ source('fake_data', 'Encounter') }}
