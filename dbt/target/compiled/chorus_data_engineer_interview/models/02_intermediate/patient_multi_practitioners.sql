/*
Write a query to return a list of patient IDs who have had encounters with more than one distinct practitioner.
 */

WITH practitioner_counts AS (
    SELECT
        patient_id,
        COUNT(DISTINCT practitioner_id) AS distinct_practitioners
    FROM "postgres"."public"."Encounter"
    GROUP BY patient_id
)

SELECT
    patient_id
FROM practitioner_counts
WHERE distinct_practitioners > 1