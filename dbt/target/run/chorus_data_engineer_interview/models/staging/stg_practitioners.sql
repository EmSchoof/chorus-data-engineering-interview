
  create view "postgres"."public"."stg_practitioners__dbt_tmp"
    
    
  as (
    SELECT
  id,
  identifier,
  name,
  specialty,
  telecom,
  active,
  created_at
FROM "postgres"."public"."Practitioner"
  );