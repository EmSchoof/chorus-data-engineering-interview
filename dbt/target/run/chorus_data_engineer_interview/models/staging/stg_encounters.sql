
  create view "postgres"."public"."stg_encounters__dbt_tmp"
    
    
  as (
    SELECT
  id,
  patient_id,
  practitioner_id,
  status,
  encounter_date,
  reason,
  created_at
FROM "postgres"."public"."Encounter"
  );