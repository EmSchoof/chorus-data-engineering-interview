-- Person-Task summary
-- Shows completion rate and next occurrence for each person's tasks

WITH completion_summary AS (
  SELECT
    person_id,
    person_name,
    task_id,
    task_name,
    COUNT(*) AS total_occurrences,
    SUM(is_completed) AS completed_occurrences,
    ROUND(100.0 * SUM(is_completed) / COUNT(*), 2) AS completion_rate,
    MAX(CASE WHEN status != 'Completed' THEN occurrence_date END) AS next_occurrence
  FROM {{ ref('fct_task_occurrences') }}
  GROUP BY person_id, person_name, task_id, task_name
)
SELECT
  person_id,
  person_name,
  task_id,
  task_name,
  total_occurrences,
  completed_occurrences,
  completion_rate,
  next_occurrence,
  CASE 
    WHEN completion_rate = 100 THEN 'On Track'
    WHEN completion_rate >= 75 THEN 'Good'
    WHEN completion_rate >= 50 THEN 'Needs Attention'
    ELSE 'At Risk'
  END AS health_status
FROM completion_summary
ORDER BY person_id, task_id
