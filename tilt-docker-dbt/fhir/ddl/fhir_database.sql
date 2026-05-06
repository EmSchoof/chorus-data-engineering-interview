CREATE TABLE "Patient" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "identifier" varchar(255) UNIQUE NOT NULL,
  "name" varchar(255) NOT NULL,
  "gender" varchar(10),
  "birth_date" date,
  "address" text,
  "telecom" varchar(255),
  "active" boolean DEFAULT true,
  "created_at" timestamp DEFAULT (now())
);

CREATE TABLE "Practitioner" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "identifier" varchar(255) UNIQUE NOT NULL,
  "name" varchar(255) NOT NULL,
  "specialty" varchar(255),
  "telecom" varchar(255),
  "active" boolean DEFAULT true,
  "created_at" timestamp DEFAULT (now())
);

CREATE TABLE "Encounter" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "patient_id" uuid NOT NULL,
  "practitioner_id" uuid,
  "status" varchar(50) NOT NULL,
  "encounter_date" timestamp DEFAULT (now()),
  "reason" text,
  "created_at" timestamp DEFAULT (now())
);

CREATE TABLE "Observation" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "patient_id" uuid NOT NULL,
  "encounter_id" uuid,
  "type" varchar(255) NOT NULL,
  "value" varchar(255) NOT NULL,
  "unit" varchar(50),
  "recorded_at" timestamp DEFAULT (now())
);

CREATE TABLE "MedicationRequest" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "patient_id" uuid NOT NULL,
  "practitioner_id" uuid NOT NULL,
  "medication_name" varchar(255) NOT NULL,
  "dosage" varchar(255),
  "status" varchar(50) NOT NULL,
  "created_at" timestamp DEFAULT (now())
);

COMMENT ON COLUMN "Patient"."identifier" IS 'Patient identifier';

COMMENT ON COLUMN "Patient"."name" IS 'Patient full name';

COMMENT ON COLUMN "Patient"."gender" IS 'Male, Female, Other, Unknown';

COMMENT ON COLUMN "Patient"."birth_date" IS 'Patient date of birth';

COMMENT ON COLUMN "Patient"."address" IS 'Full address as a single text field';

COMMENT ON COLUMN "Patient"."telecom" IS 'Contact details, can be phone or email';

COMMENT ON COLUMN "Patient"."active" IS 'Whether the patient is active';

COMMENT ON COLUMN "Practitioner"."identifier" IS 'Practitioner identifier';

COMMENT ON COLUMN "Practitioner"."name" IS 'Practitioner full name';

COMMENT ON COLUMN "Practitioner"."specialty" IS 'Medical specialty, e.g., Cardiology';

COMMENT ON COLUMN "Practitioner"."telecom" IS 'Contact details';

COMMENT ON COLUMN "Practitioner"."active" IS 'Whether the practitioner is active';

COMMENT ON COLUMN "Encounter"."patient_id" IS 'Reference to Patient';

COMMENT ON COLUMN "Encounter"."practitioner_id" IS 'Practitioner responsible';

COMMENT ON COLUMN "Encounter"."status" IS 'planned, in-progress, finished, cancelled';

COMMENT ON COLUMN "Encounter"."encounter_date" IS 'Date and time of encounter';

COMMENT ON COLUMN "Encounter"."reason" IS 'Reason for the visit';

COMMENT ON COLUMN "Observation"."patient_id" IS 'Reference to Patient';

COMMENT ON COLUMN "Observation"."encounter_id" IS 'Reference to Encounter';

COMMENT ON COLUMN "Observation"."type" IS 'Type of observation, e.g., blood pressure';

COMMENT ON COLUMN "Observation"."value" IS 'Value of the observation, e.g., 120/80 mmHg';

COMMENT ON COLUMN "Observation"."unit" IS 'Unit of measurement, e.g., mmHg, bpm';

COMMENT ON COLUMN "Observation"."recorded_at" IS 'Time the observation was recorded';

COMMENT ON COLUMN "MedicationRequest"."patient_id" IS 'Reference to Patient';

COMMENT ON COLUMN "MedicationRequest"."practitioner_id" IS 'Prescribing practitioner';

COMMENT ON COLUMN "MedicationRequest"."medication_name" IS 'Name of prescribed medication';

COMMENT ON COLUMN "MedicationRequest"."dosage" IS 'Dosage instructions';

COMMENT ON COLUMN "MedicationRequest"."status" IS 'active, completed, cancelled';

ALTER TABLE "Encounter" ADD FOREIGN KEY ("patient_id") REFERENCES "Patient" ("id");

ALTER TABLE "Encounter" ADD FOREIGN KEY ("practitioner_id") REFERENCES "Practitioner" ("id");

ALTER TABLE "Observation" ADD FOREIGN KEY ("patient_id") REFERENCES "Patient" ("id");

ALTER TABLE "Observation" ADD FOREIGN KEY ("encounter_id") REFERENCES "Encounter" ("id");

ALTER TABLE "MedicationRequest" ADD FOREIGN KEY ("patient_id") REFERENCES "Patient" ("id");

ALTER TABLE "MedicationRequest" ADD FOREIGN KEY ("practitioner_id") REFERENCES "Practitioner" ("id");
