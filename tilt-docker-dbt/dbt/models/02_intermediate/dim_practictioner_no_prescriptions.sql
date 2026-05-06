/*
 Write a query to find all practitioners who do not appear in the MedicationRequest table as a prescribing practitioner.
 */

WITH prescribing_practitioners AS (
    SELECT DISTINCT practitioner_id
    FROM {{ ref('stg_medication_requests') }}
)

SELECT
    id AS practitioner_id,
    name,
    specialty
FROM {{ ref('stg_practitioners') }}
WHERE id NOT IN (SELECT practitioner_id FROM prescribing_practitioners)
