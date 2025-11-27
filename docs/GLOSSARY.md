# Glossary

Technical terminology reference for kast-system.

## Configuration Structure

**Book**
Deployment context containing chapters and configuration. Represents an environment, cluster, or organizational unit. Located in `bookrack/`. A book consists of a directory with an `index.yaml` file, optional `_lexicon` folder, and one or more chapter directories. The index.yaml specifies included chapters and default chart repositories (kaster, summon).

**Chapter**
Logical grouping of spells within a book. Examples: intro, services, monitoring. Each chapter is a directory within the book containing spells. Chapters can have an optional `index.yaml` to override book-level defaults for kaster/summon chart repositories.

**Spell**
Central concept in kast. YAML file defining application or infrastructure deployment. Located in book chapters. Spells can include multiple resources simultaneously, support glyphs and runes, and range from simple docker deployments via summon to complex multi-chart deployments.

**Index**
`index.yaml` file in book root. Defines book metadata, chapters, chart versions, and repositories.

**Rune**
Independent chart serving as component within main spell. Used when application requires multiple charts or additional resources (CRDs, addons). Runes function independently but complement the main chart. Not recommended for standalone apps. Defined in spell's `runes` array.

**Appendix**
Shared configuration appended to all spells in a scope. Can be book-level (`_appendix/`) or chapter-level. Provides common values, environment variables, and glyph definitions automatically merged into all spells. Located in `bookrack/<book>/_appendix/` (book-level) or `bookrack/<book>/<chapter>/_appendix/` (chapter-level).

**Local Appendix**
Chapter-specific appendix that extends or overrides book-level appendix. See [BOOKRACK.md](BOOKRACK.md) for appendix system details.

## Charts and Templates

**Chart**
Standard Helm chart. Contains templates, values, and Chart.yaml.

**Glyph**
Reusable Helm named template for specific functionality. Located in `charts/glyphs/`. Examples: vault, istio, certManager.

**Kaster**
Orchestration chart serving as package manager for preconfigured resource definitions. Coordinates multiple glyphs by iterating glyph definitions and invoking templates. Repository defined in book/chapter `index.yaml`. Contains glyphs that can be invoked via glyph declarations in spells.

**Summon**
Standardized deployment approach for microservices. Base chart for workload deployment. Generates Deployment, StatefulSet, Service, PVC, HPA, ServiceAccount resources. Inherits defaults from book/chapter `index.yaml`. Enables deploying any container following platform standards.

**Trinket**
Opinionated Helm chart wrapping glyphs for specific patterns. Examples: microspell (microservices), tarot (CI/CD workflows), covenant (identity management). Located in `charts/trinkets/`. Trinkets provide higher-level abstractions with sensible defaults built on summon and glyphs.

## Deployment

**Librarian**
ArgoCD App of Apps orchestrator. Reads books from bookrack and generates ArgoCD Applications via ApplicationSets.

**Source**
ArgoCD Application source. Points to Helm chart repository and path. Multi-source applications use multiple sources.

**Deployment Strategy**
Method Librarian uses to deploy spell. Detected from spell configuration:
- Simple: Uses Summon chart
- Infrastructure: Uses Kaster chart for glyphs
- Multi-source: Uses Summon + Kaster + runes
- External: Direct chart deployment

## Discovery and Resolution

**Lexicon**
Global registry of infrastructure resources. Array in `Values.lexicon`. Contains entries for vault servers, gateways, databases, etc. Defined in book's `_lexicon` directory. Provides shared configuration dependencies for glyphs, enabling resource discovery via selectors.

**Lexicon Entry**
Single infrastructure resource definition in lexicon. Contains type, labels, and configuration.

**Runic Indexer**
Template function that queries lexicon entries matching label selectors. Returns infrastructure configuration for glyphs.

**Selector**
Label-based query used by runic indexer. Matches lexicon entries with same labels.

**Default Selector**
Special label in lexicon entry indicating fallback. Values: `book` (book-wide default), `chapter` (chapter-specific default).

## Hierarchy and Scope

**Hierarchy System**
Pattern where specific configuration overrides general configuration. Used in values merging, vault paths, lexicon defaulting.

**Scope**
Configuration visibility level:
- Book scope: Available to all chapters
- Chapter scope: Available to spells in chapter
- Spell scope: Specific to one spell
- Namespace scope: Kubernetes namespace-specific

**Path Hierarchy** (Vault)
Vault secret path resolution pattern: `book/publics` → `chapter/publics` → `namespace/publics`.

**Values Hierarchy**
Configuration merging order: global defaults → book → chapter → spell. Most specific wins.

## Vault Integration

**Vault Path**
Vault KV path following pattern: `kv/data/<spellbook>/<chapter>/<namespace>/<scope>/<name>`.

**Vault Policy**
HashiCorp Vault policy defining access rules. Generated by vault glyph.

**Vault Role**
Kubernetes auth role mapping ServiceAccount to Vault policy.

**Secret Path Type**
Vault path scope:
- `book`: `<spellbook>/publics/<name>`
- `chapter`: `<spellbook>/<chapter>/publics/<name>`
- Default: `<spellbook>/<chapter>/<namespace>/publics/<name>`
- Absolute: Custom full path

## Tarot Workflows

**Tarot**
Trinket for dynamic Argo Workflow generation using card-based configuration.

**Card**
Workflow task definition in Tarot. Can be registered, selector-based, or inline.

**Reading**
Tarot workflow definition. Maps card names to configurations with positions and dependencies.

**Position**
Card execution order indicator:
- `foundation`: Initial tasks, no dependencies
- `action`: Main tasks, depends on foundation
- `challenge`: Validation tasks, depends on action
- `outcome`: Final tasks, depends on all previous

**Execution Mode**
Tarot workflow type:
- `container`: Single-pod execution
- `dag`: Directed Acyclic Graph with dependencies
- `steps`: Sequential with parallel support
- `suspend`: Workflow with approval gates

**Card Resolution**
Process of determining card implementation. Methods: registered name lookup, selector-based discovery, inline definition.

## Covenant (Identity Management)

**Covenant**
Trinket for identity and access management using Keycloak and Vault OIDC. Manages realms, clients, users, groups, and secrets. Located in `kast-system/covenant/`. Uses two-stage deployment: main covenant generates ApplicationSet, per-chapter covenants render actual resources.

**Integration**
Configuration in covenant for OIDC client. Defines clientId, redirect URIs, web URL, and secret generation. One integration = one KeycloakClient + one VaultSecret.

**Member**
User definition in covenant. Generates KeycloakUser with email, groups, and optional password policy.

**Chapel**
Subgroup within covenant chapter. Creates KeycloakGroup resource.

**Conventions Directory**
Structured directory in covenant book containing integrations/, members/, and chapels/ subdirectories.

## RBAC and Security

**ServiceAccount**
Kubernetes ServiceAccount for pod identity. Used by Vault for authentication and K8s RBAC.

**Role**
Kubernetes Role defining namespace-scoped permissions.

**ClusterRole**
Kubernetes ClusterRole defining cluster-wide permissions.

**Policy** (Vault)
Vault policy document in HCL defining path-based access rules.

**Password Policy**
Vault password generation policy defining character requirements and length.

## Testing

**TDD**
Test-Driven Development. Methodology: write failing test, implement feature, verify test passes, refactor.

**Example**
Test case YAML file in chart's `examples/` directory. Serves as both test and documentation.

**Snapshot**
Expected output for chart rendering. Used to detect unintended changes.

**Resource Completeness**
Validation that expected Kubernetes resources are generated based on configuration.

**Glyph Test**
Test that renders glyph through kaster and validates output against expected result.

## Resource Types

**Workload**
Kubernetes workload resource. Types: Deployment, StatefulSet, DaemonSet, Job, CronJob.

**PVC**
PersistentVolumeClaim. Kubernetes storage request.

**HPA**
HorizontalPodAutoscaler. Kubernetes autoscaling resource.

**VirtualService**
Istio resource defining routing rules for service mesh traffic.

**Gateway**
Istio resource defining ingress/egress configuration.

**VaultSecret**
Kubernetes CRD (via vault-config-operator) syncing secrets from Vault to K8s. Replaces external-secrets operator. Used by vault glyph for secret synchronization.

**RandomSecret**
Kubernetes CRD (via vault-config-operator) generating random passwords using Vault password policies and storing in Vault.

**Policy** (Vault Config Operator CRD)
Kubernetes CRD defining Vault HCL policies. Managed by vault-config-operator.

**KubernetesAuthEngineRole**
Kubernetes CRD binding ServiceAccounts to Vault policies via Kubernetes authentication. Part of vault glyph prolicy template.

## Conventions

**Spellbook**
Book name used in configurations and vault paths. Defined in book's index.yaml.

**Trinket Key**
Field in spell configuration indicating which trinket to use. Defaults to summon if not specified.

**Glyph Key**
When spell uses non-summon charts, configuration is under `glyphs` key. Summon direct uses source name without glyph key.

**Namespace**
Kubernetes namespace. Can be defined in spell or inherited from chapter name.

## Operators

**Vault Config Operator**
Kubernetes operator for declarative Vault configuration. Provides VaultSecret, Policy, KubernetesAuthEngineRole, RandomSecret, and other CRDs. Used extensively by vault glyph. Repository: https://github.com/redhat-cop/vault-config-operator

**External Secrets Operator**
Kubernetes operator syncing secrets from external systems. Legacy approach, replaced by vault-config-operator in kast.

**Argo Workflows**
Kubernetes-native workflow engine. Used by Tarot trinket for dynamic CI/CD workflow execution.

**ArgoCD**
GitOps continuous delivery tool. Librarian generates ArgoCD Applications via ApplicationSets. Core deployment mechanism for kast.

**Istio**
Service mesh providing traffic management, security, and observability. Istio glyph generates VirtualServices, Gateways, and DestinationRules.

**Cert-Manager**
Certificate management operator. certManager glyph generates Certificate, Issuer, and DNSEndpoint resources.

## TDD Phases

**RED Phase**
First phase of TDD. Write failing test before implementing feature. Command: `make tdd-red`. Failures are expected and acceptable (exit code 0).

**GREEN Phase**
Second phase of TDD. Implement minimum code to make test pass. Command: `make tdd-green`. Tests must pass (exit code non-zero on failure).

**REFACTOR Phase**
Third phase of TDD. Improve code while maintaining test coverage. Command: `make tdd-refactor`. Runs comprehensive test suite including snapshots and glyphs.

## Additional Terms

**Multi-Source**
ArgoCD Application pattern using multiple Helm charts simultaneously. Kast uses this for combining summon (workload) + kaster (glyphs) + runes (additional charts). Enables composition of complex deployments from modular components.

**ApplicationSet**
ArgoCD resource generating multiple Applications from templates. Librarian uses ApplicationSets to deploy entire books. Covenant uses ApplicationSets to generate per-chapter applications.

**Chapter Filter**
Parameter in covenant deployment filtering which chapter's resources to render. Main covenant has no filter (generates ApplicationSet), chapter-specific covenants have filter (render actual resources).

**Prolicy**
Vault policy glyph type. Note: "prolicy" is correct spelling in kast (not "policy") to distinguish from Vault Policy CRD. Generates both Policy CRD and KubernetesAuthEngineRole.

**Default Verbs**
Glyph containing utility templates for common operations. Provides helper functions used by other glyphs.

**Runic System**
Infrastructure discovery and indexing system. Includes runic indexer template function and related glyphs for querying lexicon.
