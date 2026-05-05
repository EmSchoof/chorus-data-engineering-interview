/* Write a query to return all patients who are active. */

SELECT
  id,
  identifier,
  gender
FROM "postgres"."public"."Patient"
WHERE active = true