SELECT
  task_occurrence_id,
  status,
  updated_at
FROM {{ ref('task_occurrence_status') }}
