# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.3.2] - 2025-12-22

### Features

- add chapter-specific post-provisioning policies and secret consumption (covenant/templates/covenant.yaml) [`fd4d85e`] 
- add Vault policy for post-provisioning ServiceAccount and consume keycloak-access secret from Vault into chapter namespace (covenant/templates/covenant.yaml) [`5254bd5`] 
- add common name template support (librarian) [`a2cef02`] 
- add podSecurityContext filter for filtered securityContext with only pod-level fields feat(glyphs/summon/templates/workload/_container.tpl): update resources section to use podSecurityContext feat(glyphs/summon/templates/workload/_podSpec.tpl): add podSecurityContext filter and update common.podSpec feat(glyphs/summon/templates/workload/daemonset/daemonset.tpl): add daemonset template feat(glyphs/summon/templates/workload/deployment/deployment.tpl): add deployment template feat(glyphs/summon/templates/workload/statefulset/statefulSet.tpl): add statefulset template feat(summon/examples/security-context-separation.yaml): add example security context separation docs: update security context separation example perf: improve security context separation example performance (glyphs/summon/templates/workload) [`39e83f1`] 
- add example iam-policy and iam-role configurations (aws) [`3f507a4`] 
- add iam-policy template and example (charts/glyphs/aws) [`d9068c5`] 
- add AWS IAM policy and role templates (charts/glyphs/aws) [`0582087`] 
- add aws and gcp secret path helpers (charts/glyphs/external-secrets/templates) [`e919c6b`] 
- update external secret template to use extract key (external-secrets) [`c539010`] 
- update yaml templates for external-secret and secret-store (external-secrets/templates) [`0aae41f`] 
- update api version to v1beta1 in external-secret and secret-store templates (external-secrets) [`87c125d`] 
- rename externalsecrets to external-secrets (glyphs/external-secrets) [`6097c76`] 
- Update chapter ownership hook to use argocd.argoproj.io/hook-delete-policy: HookSucceeded (librarian/templates/chapter-ownership-hook.yaml) [`a28c1cd`] 
- remove tracking-id annotation to enable ownerReference-based hierarchy (librarian) [`e6c70ad`] 
- add chapter ownership hook functionality (librarian/templates) [`0955884`] 
- add annotations for chapter configmap and owner references (kast.yaml) [`13ba11a`] 
- add chapter ownership hook and RBAC resources for chapter ownership management (kast) [`feddcdc`] 
- add chapter configmap and ownership to spells  [`5bd2665`] 
- add support for secret and configmap volumes (charts) [`b38f8f6`] 
- add comprehensive port handling and multi-service support (summon) [`b661529`] 
- bump version to 1.8.0 and update changelog  [`998dc57`] 
- add security context to workload container template (charts/glyphs/summon/templates/workload) [`5e0df5f`] 
- add runtime class support to pod spec templates (glyphs/summon/templates) [`ff36ac3`] 
- update gateway and virtualService templates (charts/glyphs/istio/templates) [`407a2d5`] 
- add finops labels for cost allocation and tracking (summon) [`f7a3171`] 
- add common name template and update kast.yaml (librarian) [`e9904ab`] 
- add AWS ClusterIssuer with IRSA Autodiscovery example (charts/glyphs/certManager) [`b6d70eb`] 

### Bug Fixes

- improve namePrefix and nameSuffix logic (librarian) [`bee84f7`] 
- update iam-policy.tpl to conform to api conventions (glyphs/aws) [`98a7449`] 
- update iam-role.yaml to use correct secret-manager label (charts/glyphs/aws/examples) [`508cb43`] 
- update iam-role labels to use resources (charts/glyphs/aws) [`49ad940`] 
- uncomment ttlSecondsAfterFinished for proper job cleanup (librarian) [`00f17bd`] 
- fix chapter ownership hook script (ownership-hook) [`73c7555`] 
- update kubectl image to alpine/k8s (librarian/templates/chapter-ownership-hook.yaml) [`f5fa01a`] 
- update namePrefix and nameSuffix logic (kast.yaml) [`b9de205`] 

### Refactoring

- remove uid from configmap metadata (kast) [`aa340f2`] 
- simplify values.yaml for summon chart (charts) [`905bc85`] 

### Chore

- bump version to v1.6.3  [`ad29070`] 
- bump version to v1.6.2  [`3ab7167`] 
- bump version to v1.9.1  [`19f7453`] 
- bump version to v1.6.1  [`54c92f0`] 
- bump version to v1.6.0  [`80f4c3f`] 
- bump version to v1.5.0  [`1b9b4a3`] 
- bump version to v1.4.1  [`b40cb63`] 
- bump version to v1.4.0  [`191be06`] 
- bump version to v1.9.0  [`5b1e074`] 
- bump version to v1.8.0  [`1865733`] 
- bump version to v1.7.0  [`c95e379`] 
- bump version to v1.6.0  [`25ff64f`] 
- bump version to v1.7.0  [`0d2b818`] 
- bump version to v1.2.0  [`9ba8c9e`] 
- bump version to v1.5.0  [`d3d5d08`] 
- bump version to v1.3.1  [`8b0b871`] 
- bump version to v1.3.0  [`0a9ead2`] 
- bump version to v1.4.0  [`8067647`] 
- bump version to v1.6.0  [`4741d46`] 
- bump version to v1.3.0  [`5b36048`] 
- bump version to v1.5.0  [`599ae16`] 
- bump version to v1.1.0  [`3aa388e`] 
- bump version to v1.1.0  [`b915594`] 

### Other

- rollback to version 1.2.4 removing chapter ownership hooks (librarian) [`abbd346`] 
- Merge pull request #32 from kast-spells/feature/aws-roles  [`ee2ae03`]  (#32)
- Merge pull request #31 from kast-spells/hotfix/typo  [`53ceaef`]  (#31)
- Merge pull request #30 from kast-spells/feature/aws-glyph  [`2099272`]  (#30)
- Merge pull request #29 from kast-spells/feature/aws-iam  [`97c4754`]  (#29)
- Merge pull request #28 from kast-spells/feature/externalsecrets  [`efac554`]  (#28)
- Implements provider-agnostic ExternalSecrets support (vault/aws/gcp) with   dynamic SecretStore discovery via runic indexer.  [`acc36d2`] 
- comentando el fit  [`ef59b16`] 
- proveyendo el fit  [`dc6ad4a`] 
- errors shenanigans  [`82b9c05`] 
- shenanigans  [`a103204`] 
- shenanigans  [`9bdecc4`] 
- external secrets  [`214d629`] 


## [v1.6.3] - 2025-12-12

### Bug Fixes

- uncomment ttlSecondsAfterFinished for proper job cleanup (librarian) [`00f17bd`] 


## [v1.6.2] - 2025-12-12

### Features

- remove tracking-id annotation to enable ownerReference-based hierarchy (librarian) [`e6c70ad`] 
- add chapter ownership hook functionality (librarian/templates) [`0955884`] 
- add annotations for chapter configmap and owner references (kast.yaml) [`13ba11a`] 

### Chore

- bump version to v1.9.1  [`19f7453`] 


## [v1.9.1] - 2025-12-12

### Features

- add chapter ownership hook functionality (librarian/templates) [`0955884`] 
- add annotations for chapter configmap and owner references (kast.yaml) [`13ba11a`] 
- add chapter ownership hook and RBAC resources for chapter ownership management (kast) [`feddcdc`] 
- add chapter configmap and ownership to spells  [`5bd2665`] 

### Bug Fixes

- fix chapter ownership hook script (ownership-hook) [`73c7555`] 
- update kubectl image to alpine/k8s (librarian/templates/chapter-ownership-hook.yaml) [`f5fa01a`] 

### Refactoring

- remove uid from configmap metadata (kast) [`aa340f2`] 

### Chore

- bump version to v1.6.1  [`54c92f0`] 
- bump version to v1.6.0  [`80f4c3f`] 
- bump version to v1.5.0  [`1b9b4a3`] 
- bump version to v1.4.1  [`b40cb63`] 
- bump version to v1.4.0  [`191be06`] 


## [v1.6.1] - 2025-12-11

### Bug Fixes

- fix chapter ownership hook script (ownership-hook) [`73c7555`] 


## [v1.6.0] - 2025-12-11

### Bug Fixes

- update kubectl image to alpine/k8s (librarian/templates/chapter-ownership-hook.yaml) [`f5fa01a`] 


## [v1.5.0] - 2025-12-11

### Features

- add chapter ownership hook and RBAC resources for chapter ownership management (kast) [`feddcdc`] 


## [v1.4.1] - 2025-12-11

### Refactoring

- remove uid from configmap metadata (kast) [`aa340f2`] 


## [v1.4.0] - 2025-12-11

### Features

- add chapter configmap and ownership to spells  [`5bd2665`] 
- add support for secret and configmap volumes (charts) [`b38f8f6`] 
- add comprehensive port handling and multi-service support (summon) [`b661529`] 
- bump version to 1.8.0 and update changelog  [`998dc57`] 
- add security context to workload container template (charts/glyphs/summon/templates/workload) [`5e0df5f`] 
- add runtime class support to pod spec templates (glyphs/summon/templates) [`ff36ac3`] 
- update gateway and virtualService templates (charts/glyphs/istio/templates) [`407a2d5`] 
- add finops labels for cost allocation and tracking (summon) [`f7a3171`] 

### Refactoring

- simplify values.yaml for summon chart (charts) [`905bc85`] 

### Chore

- bump version to v1.9.0  [`5b1e074`] 
- bump version to v1.8.0  [`1865733`] 
- bump version to v1.7.0  [`c95e379`] 
- bump version to v1.6.0  [`25ff64f`] 
- bump version to v1.7.0  [`0d2b818`] 
- bump version to v1.2.0  [`9ba8c9e`] 
- bump version to v1.5.0  [`d3d5d08`] 


## [v1.9.0] - 2025-12-10

### Features

- add support for secret and configmap volumes (charts) [`b38f8f6`] 


## [v1.8.0] - 2025-12-07

### Features

- add comprehensive port handling and multi-service support (summon) [`b661529`] 
- bump version to 1.8.0 and update changelog  [`998dc57`] 
- add security context to workload container template (charts/glyphs/summon/templates/workload) [`5e0df5f`] 


## [v1.8.0] - 2025-12-07

### Features

- add security context to workload container template (charts/glyphs/summon/templates/workload) [`5e0df5f`] 


## [v1.7.0] - 2025-12-06

### Features

- add runtime class support to pod spec templates (glyphs/summon/templates) [`ff36ac3`] 


## [v1.6.0] - 2025-12-04

### Features

- update gateway and virtualService templates (charts/glyphs/istio/templates) [`407a2d5`] 

### Chore

- bump version to v1.7.0  [`0d2b818`] 
- bump version to v1.2.0  [`9ba8c9e`] 


## [v1.7.0] - 2025-12-04

### Features

- update gateway and virtualService templates (charts/glyphs/istio/templates) [`407a2d5`] 
- add finops labels for cost allocation and tracking (summon) [`f7a3171`] 
- add common name template and update kast.yaml (librarian) [`e9904ab`] 

### Bug Fixes

- update namePrefix and nameSuffix logic (kast.yaml) [`b9de205`] 

### Refactoring

- simplify values.yaml for summon chart (charts) [`905bc85`] 

### Chore

- bump version to v1.2.0  [`9ba8c9e`] 
- bump version to v1.5.0  [`d3d5d08`] 
- bump version to v1.3.1  [`8b0b871`] 
- bump version to v1.3.0  [`0a9ead2`] 
- bump version to v1.4.0  [`8067647`] 


## [v1.2.0] - 2025-12-04

### Features

- update gateway and virtualService templates (charts/glyphs/istio/templates) [`407a2d5`] 
- add finops labels for cost allocation and tracking (summon) [`f7a3171`] 
- add common name template and update kast.yaml (librarian) [`e9904ab`] 
- add AWS ClusterIssuer with IRSA Autodiscovery example (charts/glyphs/certManager) [`b6d70eb`] 

### Bug Fixes

- update namePrefix and nameSuffix logic (kast.yaml) [`b9de205`] 

### Refactoring

- simplify values.yaml for summon chart (charts) [`905bc85`] 

### Chore

- bump version to v1.5.0  [`d3d5d08`] 
- bump version to v1.3.1  [`8b0b871`] 
- bump version to v1.3.0  [`0a9ead2`] 
- bump version to v1.4.0  [`8067647`] 
- bump version to v1.6.0  [`4741d46`] 
- bump version to v1.3.0  [`5b36048`] 
- bump version to v1.5.0  [`599ae16`] 


## [v1.5.0] - 2025-12-03

### Features

- add finops labels for cost allocation and tracking (summon) [`f7a3171`] 
- add common name template and update kast.yaml (librarian) [`e9904ab`] 

### Bug Fixes

- update namePrefix and nameSuffix logic (kast.yaml) [`b9de205`] 

### Refactoring

- simplify values.yaml for summon chart (charts) [`905bc85`] 

### Chore

- bump version to v1.3.1  [`8b0b871`] 
- bump version to v1.3.0  [`0a9ead2`] 


## [v1.3.1] - 2025-12-01

### Bug Fixes

- update namePrefix and nameSuffix logic (kast.yaml) [`b9de205`] 


## [v1.3.0] - 2025-12-01

### Features

- add common name template and update kast.yaml (librarian) [`e9904ab`] 
- add AWS ClusterIssuer with IRSA Autodiscovery example (charts/glyphs/certManager) [`b6d70eb`] 
- add clusterkeycloakrealm support and chart updates (keycloak) [`994397e`] 
- update keycloak chart version feat(covenant): update covenant chart version docs: add new books and getting started guides docs: add glossary and good practices documentation refactor(covenant/templates/applicationset.yaml): improve applicationset yaml style: update chart yaml formatting (charts/glyphs/keycloak) [`8876ebd`] 
- bump version to 1.1.2 and update client secret formatting (charts/glyphs/keycloak) [`6967825`] 
- improve applicationset template with fallbacks for repository, path and revision (covenant) [`46648a6`] 
- generate ApplicationSet when chapters with members are found (covenant/templates) [`7ec0b9f`] 
- update version numbers (charts/kaster, charts/summon) [`d1bbe68`] 
- add ClusterKeycloak template and update covenant template to reference cluster-scoped Keycloak instance connection resource (glyphs/keycloak) [`c09d6a6`] 

### Bug Fixes

- fix chart versions and covenant template (charts,covenant) [`90fa2ac`] 

### Chore

- bump version to v1.4.0  [`8067647`] 
- bump version to v1.6.0  [`4741d46`] 
- bump version to v1.3.0  [`5b36048`] 
- bump version to v1.5.0  [`599ae16`] 
- bump version to v1.1.0  [`3aa388e`] 
- bump version to v1.1.0  [`b915594`] 
- bump version to v0.3.1  [`a495b5a`] 
- bump version to v0.3.0  [`c436ccb`] 
- bump version to v0.2.5  [`ac9a808`] 
- bump version to v0.2.4  [`09ca0ff`] 
- bump version to v0.2.3  [`a1a6d47`] 
- bump version to v0.2.2  [`0e23d9c`] 
- bump chart versions for keycloak and covenant  [`4b8a7f5`] 

### Other

- Here is a conventional commit message based on the provided change summaries:  [`d572f85`] 
- Merge pull request #27 from kast-spells/refactor/covenant  [`b5ee8ba`]  (#27)
- Here are the commit messages for each part:  [`a5dce25`] 


## [v1.4.0] - 2025-12-01

### Features

- add AWS ClusterIssuer with IRSA Autodiscovery example (charts/glyphs/certManager) [`b6d70eb`] 

### Chore

- bump version to v1.6.0  [`4741d46`] 


## [v1.6.0] - 2025-12-01

### Features

- add AWS ClusterIssuer with IRSA Autodiscovery example (charts/glyphs/certManager) [`b6d70eb`] 

### Chore

- bump version to v1.3.0  [`5b36048`] 


## [v1.3.0] - 2025-11-27

### Features

- add clusterkeycloakrealm support and chart updates (keycloak) [`994397e`] 
- update keycloak chart version feat(covenant): update covenant chart version docs: add new books and getting started guides docs: add glossary and good practices documentation refactor(covenant/templates/applicationset.yaml): improve applicationset yaml style: update chart yaml formatting (charts/glyphs/keycloak) [`8876ebd`] 
- bump version to 1.1.2 and update client secret formatting (charts/glyphs/keycloak) [`6967825`] 
- improve applicationset template with fallbacks for repository, path and revision (covenant) [`46648a6`] 
- generate ApplicationSet when chapters with members are found (covenant/templates) [`7ec0b9f`] 

### Bug Fixes

- fix chart versions and covenant template (charts,covenant) [`90fa2ac`] 

### Chore

- bump version to v1.5.0  [`599ae16`] 
- bump version to v1.1.0  [`3aa388e`] 
- bump version to v1.1.0  [`b915594`] 
- bump version to v0.3.1  [`a495b5a`] 
- bump version to v0.3.0  [`c436ccb`] 
- bump version to v0.2.5  [`ac9a808`] 
- bump version to v0.2.4  [`09ca0ff`] 
- bump version to v0.2.3  [`a1a6d47`] 
- bump version to v0.2.2  [`0e23d9c`] 

### Other

- Here is a conventional commit message based on the provided change summaries:  [`d572f85`] 


## [v1.5.0] - 2025-11-27

### Features

- add clusterkeycloakrealm support and chart updates (keycloak) [`994397e`] 
- update keycloak chart version feat(covenant): update covenant chart version docs: add new books and getting started guides docs: add glossary and good practices documentation refactor(covenant/templates/applicationset.yaml): improve applicationset yaml style: update chart yaml formatting (charts/glyphs/keycloak) [`8876ebd`] 
- bump version to 1.1.2 and update client secret formatting (charts/glyphs/keycloak) [`6967825`] 
- improve applicationset template with fallbacks for repository, path and revision (covenant) [`46648a6`] 
- generate ApplicationSet when chapters with members are found (covenant/templates) [`7ec0b9f`] 

### Bug Fixes

- fix chart versions and covenant template (charts,covenant) [`90fa2ac`] 

### Chore

- bump version to v1.1.0  [`3aa388e`] 
- bump version to v1.1.0  [`b915594`] 
- bump version to v0.3.1  [`a495b5a`] 
- bump version to v0.3.0  [`c436ccb`] 
- bump version to v0.2.5  [`ac9a808`] 
- bump version to v0.2.4  [`09ca0ff`] 
- bump version to v0.2.3  [`a1a6d47`] 
- bump version to v0.2.2  [`0e23d9c`] 

### Other

- Here is a conventional commit message based on the provided change summaries:  [`d572f85`] 


## [v1.1.0] - 2025-11-27

### Features

- add clusterkeycloakrealm support and chart updates (keycloak) [`994397e`] 
- update keycloak chart version feat(covenant): update covenant chart version docs: add new books and getting started guides docs: add glossary and good practices documentation refactor(covenant/templates/applicationset.yaml): improve applicationset yaml style: update chart yaml formatting (charts/glyphs/keycloak) [`8876ebd`] 
- bump version to 1.1.2 and update client secret formatting (charts/glyphs/keycloak) [`6967825`] 
- improve applicationset template with fallbacks for repository, path and revision (covenant) [`46648a6`] 
- generate ApplicationSet when chapters with members are found (covenant/templates) [`7ec0b9f`] 
- update version numbers (charts/kaster, charts/summon) [`d1bbe68`] 
- add ClusterKeycloak template and update covenant template to reference cluster-scoped Keycloak instance connection resource (glyphs/keycloak) [`c09d6a6`] 
- update version to 1.2.4 (charts/summon) [`6818945`] 
- add spellbook, lexicon and cards to kast.yaml template (librarian/templates) [`7829faa`] 
- add .gitignore for bookrack symlink (covenant,librarian) [`161c72a`] 
- update sync-docs workflow to use token-based authentication and clone kast-docs repository (workflows/sync-docs.yml) [`8c97e8e`] 

### Bug Fixes

- fix chart versions and covenant template (charts,covenant) [`90fa2ac`] 
- exclude bookrack from rsync sync (workflows) [`c6c4541`] 
- update sync-docs workflow to use multi-line commit message (.github/workflows) [`d8897e5`] 
- create tag in kast-docs after sync to trigger deployment (workflows) [`dd498f5`] 
- translate Spanish comments to English (workflows) [`6449418`] 

### Documentation

- setup automatic sync to kast-docs on tags  [`c497ab3`] 
- add MkDocs Material site with GitHub Pages deployment  [`583bc29`] 
- reorganize documentation with holistic navigation  [`76bf328`] 

### Refactoring

- remove redundant docs validation workflow (workflows) [`c4f5948`] 
- move CODING_STANDARDS and GOOD_PRACTICES into docs/ (docs) [`aa5d5aa`] 

### Chore

- bump version to v1.1.0  [`b915594`] 
- bump version to v0.3.1  [`a495b5a`] 
- bump version to v0.3.0  [`c436ccb`] 
- bump version to v0.2.5  [`ac9a808`] 
- bump version to v0.2.4  [`09ca0ff`] 
- bump version to v0.2.3  [`a1a6d47`] 
- bump version to v0.2.2  [`0e23d9c`] 
- bump chart versions for keycloak and covenant  [`4b8a7f5`] 
- remove unnecessary .gitignore files from covenant and librarian  [`44a1792`] 

### Other

- Here is a conventional commit message based on the provided change summaries:  [`d572f85`] 
- Merge pull request #27 from kast-spells/refactor/covenant  [`b5ee8ba`]  (#27)
- Here are the commit messages for each part:  [`a5dce25`] 
- Here's a conventional commit message based on the provided change summaries:  [`0ef3ef7`] 
- Review Kast system stack and documentation  [`4caadca`] 


## [v1.1.0] - 2025-11-27

### Features

- add clusterkeycloakrealm support and chart updates (keycloak) [`994397e`] 
- update keycloak chart version feat(covenant): update covenant chart version docs: add new books and getting started guides docs: add glossary and good practices documentation refactor(covenant/templates/applicationset.yaml): improve applicationset yaml style: update chart yaml formatting (charts/glyphs/keycloak) [`8876ebd`] 
- bump version to 1.1.2 and update client secret formatting (charts/glyphs/keycloak) [`6967825`] 
- improve applicationset template with fallbacks for repository, path and revision (covenant) [`46648a6`] 
- generate ApplicationSet when chapters with members are found (covenant/templates) [`7ec0b9f`] 
- update version numbers (charts/kaster, charts/summon) [`d1bbe68`] 
- add ClusterKeycloak template and update covenant template to reference cluster-scoped Keycloak instance connection resource (glyphs/keycloak) [`c09d6a6`] 
- update version to 1.2.4 (charts/summon) [`6818945`] 
- add spellbook, lexicon and cards to kast.yaml template (librarian/templates) [`7829faa`] 
- add .gitignore for bookrack symlink (covenant,librarian) [`161c72a`] 

### Bug Fixes

- fix chart versions and covenant template (charts,covenant) [`90fa2ac`] 
- exclude bookrack from rsync sync (workflows) [`c6c4541`] 

### Chore

- bump version to v0.3.1  [`a495b5a`] 
- bump version to v0.3.0  [`c436ccb`] 
- bump version to v0.2.5  [`ac9a808`] 
- bump version to v0.2.4  [`09ca0ff`] 
- bump version to v0.2.3  [`a1a6d47`] 
- bump version to v0.2.2  [`0e23d9c`] 
- bump chart versions for keycloak and covenant  [`4b8a7f5`] 
- remove unnecessary .gitignore files from covenant and librarian  [`44a1792`] 

### Other

- Here is a conventional commit message based on the provided change summaries:  [`d572f85`] 
- Merge pull request #27 from kast-spells/refactor/covenant  [`b5ee8ba`]  (#27)
- Here are the commit messages for each part:  [`a5dce25`] 
- Here's a conventional commit message based on the provided change summaries:  [`0ef3ef7`] 


## [v0.3.1] - 2025-11-27

### Other

- Here is a conventional commit message based on the provided change summaries:  [`d572f85`] 


## [v0.3.0] - 2025-11-24

### Features

- add clusterkeycloakrealm support and chart updates (keycloak) [`994397e`] 


## [v0.2.5] - 2025-11-24

### Features

- update keycloak chart version feat(covenant): update covenant chart version docs: add new books and getting started guides docs: add glossary and good practices documentation refactor(covenant/templates/applicationset.yaml): improve applicationset yaml style: update chart yaml formatting (charts/glyphs/keycloak) [`8876ebd`] 


## [v0.2.4] - 2025-11-23

### Features

- bump version to 1.1.2 and update client secret formatting (charts/glyphs/keycloak) [`6967825`] 


## [v0.2.3] - 2025-11-23

### Bug Fixes

- fix chart versions and covenant template (charts,covenant) [`90fa2ac`] 


## [v0.2.2] - 2025-11-23

### Features

- improve applicationset template with fallbacks for repository, path and revision (covenant) [`46648a6`] 

