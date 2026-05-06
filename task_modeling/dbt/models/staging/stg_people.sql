SELECT
  person_id,
  person_name,
  created_at,
  updated_at
FROM {{ ref('people') }}
