SELECT
  id,
  identifier,
  name,
  gender,
  birth_date,
  address,
  telecom,
  active,
  created_at
FROM {{ source('fake_data', 'Patient') }}
