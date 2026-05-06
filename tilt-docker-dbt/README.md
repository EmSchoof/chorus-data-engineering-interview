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
│   ├── dbt_project.yml                # Project config (default: table materialization)
│   ├── packages.yml                   # dbt-utils, codegen
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
│   ├── init_db.py                     # Schema initialization script
│   ├── requirements.txt               # psycopg2, faker, python-dotenv
│   ├── .env                           # Database connection variables
│   └── __init__.py
├── Dockerfile                         # Root Dockerfile (multi-stage, non-root user)
└── README.md                          # This file
```

## Quick Start

### 1. Start PostgreSQL

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

### 2. Initialize FHIR Database Schema

Option A: Using Docker exec
```bash
docker exec -i $(docker compose -f docker-compose.dev.yml ps -q db) \
  psql -U user -d postgres < ../fhir/ddl/fhir_database.sql
```

Option B: Using Python script (auto-adds IF NOT EXISTS)
```bash
cd ../src
pip install -r requirements.txt
python init_db.py
```

Option C: Manual psql
```bash
psql -h 127.0.0.1 -U user -d postgres -f ../fhir/ddl/fhir_database.sql
# When prompted, enter: password
```

### 3. Generate Test Data

```bash
cd src
python main.py
```

The script generates:
- 10 patients
- 5 practitioners
- 15 encounters
- 20 observations
- 10 medication requests

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
**Materialization:** `view` (default, no override in config)  
**Sources:** Defined in `schema.yml`

**Source tables from `schema.yml`:**
- `fake_data.Patient` — Patient demographics
- `fake_data.Practitioner` — Healthcare provider info
- `fake_data.Encounter` — Patient-practitioner visits
- `fake_data.Observation` — Clinical vitals & measurements
- `fake_data.MedicationRequest` — Medication prescriptions

**Output models:**
- `stg_patients` — Select all columns from Patient
- `stg_practitioners` — Select all columns from Practitioner
- `stg_encounters` — Select all columns from Encounter
- `stg_observations` — Select all columns from Observation
- `stg_medication_requests` — Select all columns from MedicationRequest

### Layer 2: Dimensional Models (`01_beginner/`, `02_intermediate/`, `03_advanced/`)

**Purpose:** Analytics-ready queries organized by complexity.  
**Materialization:** `table` (default from dbt_project.yml, no override)  
**Re-execution:** Entire table rebuilt on each `dbt run`

#### Beginner (Simple Filters)
- `dim_all_active_patients` — Patients with `active = true` (single table scan)
- `dim_encounters_per_specific_patient` — Encounters for a given patient (filter + select)
- `dim_observations_per_specific_patient` — Vitals for a given patient (filter + select)

#### Intermediate (Joins & Aggregations)
- `dim_patient_multi_practitioners` — Patients seen by 2+ practitioners (GROUP BY + HAVING)
- `dim_practictioner_no_prescriptions` — Practitioners with zero prescriptions (LEFT JOIN + filter)
- `dim_recent_patient_encounters` — Encounters in last 30 days (time-based filter)
- `dim_top_3_prescriptions` — Most common medications prescribed (GROUP BY + ORDER BY LIMIT)

#### Advanced (Cohort Analysis & Window Functions)
- `dim_avg_encounter_per_patient` — Average encounters per patient (aggregation)
- `dim_patient_prescription_wo_encounter` — Prescriptions without recorded encounters (anti-join)
- `dim_patient_retention_per_cohort` — Retention rates by first-encounter month (cohort analysis with 6-month window)

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
- Patient.identifier and Practitioner.identifier are UNIQUE
- Encounter references Patient and Practitioner via foreign keys
- Observation references Patient and Encounter via foreign keys
- MedicationRequest references Patient and Practitioner via foreign keys
- All tables include `created_at` timestamps
- Table creation is idempotent: `init_db.py` adds `CREATE TABLE IF NOT EXISTS`

## Development Workflows

### Running Specific Models

```bash
cd dbt

# Run only staging models
dbt run -m staging

# Run beginner queries
dbt run -m 01_beginner

# Run intermediate queries
dbt run -m 02_intermediate

# Run advanced queries
dbt run -m 03_advanced

# Run model + downstream dependents
dbt run --models +dim_all_active_patients+
```

### Debugging

```bash
cd dbt

# Compile & show generated SQL
dbt compile --models 02_intermediate

# Test specific model columns
dbt test -m stg_patients

# Parse for syntax errors
dbt parse

# Show model lineage
dbt dag

# View compiled SQL without running
dbt compile -m dim_patient_retention_per_cohort
```

### Adding New Models

1. Create SQL file in appropriate layer: `dbt/models/02_intermediate/dim_new_metric.sql`
2. Reference staging models: `FROM {{ ref('stg_patients') }}`
3. Use dbt_utils macros if needed (installed): `{{ dbt_utils.deduplicate(...) }}`
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
- Liveness & readiness probes (pg_isready)

## Tilt Orchestration

At project root, `Tiltfile` orchestrates setup:

```bash
tilt up
```

**Orchestration steps:**

1. **Deploy Kubernetes manifests** — PostgreSQL + pgAdmin via `postgres.yaml` and `postgres-secret.yaml`
2. **init_schema** — Manually trigger `init_db.py` to create FHIR schema (auto-adds IF NOT EXISTS)
3. **seed_db** — Manually trigger `main.py` to generate Faker test data

Manual triggers allow control over execution order. After triggering both:

```bash
cd tilt-docker-dbt/dbt
dbt run
dbt test
```

## Troubleshooting

### dbt connection fails

```bash
# Test profile
dbt debug

# Check PostgreSQL is running
docker compose -f docker-compose.dev.yml ps

# Verify credentials in ~/.dbt/profiles.yml and docker/.env match
cat ~/.dbt/profiles.yml
cat docker/.env
```

### FHIR schema not created

```bash
# Check tables exist
docker compose -f docker-compose.dev.yml exec db psql -U user -d postgres -c "\dt"

# Re-run schema initialization
cd src && python init_db.py

# Or use Docker exec
docker exec -i $(docker compose -f docker-compose.dev.yml ps -q db) \
  psql -U user -d postgres -c "CREATE TABLE IF NOT EXISTS \"Patient\" (...)"
```

### Test data not inserted

```bash
# Re-generate test data
cd src && python main.py

# Verify insertion
docker compose -f docker-compose.dev.yml exec db psql -U user -d postgres \
  -c "SELECT COUNT(*) FROM \"Patient\""
```

### dbt docs not generating

```bash
# Ensure schema.yml is well-formed (no YAML syntax errors)
dbt parse

# Regenerate docs
dbt docs generate --no-serve
dbt docs serve  # http://localhost:8000
```

### Models materialized incorrectly

```bash
# Check dbt_project.yml for model config
cat dbt/dbt_project.yml

# Default: table materialization (rebuild entire table on run)
# Staging models should ideally be view (currently table by default)

# To override for staging, add to dbt_project.yml:
# models:
#   chorus_data_engineer_interview:
#     staging:
#       +materialized: view
```

### Docker container exits unexpectedly

```bash
# View logs
docker compose -f docker-compose.dev.yml logs db

# Check exit code (137 = OOM, 1 = error)
docker compose -f docker-compose.dev.yml ps db

# Restart and check health
docker compose -f docker-compose.dev.yml restart
docker compose -f docker-compose.dev.yml ps db  # healthcheck status
```

## Best Practices

### dbt Development
- Run `dbt debug` to verify profile connectivity before running models
- Use `dbt compile` to check SQL syntax without executing
- Use `dbt test` after changes to verify data quality
- Document models in `schema.yml` with column descriptions and tests

### Data Generation
- Run `init_db.py` once to initialize schema (idempotent with IF NOT EXISTS)
- Run `main.py` to generate fresh test data each time (truncates and re-inserts)
- Adjust `NUM_PATIENTS`, `NUM_PRACTITIONERS`, etc. in `main.py` for larger datasets

### Docker
- Use `docker compose ps` to verify container health
- Use `docker compose logs` for debugging
- Use `docker compose down -v` to clean up volumes and reset database

### Kubernetes (Optional)
- pgAdmin accessible via NodePort after `kubectl port-forward`
- PVC persists data across pod restarts
- Secrets store database credentials securely
