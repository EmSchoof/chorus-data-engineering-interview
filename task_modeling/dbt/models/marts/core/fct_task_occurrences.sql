/*
Task occurrence fact table
Generates recurring task occurrences from task definitions and enriches with status
*/

WITH

assigned_tasks AS (
    -- CTE for only valid task assignments, ensuring we only generate occurrences for tasks that are assigned to people
    SELECT
        t.task_id,
        t.task_name,
        t.cadence,
        t.start_date,
        t.max_occurrences,
        p.person_id,
        p.person_name
    FROM {{ ref('dim_tasks') }} t
    INNER JOIN {{ ref('dim_task_assignment') }} ta
        ON t.task_id = ta.task_id
    INNER JOIN {{ ref('dim_people') }} p
        ON ta.person_id = p.person_id
    ),

task_occurrences AS (
  -- Generate task occurrences based on cadence and max occurrences for each assigned task
  SELECT
    ROW_NUMBER() OVER (ORDER BY t.task_id, t.person_id, n)::integer AS task_occurrence_id,
    t.task_id,
    t.task_name,
    t.person_id,
    t.person_name,
    n AS occurrence_number,
    CASE t.cadence
      WHEN 'daily' THEN t.start_date + (n || ' days')::interval
      WHEN 'weekly' THEN t.start_date + (n * 7 || ' days')::interval
      WHEN 'monthly' THEN t.start_date + (n || ' months')::interval
    END AS occurrence_date,
    CURRENT_TIMESTAMP AS created_at
  FROM assigned_tasks t
  CROSS JOIN LATERAL generate_series(0, t.max_occurrences - 1) AS n
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
LEFT JOIN {{ ref('dim_task_occurrence_status') }} stat
  ON occ.task_occurrence_id = stat.task_occurrence_id
