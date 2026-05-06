SELECT
  person_id,
  person_name,
  created_at
FROM {{ ref('people') }}
