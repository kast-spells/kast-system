{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

---
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Policy
metadata:
  name: ec2-rds-policy
spec:
  name: ec2-rds-policy
  description: "IAM Policy for EC2 instances to access RDS"
  policyDocument: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "rds:DescribeDBInstances",
            "rds:DescribeDBClusters",
            "rds:Connect"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeInstances",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets"
          ],
          "Resource": "*"
        }
      ]
    }
  tags:
    - key: Name
      value: ec2-rds-policy
    - key: ManagedBy
      value: kast-system
    - key: Environment
      value: dev
    - key: Application
      value: routeware
