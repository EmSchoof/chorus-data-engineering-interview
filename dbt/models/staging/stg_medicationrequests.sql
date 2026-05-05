SELECT
    id,
    patient_id,
    practitioner_id,
    medication_name,
    dosage,
    status,
    created_at
FROM {{ source('fhir', 'MedicationRequest') }}
