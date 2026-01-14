{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

---
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: ec2-rds-access-role
spec:
  name: ec2-rds-access-role
  description: "IAM Role for EC2 instances to access RDS"
  assumeRolePolicyDocument: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  policies:
    - arn:aws:iam::123456789012:policy/ec2-rds-policy
  tags:
    - key: Name
      value: ec2-rds-access-role
    - key: ManagedBy
      value: kast-system
    - key: Environment
      value: dev
    - key: Application
      value: routeware
