# Task Modeling

dbt data modeling for task tracking system with recurring task generation, assignment tracking, and status updates.

## Structure

```
task_modeling/
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
│   ├── target/                       # Compiled & executed models (generated)
│   ├── dbt_packages/                 # Installed packages
│   │   ├── dbt_utils/
│   │   └── codegen/
│   ├── dbt_project.yml               # Project config (staging: view, marts: table)
│   ├── packages.yml                  # dbt-utils, codegen
│   ├── package-lock.yml
│   ├── dbt_task_data_model_lineage.png
│   └── profiles.yml                  # (not tracked; create locally)
└── README.md
```

## Quick Start

### 1. Configure dbt Profile

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
      schema: task_tracking
      threads: 4
      keepalives_idle: 0
  target: dev
```

Verify connection:

```bash
cd dbt
dbt debug
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
dbt docs generate
dbt docs serve  # View at http://localhost:8000
```

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

## Development

### Running Specific Models

```bash
# Run only staging
dbt run -m staging

# Run only marts
dbt run -m marts.core

# Run specific model
dbt run -m fct_task_occurrences

# Run + downstream models
dbt run --models +fct_task_occurrences+
```

### Testing

```bash
# Run all tests (unique, not_null constraints from YAML)
dbt test

# Test specific model
dbt test -m stg_people

# Test seed data
dbt test -m people
```

### Debugging

```bash
# Compile SQL (show generated query)
dbt compile --models fct_task_occurrences

# Show model DAG
dbt dag

# Parse for errors
dbt parse
```

### Adding New Models

1. Create SQL file: `dbt/models/marts/core/dim_new_entity.sql`
2. Reference staging: `FROM {{ ref('stg_tasks') }}`
3. Add to `schema.yml` with column descriptions
4. Run: `dbt run -m dim_new_entity`

## Seeds

Reference data loaded from CSV:

### people.csv
```
person_id, person_name, created_at, updated_at
1, Ricardo, 2026-03-01 11:00:00, 2026-03-01 11:00:00
2, Shanaya, 2026-04-01 15:00:00, 2026-04-01 15:00:00
3, Daniel, 2026-05-01 09:00:00, 2026-05-01 09:00:00
```

### tasks.csv
```
task_id, task_name, cadence, start_date, max_occurrences, created_at
1, Task 1, monthly, 2026-01-01, 12, 2026-01-01 00:00:00
2, Task 2, weekly, 2026-01-05, 8, 2026-01-05 00:00:00
3, Task 3, daily, 2026-01-01, 30, 2026-01-01 00:00:00
```

Task occurrences are **generated dynamically** in `fct_task_occurrences` based on cadence and max_occurrences.

## Key Models Explained

### fct_task_occurrences (Fact Table)

Generates all task occurrences based on task recurrence patterns:

```sql
-- Example logic
WITH task_occurrences AS (
  SELECT
    t.task_id,
    t.task_name,
    a.person_id,
    p.person_name,
    GENERATE_SERIES(...) AS occurrence_date,  -- Based on cadence
    ROW_NUMBER() OVER (PARTITION BY t.task_id) AS occurrence_number
  FROM stg_tasks t
  JOIN stg_task_assignments a ON t.task_id = a.task_id
  JOIN stg_people p ON a.person_id = p.person_id
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

## Troubleshooting

### dbt seed fails

```bash
# Check CSV format (no trailing commas, consistent columns)
dbt seed --show

# Drop and reload
dbt seed --drop-existing
```

### Model compilation fails

```bash
# Check staging model SQL references
dbt compile --models staging

# Ensure seeds are loaded first
dbt seed
dbt run --models staging
```

### Tests fail

```bash
# View test output
dbt test --show

# Check unique/not_null constraints in sources.yml
cat dbt/models/staging/sources.yml
```

### Task occurrences not generating

```bash
# Verify tasks & assignments exist
dbt run -m dim_tasks
dbt run -m dim_task_assignment

# Check fct_task_occurrences SQL for GENERATE_SERIES or equivalent
dbt compile -m fct_task_occurrences
```
