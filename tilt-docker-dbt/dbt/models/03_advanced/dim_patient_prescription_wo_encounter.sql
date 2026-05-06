/*
 Write a query to find patients who have a record in the MedicationRequest table but no associated encounters in the Encounter table.
 */

WITH

patients_with_medication_requests AS (
    SELECT DISTINCT patient_id
    FROM {{ ref('stg_medication_requests') }}
),

patients_with_encounters AS (
    SELECT DISTINCT patient_id
    FROM {{ ref('stg_encounters') }}
)

SELECT
    patient_id
FROM patients_with_medication_requests
WHERE patient_id NOT IN (SELECT patient_id FROM patients_with_encounters)
