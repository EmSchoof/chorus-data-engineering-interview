# Task Modeling
dbt data modeling for task tracking system with recurring task generation, assignment tracking, and status updates.

## Structure
```
task-modeling-docker-dbt/
├── dbt/                               # dbt project root
│   ├── models/
│   │   ├── staging/                  # Staging layer (views, from seeds)
│   │   │   ├── sources.yml           # Seed definitions with tests
│   │   │   ├── stg_people.sql        # People staging model
│   │   │   ├── stg_tasks.sql         # Tasks staging model
│   │   │   ├── stg_task_assignments.sql
│   │   │   └── stg_task_occurance_status.sql
│   │   └── marts/                   # Fact & dimension tables (materialized as tables)
│   │       └── core/
│   │           ├── schema.yml        # Mart model documentation
│   │           ├── dim_people.sql    # Person dimension
│   │           ├── dim_tasks.sql     # Task dimension
│   │           ├── dim_task_assignment.sql
│   │           ├── dim_task_occurance_status.sql
│   │           ├── fct_task_occurrences.sql  # Fact table with generated occurrences
│   │           └── fct_task_occurrence_summary.sql
│   ├── seeds/                        # Reference data (CSV)
│   │   ├── people.csv                # 3 people (Ricardo, Shanaya, Daniel)
│   │   ├── tasks.csv                 # 3 tasks with cadence (monthly, weekly, daily)
│   │   ├── task_assignment.csv       # Task-person assignments
│   │   └── task_occurance_status.csv # Task occurrence status tracking
│   ├── exports/                       # Output data (CSV)
│   │   ├── dim_people.csv                  # output of dim_people model
│   │   ├── dim_tasks.csv                   # output of dim_tasks model
│   │   ├── dim_task_assignment.csv         # output of dim_task_assignment model
│   │   ├── dim_task_occurance_status.csv   # output of dim_task 
│   │   ├── fct_task_occurrences.csv        # output of fct_task_occurrences model
│   │   └── fct_task_occurence_summary.csv  # output of fct_task_occurrence_summary model
│   ├── target/                       # Compiled & executed models (generated)
│   ├── dbt_packages/                 # Installed packages
│   │   ├── dbt_utils/
│   │   └── codegen/
│   ├── dbt_project.yml               # Project config (staging: view, marts: table)
│   ├── packages.yml                  # dbt-utils, codegen
│   ├── package-lock.yml
│   ├── dbt_task_data_model_lineage.png
│   └── profiles.yml                  # (not tracked; create locally)
├── export_to_csv.py                  # Script to export model outputs to CSV
└── README.md
```

## Quick Start

### 1. Configure dbt Profile
**`cd task-modeling-docker-dbt/`**

Create `task-modeling-docker/profiles.yml`:
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
cd dbt && dbt debug
```

### 2. Load Seed Data
```bash
dbt seed
```

This loads CSV data from `seeds/` into the database:
- `people` — 3 sample people
- `tasks` — 3 recurring tasks with different cadences
- `task_assignment` — Task-to-person assignments
- `task_occurance_status` — Status tracking for occurrences

### 3. Install dbt Packages
```bash
dbt deps
```

Installs `dbt_utils` and `codegen`.

### 4. Run Models
```bash
dbt run
```

**Execution order:**
1. **Staging** (materialized as `view`):
   - `stg_people` — Clean people seed data
   - `stg_tasks` — Clean tasks with cadence & recurrence
   - `stg_task_assignments` — Task-person mappings
   - `stg_task_occurance_status` — Status history

2. **Marts** (materialized as `table`):
   - `dim_people` — People dimension
   - `dim_tasks` — Task dimension with recurrence details
   - `dim_task_assignment` — Assignment dimension
   - `dim_task_occurance_status` — Status dimension
   - `fct_task_occurrences` — **Fact table**: Generates task occurrences based on cadence/start_date
   - `fct_task_occurrence_summary` — Aggregated completion rates by person-task

### 5. Test & Document
```bash
# Run data quality tests (source & model tests defined in YAML)
dbt test

# Generate documentation
dbt docs generate && dbt docs serve  # View at http://localhost:8000
```

### 6. Write to CSV (for demo)
**`ipython export_to_csv.py `** → Query data, build models, and output to CSV files

## Data Model

### Seeds (Reference Data)
| Seed | Rows | Purpose |
|------|------|---------|
| `people` | 3 | Sample people (Ricardo, Shanaya, Daniel) |
| `tasks` | 3 | Recurring tasks with cadence (monthly, weekly, daily) |
| `task_assignment` | 3-6 | Task-to-person assignments |
| `task_occurance_status` | 10+ | Status updates for each occurrence |

### Staging Layer
All staging models are `view` materialization and reference seeds:
- `stg_people(person_id, person_name, created_at, updated_at)`
- `stg_tasks(task_id, task_name, cadence, start_date, max_occurrences, created_at)`
- `stg_task_assignments(task_assignment_id, task_id, person_id, assigned_date)`
- `stg_task_occurance_status(task_occurrence_id, status, updated_at)`

### Marts Layer (Tables)

**Dimensions:**
- `dim_people` — person_id, person_name
- `dim_tasks` — task_id, task_name, cadence, start_date, max_occurrences
- `dim_task_assignment` — task_assignment_id, task_id, person_id, assigned_date
- `dim_task_occurance_status` — task_occurrence_id, status, updated_at

**Facts:**
- `fct_task_occurrences` — **Core fact table**. Generates task occurrences dynamically:
  - **task_occurrence_id** (PK): Composite key (task_id + occurrence_number)
  - **occurrence_number**: 1, 2, 3... based on cadence
  - **occurrence_date**: Calculated from start_date + cadence (daily, weekly, monthly)
  - **status**: Current status of the occurrence
  - **is_completed**: Boolean flag (0/1)
  - Denormalized: task_name, person_name for easier querying

- `fct_task_occurrence_summary` — Aggregated by person-task:
  - **person_id, person_name, task_id, task_name**
  - **total_occurrences**: Count
  - **completed_occurrences**: Count
  - **last_scheduled_date**: Latest occurrence date
  - **completion_status**: 'All Completed', 'Overdue', 'In Progress'

### Model Configuration

**dbt_project.yml:**
```yaml
models:
  chorus_data_engineer_interview:
    staging:
      +materialized: view          # Staging as views
      tags: ["staging"]
    marts:
      core:
        +materialized: table       # Marts as tables
        tags: ["marts", "core"]
```

## Key Models Explained

### fct_task_occurrences (Fact Table)
Generates all task occurrences based on task recurrence patterns:
```sql
-- Example logic
WITH task_occurrences AS (
  -- Generate task occurrences based on cadence and max occurrences for each assigned task
  SELECT
    ROW_NUMBER() OVER (ORDER BY t.task_id, t.person_id, n)::integer AS task_occurrence_id,
    t.task_id,
    t.task_name,
    t.person_id,
    t.person_name,
    n AS occurrence_number,
    CASE t.cadence
      WHEN 'daily' THEN t.start_date + (n || ' days')::interval
      WHEN 'weekly' THEN t.start_date + (n * 7 || ' days')::interval
      WHEN 'monthly' THEN t.start_date + (n || ' months')::interval
    END AS occurrence_date,
    CURRENT_TIMESTAMP AS created_at
  FROM assigned_tasks t
  CROSS JOIN LATERAL generate_series(0, t.max_occurrences - 1) AS n
)
```
**Key features:**
- Generates all occurrences up to `max_occurrences`
- Occurrence dates calculated from cadence (daily → 1 day, weekly → 7 days, monthly → 1 month)
- Status merged from `stg_task_occurance_status`
- Denormalized person/task names for analytics

### fct_task_occurrence_summary (Aggregation)
Summarizes completion by person-task pair:
```sql
SELECT
  person_id,
  task_id,
  COUNT(*) AS total_occurrences,
  COUNT(CASE WHEN is_completed = 1 THEN 1 END) AS completed_occurrences,
  MAX(occurrence_date) AS last_scheduled_date,
  CASE 
    WHEN COUNT(*) = COUNT(CASE WHEN is_completed = 1 THEN 1 END) THEN 'All Completed'
    WHEN MAX(occurrence_date) < NOW() THEN 'Overdue'
    ELSE 'In Progress'
  END AS completion_status
FROM fct_task_occurrences
GROUP BY person_id, task_id
```
