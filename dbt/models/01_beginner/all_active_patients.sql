/* Write a query to return all patients who are active. */

SELECT
  id,
  identifier,
  gender
FROM {{ source('fhir', 'Patient') }}
WHERE active = true