# FHIR Healthcare Data Pipeline

Tilt-orchestrated local development environment for healthcare data analytics with FHIR schema, PostgreSQL, Docker, Kubernetes, and dbt.

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
├── docker/                            # Docker Compose setup (optional, standalone)
│   ├── Dockerfile                     # Multi-stage Python build (data gen)
│   ├── docker-compose.dev.yml         # PostgreSQL service (alternative to Tilt)
│   └── .env                           # Database credentials (user, password, db)
├── fhir/
│   └── ddl/
│       └── fhir_database.sql          # FHIR schema creation script
├── k8s/                               # Kubernetes manifests (used by Tilt)
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

## Quick Start (Tilt + Kubernetes)

Tilt orchestrates PostgreSQL deployment via Kubernetes manifests and automates schema initialization and data seeding.

### Prerequisites

- **Tilt** installed: https://docs.tilt.dev/install.html
- **Docker** installed (Docker Desktop with Kubernetes, or separate K3s/Kubernetes cluster)
- **kubectl** available (for K8s cluster access)

### 1. Start Tilt
From project root (where `Tiltfile` is located):
```bash
tilt up
```

This will:
1. Load K8s manifests (`postgres.yaml`, `postgres-secret.yaml`)
2. Deploy PostgreSQL 16 + pgAdmin to your K8s cluster
3. Set up port forwards: `5432:5432` (PostgreSQL), `5050:80` (pgAdmin)
4. Create the `db` resource (tracked in Tilt UI)

**Tilt UI** opens at `http://localhost:10350/`.

### 2. Initialize FHIR Schema and Generate Test Data
```bash
ipython tilt-docker-dbt/src/main.py
```
This will trigger the following in Tilt UI:

1. Executes `init_db.py`, which: 
- Runs `init_schema` resource
- Installs Python dependencies (`psycopg2`, `faker`, `python-dotenv`)
- Reads `fhir/ddl/fhir_database.sql`
- Runs DDL with `CREATE TABLE IF NOT EXISTS` (idempotent)
- Creates all FHIR tables: Patient, Practitioner, Encounter, Observation, MedicationRequest

Check logs in Tilt UI for `✅ Schema initialized successfully!`

2. Creates `seed_db` resource in PostGreSQL, which generates:
- 10 patients
- 5 practitioners
- 15 encounters
- 20 observations
- 10 medication requests

Check logs in Tilt UI for `✅ Test data inserted successfully!`

### 3. Configure dbt Profile

Create `~/.dbt/profiles.yml`:
```yaml
chorus_data_engineer_interview:
  outputs:
    dev:
      type: postgres
      host: localhost
      user: <_user_>
      password: <_password_>
      port: 5432
  target: dev
```

Verify connection:
```bash
cd tilt-docker-dbt/dbt
dbt debug
```

### 5. Run dbt

```bash
cd tilt-docker-dbt/dbt

# Install dependencies and run models
dbt deps && dbt run 

# Test data quality (source tests + model tests)
dbt test

# Generate documentation
dbt docs generate && dbt docs serve  # View at http://localhost:8000
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

## Tilt Workflow

### Tilt Resources
```
Tiltfile
├── k8s_yaml()
│   ├── postgres-secret.yaml     # Kubernetes Secret (user, password)
│   └── postgres.yaml            # PostgreSQL 16 Deployment + pgAdmin
│
├── k8s_resource('db')           # Tracks K8s deployment
│   ├── Port forwards: 5432:5432 (postgres), 5050:80 (pgAdmin)
│   └── Links: http://localhost:5050/ (pgAdmin UI)
│
├── local_resource('init_schema')    # Manual trigger
│   ├── Command: pip install -q -r requirements.txt && python init_db.py
│   ├── Resource dep: db (waits for db to be ready)
│   └── Trigger mode: MANUAL (click in UI to run)
│
└── local_resource('seed_db')        # Manual trigger
    ├── Command: pip install -q -r requirements.txt && python main.py
    ├── Resource dep: init_schema (waits for schema)
    └── Trigger mode: MANUAL (click in UI to run)
```

### CLI Trigger Workflow
1. **`tilt up`** → Deploys K8s resources (db)
2. **`ipython tilt-docker-dbt/src/main.py `** → Triggers `init_schema` (creates tables) → Triggers `seed_db` (inserts test data)
4. **`cd ../dbt/ && dbt run`** → Query data and build models

### Checking Resource Status in Tilt UI
- **Green** — Resource is healthy
- **Yellow** — In progress
- **Red** — Error (check logs)
- **Gray** — Pending (waiting for dependency)

## Kubernetes Access (Via Tilt)
Tilt manages port forwarding automatically:

**PostgreSQL:**
```bash
# Connect directly (port-forward active)
psql -h localhost -U user -d postgres
# Password: password
```

**pgAdmin (UI):**
```bash
# Visit http://localhost:5050/
# Login: fake@gmail.com / password (from K8s secret)
```

## Stopping & Cleanup

```bash
# Stop Tilt (keeps K8s resources running)
tilt down

# Stop all resources and delete volumes (full reset)
kubectl delete all --all
kubectl delete pvc --all

# Or use Docker Compose if running standalone
cd docker
docker compose -f docker-compose.dev.yml down -v
```
