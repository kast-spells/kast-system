{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

---
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBSubnetGroup
metadata:
  name: rwg-dev-gen-us-west-1
spec:
  name: rwg-dev-gen-us-west-1
  description: "Subnet group for RDS PostgreSQL in development"
  subnetIDs:
    - subnet-020c291c17b70abb2
    - subnet-05099042d609b034a
    - subnet-0e14f81fc7072d83c
  tags:
    - key: Name
      value: routeware-dev-db-subnet-group
    - key: ManagedBy
      value: kast-system
    - key: Environment
      value: dev
    - key: Application
      value: routeware
