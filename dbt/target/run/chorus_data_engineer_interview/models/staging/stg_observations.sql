
  create view "postgres"."public"."stg_observations__dbt_tmp"
    
    
  as (
    SELECT
  id,
  patient_id,
  encounter_id,
  type,
  value,
  unit,
  recorded_at
FROM "postgres"."public"."Observation"
  );