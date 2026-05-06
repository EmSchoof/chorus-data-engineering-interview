/*
Write a query to return a list of patient IDs who have had encounters with more than one distinct practitioner.
 */

WITH practitioner_counts AS (
    SELECT
        patient_id,
        COUNT(DISTINCT practitioner_id) AS distinct_practitioners
    FROM {{ ref('stg_encounters') }}
    GROUP BY patient_id
)

SELECT
    patient_id AS patient_id_with_multiple_practitioners
FROM practitioner_counts
WHERE distinct_practitioners > 1
