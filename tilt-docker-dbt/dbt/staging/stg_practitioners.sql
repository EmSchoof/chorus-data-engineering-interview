SELECT
  id,
  identifier,
  name,
  specialty,
  telecom,
  active,
  created_at
FROM {{ source('fake_data', 'Practitioner') }}
