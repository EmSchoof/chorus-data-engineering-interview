# Chorus Data Engineering Interview
Two separate data domains in one repository:

## 1. Task Modeling (`task_modeling/`)
dbt data modeling for a task tracking system with recurring task generation and completion tracking.

**Highlights:**
- 3-layer architecture: seeds → staging (view) → marts (table)
- Recurring task generation based on cadence (daily, weekly, monthly)
- Task occurrence tracking with status updates
- Sample data: 3 people, 3 tasks, task assignments

**See:** [`task_modeling/README.md`](task-modeling-docker-dbt/README.md)

## 2. FHIR Healthcare Pipeline (`tilt-docker-dbt/`)
Local development environment for healthcare data analytics with FHIR schema, Docker, Kubernetes, PostgreSQL, and dbt.

**Highlights:**
- FHIR database schema: Patient, Practitioner, Encounter, Observation, MedicationRequest
- Multi-layered dbt models: staging → beginner/intermediate/advanced by difficulty
- Docker Compose + Kubernetes manifests
- Tilt-orchestrated workflow
- Faker-generated test data

**See:** [`tilt-docker-dbt/README.md`](./tilt-docker-dbt/README.md)

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
      user: <_user_> 
      password: <_password_>          
      port: 5432
  target: dev
```

Verify with:
```bash
cd task-modeling-docker-dbt/dbt && dbt debug

cd tilt-docker-dbt/dbt && dbt debug
```
