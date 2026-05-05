SELECT
  assignment_id,
  task_id,
  person_id,
  assigned_date,
  created_at
FROM {{ source('task_tracking', 'TaskAssignment') }}
