/* Write a query to return all patients who are active. */

SELECT
  id AS patient_id,
  name AS patient_fullname,
  gender
FROM {{ ref('stg_patients') }}
WHERE active = true
