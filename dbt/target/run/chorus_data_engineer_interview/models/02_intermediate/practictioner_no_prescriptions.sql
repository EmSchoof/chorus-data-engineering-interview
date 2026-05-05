
  create view "postgres"."public"."practictioner_no_prescriptions__dbt_tmp"
    
    
  as (
    /*
 Write a query to find all practitioners who do not appear in the MedicationRequest table as a prescribing practitioner.
 */

WITH prescribing_practitioners AS (
    SELECT DISTINCT practitioner_id
    FROM "postgres"."public"."MedicationRequest"
)

SELECT
    id AS practitioner_id,
    name,
    specialty
FROM "postgres"."public"."Practitioner"
WHERE id NOT IN (SELECT practitioner_id FROM prescribing_practitioners)
  );