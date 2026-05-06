/*
Write a query to count how many patients had their first encounter in each month (YYYY-MM format) and still had at least one encounter in the following six months.
*/

WITH

first_encounters AS (
    SELECT
        patient_id,
        MIN(encounter_date) AS first_encounter_date
    FROM {{ ref('stg_encounters') }}
    GROUP BY patient_id
),

retained_patients AS (
    SELECT
        fe.patient_id,
        fe.first_encounter_date,
        DATE_TRUNC('month', fe.first_encounter_date) AS first_encounter_month,
        MAX(e.encounter_date) AS last_encounter_date
    FROM first_encounters fe
    JOIN {{ ref('stg_encounters') }} e ON fe.patient_id = e.patient_id
    WHERE e.encounter_date >= fe.first_encounter_date
    GROUP BY fe.patient_id, fe.first_encounter_date
)

SELECT
    first_encounter_month,
    COUNT(DISTINCT patient_id) AS retained_patients_count
FROM retained_patients
WHERE last_encounter_date >= first_encounter_date + INTERVAL '6 months'
GROUP BY first_encounter_month
ORDER BY first_encounter_month
