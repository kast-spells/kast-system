# Tarot System Architecture Diagrams

This document contains detailed architectural diagrams for the Tarot system components and data flows.

## System Overview

```mermaid
graph TB
    subgraph "User Interface"
        UI[Tarot Reading YAML]
        EX[Examples & Templates]
    end
    
    subgraph "Tarot Core Engine"
        CR[Card Resolver]
        SI[Secret Injector] 
        DR[Dependency Resolver]
        WG[Workflow Generator]
        TR[Template Resolver]
    end
    
    subgraph "Integration Layer"
        RI[Runic Indexer]
        VS[Vault Secrets]
        K8S[Kubernetes API]
        RBAC[RBAC Manager]
    end
    
    subgraph "Execution Layer"
        AW[Argo Workflows]
        PODS[Workflow Pods]
        SEC[Secret Resources]
        VOL[Volume Resources]
    end
    
    subgraph "Storage & State"
        VAULT[HashiCorp Vault]
        ETCD[Kubernetes etcd]
        PVC[Persistent Volumes]
    end
    
    UI --> CR
    EX --> CR
    
    CR --> SI
    CR --> DR
    CR --> TR
    SI --> WG
    DR --> WG
    TR --> WG
    
    CR --> RI
    SI --> VS
    WG --> K8S
    WG --> RBAC
    
    K8S --> AW
    RBAC --> AW
    AW --> PODS
    AW --> SEC
    AW --> VOL
    
    VS --> VAULT
    K8S --> ETCD
    VOL --> PVC
    
    style UI fill:#e1f5fe
    style AW fill:#e8f5e8
    style VAULT fill:#ffebee
```

## Card Resolution Flow

```mermaid
flowchart TD
    START([Card Definition Input]) --> CHECK{Card Type?}
    
    CHECK -->|Has Name| NAME[Name Resolution]
    CHECK -->|Has Selectors| SEL[Selector Resolution]  
    CHECK -->|Has Container| INLINE[Inline Resolution]
    
    NAME --> LOOKUP[Registered Card Lookup]
    LOOKUP --> FOUND{Card Found?}
    FOUND -->|Yes| MERGE[Merge with Overrides]
    FOUND -->|No| IMPLICIT[Try Implicit Selectors]
    
    SEL --> RUNIC[Runic Indexer Query]
    RUNIC --> LABELS[Label Matching]
    LABELS --> RESULTS{Results Found?}
    RESULTS -->|Yes| FIRST[Select First Match]
    RESULTS -->|No| ERROR1[Resolution Failed]
    
    INLINE --> VALIDATE[Validate Container Spec]
    VALIDATE --> VALID{Valid?}
    VALID -->|Yes| DIRECT[Direct Container Use]
    VALID -->|No| ERROR2[Invalid Container]
    
    IMPLICIT --> RUNIC
    FIRST --> MERGE
    DIRECT --> MERGE
    
    MERGE --> PARAMS[Apply Parameters]
    PARAMS --> SECRETS[Inject Secrets]
    SECRETS --> ENVS[Inject Environment]
    ENVS --> RESOLVED([Resolved Card])
    
    ERROR1 --> FAIL([Resolution Failed])
    ERROR2 --> FAIL
    
    style START fill:#e1f5fe
    style RESOLVED fill:#e8f5e8
    style FAIL fill:#ffebee
    style RUNIC fill:#f3e5f5
```

## Secret Management Architecture

```mermaid
graph TB
    subgraph "Secret Sources"
        VAULT[HashiCorp Vault]
        K8SSEC[Kubernetes Secrets]
        ENV[Environment Variables]
    end
    
    subgraph "Secret Configuration"
        GLOBAL[Global Secrets]
        CARD[Card-Specific Secrets]
        INLINE[Inline Secrets]
    end
    
    subgraph "Secret Processing"
        MERGE[Hierarchical Merge]
        RESOLVE[Value Resolution]
        VALIDATE[Validation]
    end
    
    subgraph "Injection Methods"
        ENVVAR[Environment Variables]
        VOLMOUNT[Volume Mounts]
        SECRES[Secret Resources]
    end
    
    subgraph "Container Runtime"
        CONT[Container Environment]
        FILES[Mounted Files]
    end
    
    VAULT --> GLOBAL
    K8SSEC --> GLOBAL
    ENV --> GLOBAL
    
    GLOBAL --> MERGE
    CARD --> MERGE
    INLINE --> MERGE
    
    MERGE --> RESOLVE
    RESOLVE --> VALIDATE
    VALIDATE --> ENVVAR
    VALIDATE --> VOLMOUNT
    VALIDATE --> SECRES
    
    ENVVAR --> CONT
    VOLMOUNT --> FILES
    SECRES --> FILES
    
    style VAULT fill:#ffebee
    style CONT fill:#e8f5e8
    style MERGE fill:#f3e5f5
```

## Execution Mode Workflows

```mermaid
graph TB
    subgraph "Container Mode"
        C1[Single Task Entry] --> C2[Container Execution] --> C3[Task Complete]
    end
    
    subgraph "DAG Mode"
        D1[DAG Entry] --> D2[Parallel Task Execution]
        D2 --> D3[Task A]
        D2 --> D4[Task B]  
        D2 --> D5[Task C]
        D3 --> D6[Dependent Task D]
        D4 --> D6
        D5 --> D7[Final Task E]
        D6 --> D7
        D7 --> D8[DAG Complete]
    end
    
    subgraph "Steps Mode"  
        S1[Steps Entry] --> S2[Step 1: Parallel Tasks]
        S2 --> S3[Task A & B]
        S3 --> S4[Step 2: Sequential]
        S4 --> S5[Task C]
        S5 --> S6[Step 3: Final]
        S6 --> S7[Task D]
        S7 --> S8[Steps Complete]
    end
    
    subgraph "Suspend Mode"
        U1[Suspend Entry] --> U2[Initial Tasks]
        U2 --> U3[Approval Gate 🛑]
        U3 --> U4{Human Decision}
        U4 -->|Approved| U5[Continue Execution]
        U4 -->|Rejected| U6[Workflow Failed]
        U5 --> U7[Final Tasks]
        U7 --> U8[Suspend Complete]
    end
    
    style C1 fill:#e1f5fe
    style D1 fill:#e1f5fe
    style S1 fill:#e1f5fe
    style U1 fill:#e1f5fe
    
    style C3 fill:#e8f5e8
    style D8 fill:#e8f5e8
    style S8 fill:#e8f5e8
    style U8 fill:#e8f5e8
    
    style U3 fill:#ffebee
    style U6 fill:#ffebee
```

## Dependency Resolution Algorithm

```mermaid
flowchart TD
    START([Card with Position & Dependencies]) --> EXPLICIT{Has Explicit Dependencies?}
    
    EXPLICIT -->|Yes| GETEXPLICIT[Extract Explicit Dependencies]
    EXPLICIT -->|No| POSITION{Check Position}
    
    POSITION -->|foundation| NONE[No Auto-Dependencies]
    POSITION -->|action| FOUNDATION[Find All Foundation Cards]
    POSITION -->|challenge| ACTIONFOUND[Find All Action + Foundation]
    POSITION -->|outcome| ALLFOUND[Find All Previous Positions]
    
    GETEXPLICIT --> POSITION
    
    FOUNDATION --> FOUNDLIST[Create Foundation List]
    ACTIONFOUND --> ACTIONLIST[Create Action + Foundation List]
    ALLFOUND --> ALLLIST[Create Complete List]
    
    FOUNDLIST --> MERGE[Merge Explicit + Position Dependencies]
    ACTIONLIST --> MERGE
    ALLLIST --> MERGE
    NONE --> MERGE
    GETEXPLICIT --> MERGE
    
    MERGE --> DEDUP[Remove Duplicates & Self-References]
    DEDUP --> VALIDATE[Validate Dependencies Exist]
    VALIDATE --> VALID{All Valid?}
    
    VALID -->|Yes| DEPS([Final Dependency List])
    VALID -->|No| ERROR[Dependency Resolution Error]
    
    style START fill:#e1f5fe
    style DEPS fill:#e8f5e8
    style ERROR fill:#ffebee
    style MERGE fill:#f3e5f5
```

## RBAC Security Model

```mermaid
graph TB
    subgraph "Identity & Authentication"
        SA[Service Account]
        VAULT_ROLE[Vault Role]
        K8S_AUTH[Kubernetes Authentication]
    end
    
    subgraph "Cluster-Level Permissions"
        CR[Cluster Role]
        CRB[Cluster Role Binding]
        TEMPLATES[Cluster Workflow Templates]
        NODES[Node Information]
    end
    
    subgraph "Namespace-Level Permissions"
        ROLE[Role]
        RB[Role Binding]
        WORKFLOWS[Workflow Management]
        PODS[Pod Management]
        SECRETS[Secret Access]
        PVCS[PVC Management]
    end
    
    subgraph "Resource Access Control"
        READ[Read Operations]
        WRITE[Write Operations]
        EXEC[Execute Operations]
        DELETE[Delete Operations]
    end
    
    subgraph "Audit & Compliance"
        LABELS[Resource Labels]
        ANNOTATIONS[Audit Annotations]
        EVENTS[Event Logging]
    end
    
    SA --> VAULT_ROLE
    SA --> K8S_AUTH
    
    SA --> CR
    SA --> ROLE
    
    CR --> CRB
    CRB --> TEMPLATES
    CRB --> NODES
    
    ROLE --> RB
    RB --> WORKFLOWS
    RB --> PODS
    RB --> SECRETS
    RB --> PVCS
    
    WORKFLOWS --> READ
    WORKFLOWS --> WRITE
    WORKFLOWS --> EXEC
    WORKFLOWS --> DELETE
    
    WRITE --> LABELS
    WRITE --> ANNOTATIONS
    EXEC --> EVENTS
    
    style SA fill:#e1f5fe
    style VAULT_ROLE fill:#ffebee
    style EVENTS fill:#e8f5e8
```

## Data Flow Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant T as Tarot System
    participant R as Runic Indexer
    participant V as Vault
    participant K as Kubernetes API
    participant A as Argo Workflows
    participant P as Workflow Pods
    
    U->>T: Submit Tarot Reading YAML
    
    Note over T: Card Resolution Phase
    T->>R: Resolve card selectors
    R->>T: Return matching cards
    
    Note over T: Secret Resolution Phase  
    T->>V: Request secrets
    V->>T: Return secret values
    
    Note over T: Dependency Resolution Phase
    T->>T: Calculate dependencies
    T->>T: Generate workflow spec
    
    Note over T: Resource Creation Phase
    T->>K: Create RBAC resources
    K->>T: RBAC resources created
    
    T->>K: Create secret resources  
    K->>T: Secret resources created
    
    T->>K: Create workflow resource
    K->>A: Forward workflow to Argo
    
    Note over A: Workflow Execution Phase
    A->>P: Schedule workflow pods
    P->>V: Access secrets (if needed)
    P->>P: Execute workflow tasks
    P->>A: Report task completion
    
    A->>K: Update workflow status
    K->>T: Workflow status available
    T->>U: Workflow execution complete
```

## Component Integration Map

```mermaid
mindmap
  root((Tarot System))
    Input Layer
      YAML Configuration
      Card Definitions
      Secret Specifications
      Workflow Parameters
    
    Processing Core
      Card Resolver
        Name Resolution
        Selector Resolution
        Inline Resolution
      Secret Injector
        Vault Integration
        K8s Secrets
        Environment Variables
      Workflow Generator
        Container Mode
        DAG Mode
        Steps Mode
        Suspend Mode
    
    Integration Points
      Runic Indexer
        Label Matching
        Card Selection
        Template Resolution
      Kubernetes API
        Resource Management
        Status Reporting
        Event Logging
      Argo Workflows
        Workflow Execution
        Task Scheduling
        Pod Management
    
    Security Layer
      RBAC Management
        Service Accounts
        Cluster Roles
        Role Bindings
      Secret Management
        Vault Secrets
        K8s Secrets
        Volume Mounts
      Network Security
        Network Policies
        Resource Isolation
    
    Output Layer
      Workflow Resources
      RBAC Resources
      Secret Resources
      Monitoring Events
```

## Performance & Scaling Considerations

```mermaid
graph TB
    subgraph "Input Scale"
        CARDS[Card Registry Size]
        SECRETS[Secret Count]
        DEPS[Dependency Complexity]
        PARAMS[Parameter Count]
    end
    
    subgraph "Processing Bottlenecks"
        RESOLVE[Card Resolution Time]
        VAULT_API[Vault API Calls]
        K8S_API[Kubernetes API Calls]
        TEMPLATE[Template Generation]
    end
    
    subgraph "Optimization Strategies"
        CACHE[Card Resolution Cache]
        BATCH[Batch API Operations]
        ASYNC[Async Processing]
        POOL[Connection Pooling]
    end
    
    subgraph "Runtime Performance"
        PARALLEL[Parallel Execution]
        RESOURCES[Resource Allocation]
        SCHEDULING[Pod Scheduling]
        MONITORING[Performance Monitoring]
    end
    
    CARDS --> RESOLVE
    SECRETS --> VAULT_API
    DEPS --> K8S_API
    PARAMS --> TEMPLATE
    
    RESOLVE --> CACHE
    VAULT_API --> BATCH
    K8S_API --> ASYNC
    TEMPLATE --> POOL
    
    CACHE --> PARALLEL
    BATCH --> RESOURCES
    ASYNC --> SCHEDULING
    POOL --> MONITORING
    
    style CARDS fill:#e1f5fe
    style MONITORING fill:#e8f5e8
    style CACHE fill:#f3e5f5
```

---

*These diagrams provide a comprehensive view of the Tarot system architecture, showing how all components interact to create a powerful, secure, and scalable dynamic workflow framework.*