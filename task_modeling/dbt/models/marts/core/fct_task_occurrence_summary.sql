/*
Person-Task summary
Shows completion rate and next occurrence for each person's tasks
*/

SELECT
    person_id,
    person_name,
    task_id,
    task_name,
    MAX(occurrence_number) AS total_occurrences,
    SUM(is_completed) AS completed_occurrences,
    MAX(occurrence_date) AS last_scheduled_date,
    CASE
        WHEN MAX(is_completed) = MAX(occurrence_number) THEN 'All Completed'
        WHEN MAX(occurrence_date) < CURRENT_DATE THEN 'Overdue'
        ELSE 'In Progress'
    END AS completion_status
FROM {{ ref('fct_task_occurrences') }}
GROUP BY person_id, person_name, task_id, task_name
ORDER BY person_id, task_id
