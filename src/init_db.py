import psycopg2
import os

DB_CONFIG = {
    "dbname": os.getenv("POSTGRES_DB", "postgres"),
    "user": os.getenv("POSTGRES_USER", "user"),
    "password": os.getenv("POSTGRES_PASSWORD", "password"),
    "host": os.getenv("POSTGRES_HOST", "localhost"),
    "port": os.getenv("POSTGRES_PORT", "5432")
}

conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()

ddl_path = os.getenv("DDL_PATH", "fhir/ddl/fhir_database.sql")
with open(ddl_path, 'r') as f:
    ddl = f.read()
    # Add IF NOT EXISTS to each CREATE TABLE
    ddl = ddl.replace('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS')
    cursor.execute(ddl)

conn.commit()
cursor.close()
conn.close()
print("✅ Schema initialized successfully!")
