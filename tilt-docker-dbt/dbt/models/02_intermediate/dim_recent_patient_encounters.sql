 /*
Retrieve each patient's most recent encounter (based on encounter_date). Return the patient_id, encounter_date, and status.
*/

WITH ranked_encounters AS (
    SELECT
        id,
        patient_id,
        encounter_date,
        status,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY encounter_date DESC) AS rn
    FROM {{ ref('stg_encounters') }}
)

SELECT
    id AS most_recent_encounter_id,
    patient_id,
    encounter_date AS most_recent_encounter_date,
    status AS most_recent_encounter_status
FROM ranked_encounters
WHERE rn = 1
