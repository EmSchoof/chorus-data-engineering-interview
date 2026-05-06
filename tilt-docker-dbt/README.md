# FHIR Healthcare Data Pipeline

Tilt-based local development environment for healthcare data pipeline with FHIR schema, PostgreSQL, Docker, and dbt analytics.

## Structure

```
tilt-docker-dbt/
├── Tiltfile                # Local dev orchestration
├── docker/                 # Docker configuration
│   ├── Dockerfile
│   ├── docker-compose.dev.yml
│   └── .env
├── fhir/                   # FHIR database schema (DDL)
├── k8s/                    # Kubernetes manifests
│   ├── postgres.yaml
│   └── postgres-secret.yaml
├── dbt/                    # dbt analytics queries
│   ├── models/
│   │   └── queries/        # SQL queries organized by difficulty
│   │       ├── 01_beginner/
│   │       ├── 02_intermediate/
│   │       └── 03_advanced/
│   ├── dbt_project.yml
│   ├── packages.yml
│   └── package-lock.yml
└── src/                    # Python initialization scripts
    ├── init_db.py          # Database initialization
    ├── init_task_tracking.py
    ├── main.py
    └── requirements.txt
```

## Setup

### Local Dev with Tilt

```bash
cd tilt-docker-dbt
tilt up
```

### Docker Compose

```bash
cd tilt-docker-dbt/docker
docker compose -f docker-compose.dev.yml up
```

### dbt Queries

```bash
cd tilt-docker-dbt/dbt
dbt run
dbt test
```

## Key Components

- **FHIR Schema**: Patient, Practitioner, Encounter, Observation, MedicationRequest
- **dbt Queries**: 
  - Beginner: Basic data retrieval
  - Intermediate: Joins and aggregations
  - Advanced: Complex analysis
- **Tilt**: Automated local development workflow
