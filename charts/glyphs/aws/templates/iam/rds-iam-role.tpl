{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

---
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: rds-enhanced-monitoring-role
spec:
  name: rds-enhanced-monitoring-role
  description: "IAM Role for RDS Enhanced Monitoring"
  assumeRolePolicyDocument: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "monitoring.rds.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  policies:
    - arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole
    - arn:aws:iam::123456789012:policy/rds-access-policy
  tags:
    - key: Name
      value: rds-enhanced-monitoring-role
    - key: ManagedBy
      value: kast-system
    - key: Environment
      value: dev
    - key: Application
      value: routeware
