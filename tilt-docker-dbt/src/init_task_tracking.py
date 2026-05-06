import psycopg2
from dotenv import load_dotenv
import os
from datetime import datetime, timedelta

load_dotenv()

DB_CONFIG = {
    "dbname": os.getenv("POSTGRES_DB"),
    "user": os.getenv("POSTGRES_USER"),
    "password": os.getenv("POSTGRES_PASSWORD"),
    "host": os.getenv("POSTGRES_HOST"),
    "port": os.getenv("POSTGRES_PORT")
}

conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()

# Create Task table
cursor.execute("""
    CREATE TABLE IF NOT EXISTS "Task" (
        task_id SERIAL PRIMARY KEY,
        task_name VARCHAR(255) NOT NULL,
        cadence VARCHAR(20) NOT NULL CHECK (cadence IN ('daily', 'weekly', 'monthly')),
        max_occurrences INT NOT NULL,
        start_date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
""")

# Create Person table
cursor.execute("""
    CREATE TABLE IF NOT EXISTS "Person" (
        person_id SERIAL PRIMARY KEY,
        person_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
""")

# Create TaskAssignment table
cursor.execute("""
    CREATE TABLE IF NOT EXISTS "TaskAssignment" (
        assignment_id SERIAL PRIMARY KEY,
        task_id INT NOT NULL REFERENCES "Task"(task_id),
        person_id INT NOT NULL REFERENCES "Person"(person_id),
        assigned_date DATE DEFAULT CURRENT_DATE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(task_id, person_id)
    )
""")

# Create TaskOccurrenceStatus table
cursor.execute("""
    CREATE TABLE IF NOT EXISTS "TaskOccurrenceStatus" (
        task_occurrence_id UUID PRIMARY KEY,
        status VARCHAR(50) NOT NULL CHECK (status IN ('Not Started', 'In Progress', 'Completed')),
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
""")

# Insert sample data
# Insert People
cursor.execute("DELETE FROM \"Person\"")
cursor.execute("""
    INSERT INTO "Person" (person_name) VALUES
    ('Alice Johnson'),
    ('Bob Smith'),
    ('Carol White')
""")

# Insert Tasks
cursor.execute("DELETE FROM \"Task\"")
cursor.execute("""
    INSERT INTO "Task" (task_name, cadence, max_occurrences, start_date) VALUES
    ('Monthly Review', 'monthly', 12, '2026-01-01'),
    ('Quarterly Report', 'monthly', 1, '2026-01-15'),
    ('Daily Standup', 'daily', 30, '2026-01-01')
""")

# Insert TaskAssignments
cursor.execute("DELETE FROM \"TaskAssignment\"")
cursor.execute("""
    INSERT INTO "TaskAssignment" (task_id, person_id, assigned_date) VALUES
    (1, 1, '2026-01-01'),
    (1, 2, '2026-01-01'),
    (2, 3, '2026-01-15'),
    (3, 1, '2026-01-01'),
    (3, 2, '2026-01-01'),
    (3, 3, '2026-01-01')
""")

conn.commit()
cursor.close()
conn.close()
print("✅ Task tracking tables created and seeded successfully!")
