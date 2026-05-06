SELECT
  person_id,
  person_name,
  created_at
FROM {{ source('task_tracking', 'Person') }}
