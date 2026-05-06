SELECT
  task_occurrence_id,
  status,
  updated_at
FROM {{ ref('stg_task_occurance_status') }}
