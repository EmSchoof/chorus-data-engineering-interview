# Load Kubernetes manifests
k8s_yaml([
    './tilt-docker-dbt/k8s/postgres-secret.yaml',
    './tilt-docker-dbt/k8s/postgres.yaml'
])

k8s_resource(
    'db',
    objects=["db-pvc"],
    port_forwards=['5432:5432', '5050:80'],
    links=['http://localhost:5050/']
)

local_resource(
    "init_schema",
    "cd tilt-docker-dbt/src && pip install -q -r requirements.txt && python init_db.py",
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['db']
)

local_resource(
    "seed_db",
    "cd tilt-docker-dbt/src && pip install -q -r requirements.txt && python main.py",
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['init_schema']
)
