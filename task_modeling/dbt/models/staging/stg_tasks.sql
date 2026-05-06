SELECT
  task_id,
  task_name,
  cadence,
  max_occurrences,
  start_date,
  created_at
FROM {{ ref('tasks') }}
