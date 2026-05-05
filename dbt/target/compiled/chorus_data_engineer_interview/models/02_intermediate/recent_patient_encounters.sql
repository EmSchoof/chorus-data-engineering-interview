/*
Retrieve each patient’s most recent encounter (based on encounter_date). Return the patient_id, encounter_date, and status.
*/

WITH ranked_encounters AS (
    SELECT
        patient_id,
        encounter_date,
        status,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY encounter_date DESC) AS rn
    FROM "postgres"."public"."Encounter"
)

SELECT
    patient_id,
    encounter_date,
    status
FROM ranked_encounters
WHERE rn = 1