/*
 Write a query to find all practitioners who do not appear in the MedicationRequest table as a prescribing practitioner.
 */

WITH prescribing_practitioners AS (
    SELECT DISTINCT practitioner_id
    FROM {{ source('fhir', 'MedicationRequest') }}
)

SELECT
    id AS practitioner_id,
    name,
    specialty
FROM {{ source('fhir', 'Practitioner') }}
WHERE id NOT IN (SELECT practitioner_id FROM prescribing_practitioners)
