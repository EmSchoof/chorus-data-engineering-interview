SELECT
  id,
  identifier,
  name,
  specialty,
  telecom,
  active,
  created_at
FROM {{ source('fhir', 'Practitioner') }}
