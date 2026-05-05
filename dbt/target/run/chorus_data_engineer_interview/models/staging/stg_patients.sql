
  create view "postgres"."public"."stg_patients__dbt_tmp"
    
    
  as (
    SELECT
  id,
  identifier,
  name,
  gender,
  birth_date,
  address,
  telecom,
  active,
  created_at
FROM "postgres"."public"."Patient"
  );