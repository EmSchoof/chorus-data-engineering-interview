SELECT
  task_assignment_id,
  task_id,
  person_id,
  assigned_date
FROM {{ ref('task_assignment') }}
