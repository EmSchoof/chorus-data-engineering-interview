# Load Kubernetes manifests
k8s_yaml([
    './k8s/postgres-secret.yaml',
    './k8s/postgres.yaml'
])

k8s_resource(
    'db',
    objects=["db-pvc"],
    port_forwards=['5432:5432', '5050:80'],
    links=['http://localhost:5050/']
)

local_resource(
    "init_schema",
    "cd src && python init_db.py",
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['db'],
    env={
        'POSTGRES_USER': 'user',
        'POSTGRES_PASSWORD': 'password',
        'POSTGRES_HOST': 'localhost',
        'POSTGRES_PORT': '5432',
        'POSTGRES_DB': 'postgres',
        'DDL_PATH': '../fhir/ddl/fhir_database.sql'
    }
)

local_resource(
    "seed_db",
    "cd src && python main.py",
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['init_schema'],
    env={
        'POSTGRES_HOST': 'localhost',
        'POSTGRES_PORT': '5432',
        'POSTGRES_USER': 'user',
        'POSTGRES_PASSWORD': 'password',
        'POSTGRES_DB': 'postgres'
    }
)
