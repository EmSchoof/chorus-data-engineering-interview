SELECT
  task_assignment_id,
  task_id,
  person_id,
  assigned_date
FROM {{ ref('stg_task_assignments') }}
