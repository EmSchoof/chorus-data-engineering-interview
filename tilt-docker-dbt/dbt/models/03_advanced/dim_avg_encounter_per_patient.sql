/*
 Calculate the average number of encounters per patient, rounded to two decimal places.
 */

WITH encounter_counts AS (
    SELECT
        patient_id,
        COUNT(*) AS encounter_count
    FROM {{ ref('stg_encounters') }}
    GROUP BY patient_id
)

SELECT
    patient_id,
    ROUND(AVG(encounter_count), 2) AS avg_encounters_per_patient
FROM encounter_counts
GROUP BY patient_id
