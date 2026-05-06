# Chorus Data Engineering Interview

Two separate data domains in one repository:

## 1. Task Modeling (`task_modeling/`)

dbt data modeling for a task tracking system. Focuses on data transformation and mart building.

**See:** [`task_modeling/README.md`](./task_modeling/README.md)

## 2. FHIR Healthcare Pipeline (`tilt-docker-dbt/`)

Tilt-based local development environment for healthcare data with FHIR schema, Docker, Kubernetes, and dbt analytics queries.

**See:** [`tilt-docker-dbt/README.md`](./tilt-docker-dbt/README.md)

## Quick Start

### Task Modeling
```bash
cd task_modeling/dbt
dbt seed && dbt run
```

### FHIR Pipeline
```bash
cd tilt-docker-dbt
tilt up
```

## Repository Structure

```
├── task_modeling/          # Task tracking data modeling
│   ├── dbt/
│   │   ├── models/
│   │   │   ├── staging/    # Sources and staging models
│   │   │   ├── marts/      # Fact and dimension tables
│   │   │   └── seed/       # Reference data
│   │   └── dbt_project.yml
│   └── README.md
│
├── tilt-docker-dbt/        # Healthcare FHIR pipeline
│   ├── Tiltfile
│   ├── docker/
│   ├── fhir/
│   ├── k8s/
│   ├── dbt/
│   ├── src/
│   └── README.md
│
└── .gitignore
```

## Tech Stack

### Task Modeling
- dbt 1.11+
- PostgreSQL

### FHIR Pipeline
- Tilt
- Docker / Docker Compose
- PostgreSQL
- dbt
- Python
- Kubernetes (manifests)
