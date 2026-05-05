/* Write a query to return all patients who are active. */

SELECT
  id,
  identifier,
  gender
FROM {{ source('fake_data', 'Patient') }}
WHERE active = true
