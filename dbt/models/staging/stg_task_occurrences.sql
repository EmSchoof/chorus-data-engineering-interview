-- Create task occurrences from task definitions
-- Handles daily, weekly, monthly recurrence

WITH task_dates AS (
  SELECT
    t.task_id,
    t.task_name,
    t.cadence,
    t.max_occurrences,
    p.person_id,
    p.person_name,
    -- Generate occurrence dates based on cadence
    CASE 
      WHEN t.cadence = 'daily' THEN 
        (t.start_date + (n.n || ' days')::interval)
      WHEN t.cadence = 'weekly' THEN 
        (t.start_date + (n.n * 7 || ' days')::interval)
      WHEN t.cadence = 'monthly' THEN 
        (t.start_date + (n.n || ' months')::interval)
    END AS occurrence_date,
    n.n AS occurrence_number
  FROM {{ source('task_tracking', 'Task') }} t
  CROSS JOIN {{ source('task_tracking', 'Person') }} p
  CROSS JOIN LATERAL (
    SELECT generate_series(0, t.max_occurrences - 1) AS n
  ) n
  INNER JOIN {{ source('task_tracking', 'TaskAssignment') }} ta 
    ON t.task_id = ta.task_id 
    AND p.person_id = ta.person_id
  WHERE n.n < t.max_occurrences
),
task_occurrences AS (
  SELECT
    gen_random_uuid()::text AS task_occurrence_id,
    task_id,
    task_name,
    person_id,
    person_name,
    occurrence_number,
    occurrence_date,
    'Not Started' AS status,
    CURRENT_TIMESTAMP AS created_at,
    NULL AS updated_at
  FROM task_dates
)
SELECT * FROM task_occurrences
