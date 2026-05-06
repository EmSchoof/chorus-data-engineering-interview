SELECT
  task_occurrence_id,
  status,
  updated_at
FROM {{ ref('task_occurance_status') }}
