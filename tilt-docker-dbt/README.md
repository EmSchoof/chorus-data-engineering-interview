# FHIR Healthcare Data Pipeline

Local development environment for healthcare data analytics with FHIR schema, PostgreSQL, Docker, and dbt.

## Structure

```
tilt-docker-dbt/
├── dbt/                                # dbt analytics project
│   ├── dbt_packages/                   # Installed packages
│   │   ├── dbt_utils/
│   │   └── codegen/
│   ├── target/                         # dbt compiled & run artifacts
│   ├── models/
│   │   ├── staging/                   # Data canonicalization layer
│   │   │   ├── stg_patients.sql
│   │   │   ├── stg_practitioners.sql
│   │   │   ├── stg_encounters.sql
│   │   │   ├── stg_observations.sql
│   │   │   ├── stg_medication_requests.sql
│   │   │   └── schema.yml             # Source definitions & tests
│   │   ├── 01_beginner/               # Basic queries (filters)
│   │   │   ├── dim_all_active_patients.sql
│   │   │   ├── dim_encounters_per_specific_patient.sql
│   │   │   └── dim_observations_per_specific_patient.sql
│   │   ├── 02_intermediate/           # Joins & aggregations
│   │   │   ├── dim_patient_multi_practitioners.sql
│   │   │   ├── dim_practictioner_no_prescriptions.sql
│   │   │   ├── dim_recent_patient_encounters.sql
│   │   │   └── dim_top_3_prescriptions.sql
│   │   └── 03_advanced/               # Cohort analysis & window functions
│   │       ├── dim_avg_encounter_per_patient.sql
│   │       ├── dim_patient_prescription_wo_encounter.sql
│   │       └── dim_patient_retention_per_cohort.sql
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── package-lock.yml
│   └── profiles.yml                   # (not tracked; create locally)
├── docker/                            # Docker Compose setup
│   ├── Dockerfile                     # Multi-stage Python build (data gen)
│   ├── docker-compose.dev.yml         # PostgreSQL service
│   └── .env                           # Database credentials (user, password, db)
├── fhir/
│   └── ddl/
│       └── fhir_database.sql          # FHIR schema creation script
├── k8s/                               # Kubernetes manifests
│   ├── postgres.yaml                  # Postgres + pgAdmin Deployment, Service, PVC
│   └── postgres-secret.yaml           # Kubernetes Secret
├── src/                               # Python initialization
│   ├── main.py                        # Faker test data generator
│   ├── init_db.py
│   ├── requirements.txt               # psycopg2, faker, python-dotenv
│   └── __init__.py
├── Dockerfile                         # Root Dockerfile (for image builds)
└── README.md                          # This file
```

## Quick Start

### 1. Start PostgreSQL with Test Data

```bash
cd docker
docker compose -f docker-compose.dev.yml up -d
```

Credentials from `.env`:
- **User:** `user`
- **Password:** `password`
- **Database:** `postgres`
- **Port:** `5432`

Verify the container is running:

```bash
docker compose -f docker-compose.dev.yml logs db
```

The `docker-compose` starts PostgreSQL only. Schema creation and test data insertion happen separately.

### 2. Initialize FHIR Database Schema

```bash
# From project root or docker/ directory
psql -h 127.0.0.1 -U user -d postgres -f ../fhir/ddl/fhir_database.sql
# When prompted, enter: password
```

Or, if using Docker:

```bash
docker exec -i $(docker compose -f docker-compose.dev.yml ps -q db) psql -U user -d postgres < ../fhir/ddl/fhir_database.sql
```

### 3. Generate Test Data

```bash
# From project root
cd src
pip install -r requirements.txt
python main.py
```

Or, using Docker:

```bash
docker run --rm --network docker_default \
  -e POSTGRES_HOST=db \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_PORT=5432 \
  -v $(pwd)/src:/app \
  python:3.11.12-slim-bullseye \
  bash -c "cd /app && pip install -r requirements.txt && python main.py"
```

### 4. Configure dbt Profile

Create `~/.dbt/profiles.yml`:

```yaml
chorus_data_engineer_interview:
  outputs:
    dev:
      type: postgres
      host: localhost
      user: user
      password: password
      port: 5432
      dbname: postgres
      schema: public
      threads: 4
      keepalives_idle: 0
  target: dev
```

Verify connection:

```bash
cd dbt
dbt debug
```

### 5. Run dbt

```bash
# Install dependencies
dbt deps

# Run models (staging → dimensional)
dbt run

# Test data quality (source tests + model tests)
dbt test

# Generate documentation
dbt docs generate
dbt docs serve  # View at http://localhost:8000
```

## dbt Model Architecture

### Layer 1: Staging (`staging/`)
**Purpose:** Canonicalize raw FHIR tables.  
**Materialization:** `ephemeral` (temporary CTEs, no physical table)  
**Sources:** Defined in `schema.yml`

**Source tables from `schema.yml`:**
- `fake_data.Patient` — Patient demographics
- `fake_data.Practitioner` — Healthcare provider info
- `fake_data.Encounter` — Patient-practitioner visits
- `fake_data.Observation` — Clinical vitals & measurements
- `fake_data.MedicationRequest` — Medication prescriptions

**Output models:**
- `stg_patients`
- `stg_practitioners`
- `stg_encounters`
- `stg_observations`
- `stg_medication_requests`

### Layer 2: Dimensional Models (`01_beginner/`, `02_intermediate/`, `03_advanced/`)
**Purpose:** Analytics-ready queries organized by complexity.  
**Materialization:** `view` (default, queries re-execute on demand)

#### Beginner (Simple Filters)
- `dim_all_active_patients` — Patients with `active = true`
- `dim_encounters_per_specific_patient` — Encounters for a given patient
- `dim_observations_per_specific_patient` — Vitals for a given patient

#### Intermediate (Joins & Aggregations)
- `dim_patient_multi_practitioners` — Patients seen by 2+ practitioners
- `dim_practictioner_no_prescriptions` — Practitioners with zero prescriptions
- `dim_recent_patient_encounters` — Encounters in last 30 days
- `dim_top_3_prescriptions` — Most common medications prescribed

#### Advanced (Cohort Analysis & Window Functions)
- `dim_avg_encounter_per_patient` — Average encounters per patient
- `dim_patient_prescription_wo_encounter` — Prescriptions without recorded encounters
- `dim_patient_retention_per_cohort` — Retention rates by first-encounter month (6-month window)

## FHIR Data Model

**Tables (defined in `fhir/ddl/fhir_database.sql`):**

| Table | Columns | Notes |
|-------|---------|-------|
| `Patient` | id (PK), identifier (unique), name, gender, birth_date, address, telecom, active, created_at | UUID PKs, NOT NULL constraints |
| `Practitioner` | id (PK), identifier (unique), name, specialty, telecom, active, created_at | UUID PKs |
| `Encounter` | id (PK), patient_id (FK), practitioner_id (FK), status, encounter_date, reason, created_at | Foreign keys to Patient, Practitioner |
| `Observation` | id (PK), patient_id (FK), encounter_id (FK), type, value, unit, recorded_at | Foreign key constraints |
| `MedicationRequest` | id (PK), patient_id (FK), practitioner_id (FK), medication_name, dosage, status, created_at | Foreign key constraints |

**Key Constraints:**
- All IDs are UUID primary keys with `gen_random_uuid()` default
- Patient.identifier and Practitioner.identifier are unique
- Encounter references Patient and Practitioner
- Observation references Patient and Encounter
- MedicationRequest references Patient and Practitioner
- All tables include `created_at` timestamps

## Development Workflows

### Running Specific Models

```bash
# Run only staging models
dbt run -m staging

# Run beginner queries
dbt run -m 01_beginner

# Run model + downstream dependents
dbt run --models +dim_all_active_patients+
```

### Debugging

```bash
# Compile & show generated SQL
dbt compile --models 02_intermediate

# Test specific model columns
dbt test -m stg_patients

# Parse for syntax errors
dbt parse

# Show model lineage
dbt dag
```

### Adding New Models

1. Create SQL file in appropriate layer: `dbt/models/02_intermediate/dim_new_metric.sql`
2. Reference staging models: `FROM {{ ref('stg_patients') }}`
3. Use dbt_utils macros if needed (installed): `{{ dbt_utils.get_relations_by_pattern(...) }}`
4. Run: `dbt run -m dim_new_metric`
5. Document in `schema.yml` (optional)

## Kubernetes Deployment (Optional)

Manifests in `k8s/`:

```bash
# Create secret
kubectl create secret generic postgres-secret \
  --from-literal=user=user \
  --from-literal=password=password

# Deploy
kubectl apply -f k8s/postgres.yaml

# Access pgAdmin
kubectl port-forward svc/pgadmin-service 8080:80
# Then visit http://localhost:8080
```

Deployment includes:
- PostgreSQL 16 on port 5432
- pgAdmin 4 on port 80 (for UI management)
- Persistent volume claim (5Gi)
- Liveness & readiness probes

## Troubleshooting

### dbt connection fails

```bash
# Test profile
dbt debug

# Check PostgreSQL is running
docker compose -f docker-compose.dev.yml ps

# Verify credentials in ~/.dbt/profiles.yml and docker/.env match
```

### FHIR schema not created

```bash
# Re-run DDL
docker exec -i $(docker compose -f docker-compose.dev.yml ps -q db) \
  psql -U user -d postgres -f /path/to/fhir_database.sql

# Or manually connect and check tables
docker compose -f docker-compose.dev.yml exec db psql -U user -d postgres -c "\dt"
```

### Test data not inserted

```bash
# Verify dbt staging models reference correct schema
# Check fake_data source definition in dbt/models/staging/schema.yml

# Re-generate test data
cd src && python main.py
```

### dbt docs not generating

```bash
# Ensure schema.yml is well-formed (no YAML syntax errors)
dbt parse

# Regenerate docs
dbt docs generate --no-serve
dbt docs serve
```
