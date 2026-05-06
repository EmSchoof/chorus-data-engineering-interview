/*
Task occurrence status tracking mart
Allows people to track completion of recurring tasks

Output Columns:
task_occurrence_id
task_id
occurrence_number
occurrence_date
status
 */

SELECT
  task_occur.task_occurrence_id,
  task_occur.task_id,
  task_occur.task_name,
  task_occur.person_id,
  task_occur.person_name,
  task_occur.occurrence_number,
  task_occur.occurrence_date,
  COALESCE(task_stat.status, 'Not Started') AS status,
  COALESCE(task_stat.updated_at, task_occur.created_at) AS last_updated,
  CASE 
    WHEN COALESCE(task_stat.status, 'Not Started') = 'Completed' THEN 1
    ELSE 0
  END AS is_completed
FROM {{ ref('stg_task_occurrences') }} task_occur
LEFT JOIN {{ source('task_tracking', 'TaskOccurrenceStatus') }} task_stat
  ON task_occur.task_occurrence_id::uuid = task_stat.task_occurrence_id
ORDER BY task_occur.person_id, task_occur.task_id, task_occur.occurrence_date
