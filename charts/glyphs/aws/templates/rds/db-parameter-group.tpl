{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

---
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBParameterGroup
metadata:
  name: postgres-dev-params
spec:
  name: postgres-dev-params
  description: "Parameter group for PostgreSQL 15 development instances"
  family: postgres15

  parameterOverrides:
    max_connections: "200"
    shared_buffers: "256MB"
    effective_cache_size: "1GB"
    maintenance_work_mem: "64MB"
    checkpoint_completion_target: "0.9"
    wal_buffers: "16MB"
    default_statistics_target: "100"
    random_page_cost: "1.1"
    effective_io_concurrency: "200"
    work_mem: "4MB"
    min_wal_size: "1GB"
    max_wal_size: "4GB"

  tags:
    - key: Name
      value: postgres-dev-params
    - key: ManagedBy
      value: kast-system
    - key: Environment
      value: dev
    - key: Application
      value: routeware
    - key: Family
      value: postgres15