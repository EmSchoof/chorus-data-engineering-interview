-- Task occurrence status tracking mart
-- Allows people to track completion of recurring tasks

SELECT
  toc.task_occurrence_id,
  toc.task_id,
  toc.task_name,
  toc.person_id,
  toc.person_name,
  toc.occurrence_number,
  toc.occurrence_date,
  COALESCE(tos.status, 'Not Started') AS status,
  COALESCE(tos.updated_at, toc.created_at) AS last_updated,
  CASE 
    WHEN COALESCE(tos.status, 'Not Started') = 'Completed' THEN 1
    ELSE 0
  END AS is_completed
FROM {{ ref('stg_task_occurrences') }} toc
LEFT JOIN {{ source('task_tracking', 'TaskOccurrenceStatus') }} tos
  ON toc.task_occurrence_id::uuid = tos.task_occurrence_id
ORDER BY toc.person_id, toc.task_id, toc.occurrence_date
