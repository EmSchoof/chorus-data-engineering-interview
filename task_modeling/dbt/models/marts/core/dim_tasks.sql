SELECT
    1 AS task_id,
    'Task 1' AS task_name,
    'monthly' AS recurrence_cadence,
    12 AS max_occurrences
UNION ALL
SELECT
    2,
    'Task 2',
    'once',
    1
UNION ALL
SELECT
    3,
    'Task 3',
    'daily',
    30
