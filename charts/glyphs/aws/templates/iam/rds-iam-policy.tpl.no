{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

---
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Policy
metadata:
  name: rds-access-policy
spec:
  name: rds-access-policy
  description: "IAM Policy for RDS access to secrets and monitoring"
  policyDocument: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
          ],
          "Resource": "arn:aws:secretsmanager:us-west-1:123456789012:secret:*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ],
          "Resource": "arn:aws:logs:us-west-1:123456789012:log-group:/aws/rds/*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "kms:Decrypt",
            "kms:DescribeKey"
          ],
          "Resource": "arn:aws:kms:us-west-1:123456789012:key/*"
        }
      ]
    }
  tags:
    - key: Name
      value: rds-access-policy
    - key: ManagedBy
      value: kast-system
    - key: Environment
      value: dev
    - key: Application
      value: routeware
