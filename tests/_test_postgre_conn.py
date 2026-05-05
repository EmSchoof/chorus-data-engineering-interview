import psycopg2

# Database Connection Settings
DB_CONFIG = {
    "dbname": "postgres",
    "user": "user",
    "password": "password",
    "host": "localhost",
    "port": "5432"
}
# Connect to PostgreSQL
conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()
cursor.execute("SELECT current_database(), current_user;")
print(cursor.fetchone()[0])

print("✅ Local Connection to PostgreSQL Successful!")

# Close connection
conn.commit()
cursor.close()
conn.close()