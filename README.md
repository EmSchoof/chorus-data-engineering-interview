# Chorus Data Engineering Interview
Two separate data domains in one repository:

## 1. Task Modeling (`task_modeling/`)
dbt data modeling for a task tracking system with recurring task generation and completion tracking.

**Highlights:**
- 3-layer architecture: seeds → staging (view) → marts (table)
- Recurring task generation based on cadence (daily, weekly, monthly)
- Task occurrence tracking with status updates
- Sample data: 3 people, 3 tasks, task assignments

**See:** [`task_modeling/README.md`](./task_modeling/README.md)

## 2. FHIR Healthcare Pipeline (`tilt-docker-dbt/`)
Local development environment for healthcare data analytics with FHIR schema, Docker, Kubernetes, PostgreSQL, and dbt.

**Highlights:**
- FHIR database schema: Patient, Practitioner, Encounter, Observation, MedicationRequest
- Multi-layered dbt models: staging → beginner/intermediate/advanced by difficulty
- Docker Compose + Kubernetes manifests
- Tilt-orchestrated workflow
- Faker-generated test data

**See:** [`tilt-docker-dbt/README.md`](./tilt-docker-dbt/README.md)

## Quick Start

### FHIR Pipeline (Docker Required)

#### Tilt + Kubernetes

```bash
# From project root
tilt up

# In Tilt UI, manually trigger:
# 1. init_schema
# 2. seed_db

# Then run dbt
cd tilt-docker-dbt/dbt
dbt run && dbt test
```

## Repository Structure
```
.
├── README.md                          # This file
├── Tiltfile                           # Tilt orchestration (FHIR pipeline)
├── img.png
│
├── task_modeling/                     # Task tracking dbt project
│   ├── dbt/
│   │   ├── seeds/                    # CSV reference data
│   │   │   ├── people.csv
│   │   │   ├── tasks.csv
│   │   │   ├── task_assignment.csv
│   │   │   └── task_occurance_status.csv
│   │   ├── models/
│   │   │   ├── staging/              # Staging layer (view)
│   │   │   │   ├── sources.yml
│   │   │   │   ├── stg_people.sql
│   │   │   │   ├── stg_tasks.sql
│   │   │   │   ├── stg_task_assignments.sql
│   │   │   │   └── stg_task_occurance_status.sql
│   │   │   └── marts/                # Fact & dimension (table)
│   │   │       └── core/
│   │   │           ├── schema.yml
│   │   │           ├── dim_people.sql
│   │   │           ├── dim_tasks.sql
│   │   │           ├── dim_task_assignment.sql
│   │   │           ├── dim_task_occurance_status.sql
│   │   │           ├── fct_task_occurrences.sql
│   │   │           └── fct_task_occurrence_summary.sql
│   │   ├── dbt_project.yml
│   │   ├── packages.yml
│   │   ├── package-lock.yml
│   │   └── target/                   # Compiled/run artifacts
│   ├── README.md
│   └── .gitignore
│
├── tilt-docker-dbt/                   # FHIR healthcare dbt project
│   ├── Dockerfile                     # Root Dockerfile
│   ├── README.md
│   │
│   ├── dbt/
│   │   ├── models/
│   │   │   ├── staging/              # Staging layer
│   │   │   │   ├── schema.yml
│   │   │   │   ├── stg_patients.sql
│   │   │   │   ├── stg_practitioners.sql
│   │   │   │   ├── stg_encounters.sql
│   │   │   │   ├── stg_observations.sql
│   │   │   │   └── stg_medication_requests.sql
│   │   │   ├── 01_beginner/          # Basic queries
│   │   │   ├── 02_intermediate/      # Joins & aggregations
│   │   │   └── 03_advanced/          # Cohort analysis
│   │   ├── dbt_project.yml
│   │   ├── packages.yml
│   │   ├── package-lock.yml
│   │   ├── target/                   # Compiled/run artifacts
│   │   └── dbt_packages/             # Installed dependencies
│   │
│   ├── docker/
│   │   ├── Dockerfile                # Multi-stage Python build
│   │   ├── docker-compose.dev.yml    # PostgreSQL service
│   │   └── .env                      # Credentials (user, password, postgres)
│   │
│   ├── fhir/
│   │   └── ddl/
│   │       └── fhir_database.sql    # FHIR schema DDL
│   │
│   ├── k8s/                          # Kubernetes manifests
│   │   ├── postgres.yaml             # Deployment, Service, PVC
│   │   └── postgres-secret.yaml      # Secret
│   │
│   └── src/
│       ├── main.py                   # Faker test data generator
│       ├── init_db.py                # Schema initialization
│       ├── requirements.txt          # Python dependencies
│       └── __init__.py
│
└── .gitignore
```

## Tech Stack

### Task Modeling
- **dbt** 1.11+ (local development)

### FHIR Healthcare Pipeline
- **dbt** 1.11+
- **Tilt** (orchestration)
- **Kubernetes** (manifests for Postgres)
- **K3s or Docker Desktop** (for Kubernetes)

## Prerequisites

### Task Modeling
- dbt installed: `pip install dbt-postgres`
- PostgreSQL connection configured in `~/.dbt/profiles.yml`

### FHIR Healthcare Pipeline
- Docker + Docker Compose (for automated setup)
- Or: PostgreSQL + Python + dbt (for manual setup)
- Tilt (optional, for automated orchestration)

## Workflows

### Task Modeling

**Development Loop:**
```bash
cd task_modeling/dbt

# Make changes to models
# vim dbt/models/marts/core/dim_new_entity.sql

# Run and test
dbt run
dbt test

# Generate docs
dbt docs generate
dbt docs serve
```

**Run Specific Models:**
```bash
dbt run -m staging        # Run only staging
dbt run -m marts.core     # Run only marts
dbt run -m +dim_tasks+    # Model + upstream/downstream
```

### FHIR Healthcare Pipeline

**Using Docker Compose + Manual Init:**
```bash
cd tilt-docker-dbt/docker
docker compose -f docker-compose.dev.yml up -d

cd ../src
psql -h 127.0.0.1 -U user -d postgres -f ../fhir/ddl/fhir_database.sql
python main.py

cd ../dbt
dbt run
dbt test
```

**Using Tilt (Automated):**
```bash
tilt up

# Trigger in UI:
# 1. init_schema (manual trigger)
# 2. seed_db (manual trigger)

cd tilt-docker-dbt/dbt
dbt run
```

**Run Specific dbt Models:**
```bash
cd tilt-docker-dbt/dbt

dbt run -m staging                  # Staging models only
dbt run -m 01_beginner              # Beginner queries
dbt run -m 02_intermediate          # Intermediate queries
dbt run -m +dim_all_active_patients+  # Model + dependencies
```

## Development Notes

### dbt Profile Configuration

Both projects use the same dbt profile name: `chorus_data_engineer_interview`

Create `~/.dbt/profiles.yml`:

```yaml
chorus_data_engineer_interview:
  outputs:
    dev:
      type: postgres
      host: localhost
      user: <_user_>                   # or postgres for local
      password: <_password_>           # your password
      port: 5432
  target: dev
```

Verify with:
```bash
cd task_modeling/dbt
dbt debug

cd tilt-docker-dbt/dbt
dbt debug
```

### Tilt Setup (Optional)
`Tiltfile` at project root orchestrates the FHIR pipeline:

1. **Deploys Kubernetes manifests** — PostgreSQL + pgAdmin
2. **init_schema** — Runs `init_db.py` to create FHIR schema
3. **seed_db** — Runs `main.py` to generate fake test data

## Testing & Documentation

### Run Tests
```bash
# All tests
dbt test

# Specific model
dbt test -m stg_people

# Show test results
dbt test --show
```

### Generate Documentation
```bash
dbt docs generate && dbt docs serve  # http://localhost:8000
```

## Next Steps
- **Task Modeling**: Extend marts with additional business logic, add incremental models
- **FHIR Pipeline**: Deploy to cloud (AWS RDS + dbt Cloud), add CI/CD via GitHub Actions
- **Both**: Set up monitoring, data quality checks, automated testing
