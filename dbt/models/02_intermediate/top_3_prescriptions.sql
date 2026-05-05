/*
 Write a query to find the three most commonly prescribed medications from the MedicationRequest table, sorted by the number of prescriptions.
 */

 WITH medication_counts AS (
     SELECT
         medication_name,
         COUNT(*) AS prescription_count
     FROM {{ source('fhir', 'MedicationRequest') }}
     GROUP BY medication_name
 )

SELECT
    medication_name,
    prescription_count
FROM medication_counts
ORDER BY prescription_count DESC
LIMIT 3
