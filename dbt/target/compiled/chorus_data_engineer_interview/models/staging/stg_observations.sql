SELECT
  id,
  patient_id,
  encounter_id,
  type,
  value,
  unit,
  recorded_at
FROM "postgres"."public"."Observation"