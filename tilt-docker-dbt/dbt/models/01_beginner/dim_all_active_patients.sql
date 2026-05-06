/* Write a query to return all patients who are active. */

SELECT
  id,
  identifier,
  gender
FROM {{ ref('stg_patients') }}
WHERE active = true
