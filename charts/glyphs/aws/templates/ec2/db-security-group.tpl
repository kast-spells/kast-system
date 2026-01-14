{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

---
apiVersion: ec2.services.k8s.aws/v1alpha1
kind: SecurityGroup
metadata:
  name: rds-ec2-sg
spec:
  name: rds-ec2-sg
  description: "vpc for ack ec2 rds"
  vpcID: vpc-07226d97b634d8645
  ingressRules:
    - ipProtocol: tcp
      fromPort: 5432
      toPort: 5432
      ipRanges:
        - cidrIP: 10.0.0.0/16
          description: Allow PostgreSQL from VPC
  egressRules:
    - ipProtocol: "-1"
      ipRanges:
        - cidrIP: 0.0.0.0/0
          description: Allow all outbound traffic
  tags:
    - key: Name
      value: routeware-dev-rds-postgres-sg
    - key: ManagedBy
      value: kast-system
    - key: Environment
      value: dev
    - key: Application
      value: routeware
