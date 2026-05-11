SELECT
  task_occurrence_id,
  status,
  updated_at
FROM {{ ref('stg_task_occurrences_status') }}
