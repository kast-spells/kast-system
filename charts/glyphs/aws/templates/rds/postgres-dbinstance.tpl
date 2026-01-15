{{/*kast - Kubernetes arcane spelling technology
Copyright (C) 2026  kazapeke@gmail.com
Licensed under the GNU GPL v3. See LICENSE file for details.
*/}}

---
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBInstance
metadata:
  name: postgres-dev-instance
spec:
  dbInstanceIdentifier: postgres-dev-instance
  dbInstanceClass: db.t3.micro
  engine: postgres
  engineVersion: "15.4"

  # Storage configuration
  allocatedStorage: 20
  storageType: gp3
  storageEncrypted: true

  # Master credentials
  masterUsername: postgres
  masterUserPassword:
    namespace: database
    name: rds-postgres-master
    key: password

  # Database name
  dbName: routeware_dev

  # Networking
  dbSubnetGroupName: rwg-dev-gen-us-west-1
  dbParameterGroupName: postgres-dev-params
  vpcSecurityGroupIDs:
    - sg-01692d6e6ddb9a72d
  publiclyAccessible: false
  port: 5432

  # High availability
  multiAZ: false
  availabilityZone: us-west-1a

  # Backup configuration
  backupRetentionPeriod: 7
  preferredBackupWindow: "03:00-04:00"
  preferredMaintenanceWindow: "sun:04:00-sun:05:00"
  copyTagsToSnapshot: true

  # Updates and maintenance
  autoMinorVersionUpgrade: true
  deletionProtection: false

  # Tags
  tags:
    - key: Name
      value: postgres-dev-instance
    - key: ManagedBy
      value: kast-system
    - key: Environment
      value: dev
    - key: Application
      value: routeware
    - key: Engine
      value: postgresql
