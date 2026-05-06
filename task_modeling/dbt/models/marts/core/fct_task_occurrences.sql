/*
Task occurrence fact table
Generates recurring task occurrences from task definitions and enriches with status
*/

WITH task_occurrences AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY t.task_id, p.person_id, n.n)::integer AS task_occurrence_id,
    t.task_id,
    t.task_name,
    p.person_id,
    p.person_name,
    n.n AS occurrence_number,
    CASE 
      WHEN t.cadence = 'daily' THEN 
        (t.start_date + (n.n || ' days')::interval)
      WHEN t.cadence = 'weekly' THEN 
        (t.start_date + (n.n * 7 || ' days')::interval)
      WHEN t.cadence = 'monthly' THEN 
        (t.start_date + (n.n || ' months')::interval)
    END AS occurrence_date,
    CURRENT_TIMESTAMP AS created_at
  FROM {{ ref('stg_tasks') }} t
  CROSS JOIN {{ ref('stg_people') }} p
  CROSS JOIN LATERAL (
    SELECT generate_series(0, t.max_occurrences - 1) AS n
  ) n
  INNER JOIN {{ ref('stg_task_assignments') }} ta
    ON t.task_id = ta.task_id 
    AND p.person_id = ta.person_id
  WHERE n.n < t.max_occurrences
)

SELECT
  occ.task_occurrence_id,
  occ.task_id,
  occ.task_name,
  occ.person_id,
  occ.person_name,
  occ.occurrence_number,
  occ.occurrence_date,
  COALESCE(stat.status, 'Not Started') AS status,
  COALESCE(stat.updated_at, occ.created_at) AS last_updated,
  CASE 
    WHEN COALESCE(stat.status, 'Not Started') = 'Completed' THEN 1
    ELSE 0
  END AS is_completed
FROM task_occurrences occ
LEFT JOIN {{ ref('task_occurance_status') }} stat
  ON occ.task_occurrence_id = stat.task_occurrence_id
