# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

