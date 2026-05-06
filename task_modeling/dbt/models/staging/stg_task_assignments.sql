SELECT
  task_assignment_id,
  task_id,
  person_id,
  assigned_date,
  created_at
FROM {{ ref('task_assignment') }}
