# Task Modeling

dbt data modeling for task tracking system.

## Structure

```
task_modeling/dbt/
├── models/
│   ├── staging/        # Source definitions and staging models
│   │   ├── sources.yml # Task tracking source tables (Task, Person, TaskAssignment, TaskOccurrenceStatus)
│   │   ├── stg_people.sql
│   │   ├── stg_tasks.sql
│   │   ├── stg_task_assignments.sql
│   │   └── stg_task_occurrences.sql
│   ├── marts/          # Fact and dimension tables
│   │   └── core/
│   │       ├── dim_people.sql
│   │       ├── dim_tasks.sql
│   │       ├── fct_task_occurrences.sql
│   │       └── bridge_task_occurrence_assignments.sql
│   ├── seed/           # Reference data
│   │   ├── people.csv
│   │   ├── tasks.csv
│   │   └── task_assignment.csv
│   └── macros/         # Custom macros
├── dbt_project.yml
├── packages.yml
└── package-lock.yml
```

## Setup

```bash
cd task_modeling/dbt

# Load seed data
dbt seed

# Run models
dbt run

# Test
dbt test
```

## Key Models

- **Staging**: Clean source data from task_tracking schema
- **Marts**: 
  - `fct_task_occurrences` — Task occurrence facts with status
  - `bridge_task_occurrence_assignments` — Summary by person/task
  - `dim_people`, `dim_tasks` — Dimensions
