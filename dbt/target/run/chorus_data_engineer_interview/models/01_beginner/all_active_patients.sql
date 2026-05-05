
  create view "postgres"."public"."all_active_patients__dbt_tmp"
    
    
  as (
    /* Write a query to return all patients who are active. */

SELECT
  id,
  identifier,
  gender
FROM "postgres"."public"."Patient"
WHERE active = true
  );