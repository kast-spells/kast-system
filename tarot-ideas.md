# Tarot System Design for Dynamic Workflows

## Overview

The Tarot system is a mystical approach to dynamic workflow composition in kast, designed to replace static workflow templates with a flexible, card-based system that follows kast's lexicon and runic indexer patterns.

## Core Concepts

### Mystical Terminology Mapping

| Concept | Mystical Term | Technical Meaning |
|---------|---------------|-------------------|
| Container Step | Card | Atomic workflow component (container + parameters) |
| Workflow | Tarot/Reading | Composed workflow using selected cards |
| Step Library | Deck | Dictionary of resolved/selected cards for a workflow |
| Step Category | Suit | Functional grouping (source, build, test, deploy, notify) |
| Core vs Utility | Major/Minor Arcana | Essential vs helper cards |
| Step Dependencies | Card Position | Dependency relationships (foundation, action, challenge, outcome) |
| Parameter Binding | Card Spread | How cards are arranged and configured |
| Event Triggers | Mystical Events | External triggers that initiate tarot readings |

## Architecture

### Layer Separation

#### Glyphs (Foundation Layer)
- `charts/glyphs/argo-workflow/` - Core Argo Workflows resources
- `charts/glyphs/argo-events/` - Core Argo Events resources

#### Trinket (Orchestration Layer)  
- `charts/trinkets/tarot/` - Card/tarot system that composes glyphs

### Lexicon Integration

#### Trigger Registry
Triggers are registered in the lexicon and selected via runic indexer:

```yaml
# bookrack/spellbooks/triggers/index.yaml
triggers:
  github-push:
    type: webhook
    labels:
      source: github
      event: push
      default: book
    chapter: ci
    webhook:
      url: "{{lexicon.github.webhook.url}}"
      secret: "{{lexicon.github.webhook.secret}}"
      
  gitlab-merge:
    type: webhook  
    labels:
      source: gitlab
      event: merge_request
      default: chapter
    chapter: ci
```

#### Card Registry
Cards are registered in lexicon with labels for runic indexer selection:

```yaml
# bookrack/spellbooks/cards/index.yaml  
cards:
  git-clone:
    type: source
    labels:
      vcs: git
      action: clone
      default: book
    chapter: source
    container:
      image: alpine/git:latest
      command: [sh, -c]
    parameters:
      repository: string
      branch: string
      path: string
      
  container-build:
    type: build
    labels:
      builder: buildah
      target: container
      default: chapter
    chapter: build  
    container:
      image: quay.io/buildah/stable
      securityContext:
        privileged: true
    parameters:
      dockerfile: string
      registry: string
      context: string
```

### Deck Resolution System

The deck is a resolved dictionary of selected cards, built using runic indexer:

```yaml
# Deck selection in tarot configuration
deck:
  checkout:
    selectors:
      vcs: git
      action: clone
    # Runic indexer finds: git-clone card
    
  build:
    selectors:
      builder: buildah
      target: container  
    # Runic indexer finds: container-build card
    
  # Explicit card selection (bypasses runic indexer)
  test:
    card: unit-tests
```

### Tarot Structure

Complete tarot workflow definition:

```yaml
# values.yaml for tarot trinket
triggers:
  selectors:
    source: github
    event: push
  # Runic indexer selects github-push trigger

deck:
  checkout:
    selectors:
      vcs: git
      action: clone
  build:
    selectors:
      builder: buildah
      target: container
  test:
    card: unit-tests  # Explicit selection
  deploy:
    selectors:
      platform: kubernetes
      method: helm

tarots:
  ci-pipeline:
    reading:
      - card: checkout  # References deck.checkout
        position: foundation
        with:
          repository: "{{workflow.parameters.repo}}"
          branch: "{{workflow.parameters.branch}}"
          path: /workspace
          
      - card: build
        position: action  
        depends: [checkout]
        with:
          dockerfile: Dockerfile
          context: /workspace
          registry: "{{lexicon.registry.url}}"
          
      - card: test
        position: challenge
        depends: [build]
        with:
          testCommand: ["npm", "test"]
          workingDir: /workspace
          
      - card: deploy
        position: outcome
        depends: [test]
        if: "{{workflow.parameters.branch}} == 'main'"
        with:
          environment: staging
          chart: /workspace/helm-chart
```

## Implementation Templates

### Deck Resolver Template

```yaml
# charts/trinkets/tarot/templates/_deck-resolver.tpl
{{- define "tarot.resolveDeck" }}
{{- $root := index . 0 }}
{{- $deckDef := index . 1 }}
{{- $resolvedDeck := dict }}

{{- range $cardName, $cardSelector := $deckDef }}
  {{- if $cardSelector.card }}
    {{/* Explicit card selection */}}
    {{- $resolvedCard := include "lexicon.lookup" (list $root (printf "cards.%s" $cardSelector.card)) }}
    {{- $resolvedDeck = set $resolvedDeck $cardName $resolvedCard }}
  {{- else if $cardSelector.selectors }}
    {{/* Runic indexer selection */}}
    {{- $allCards := include "lexicon.lookup" (list $root "cards") }}
    {{- $selectedCards := include "runicIndexer.runicIndexer" (list $allCards $cardSelector.selectors "source" $root.Values.spellbook.chapter) }}
    {{- $resolvedDeck = set $resolvedDeck $cardName (index $selectedCards.results 0) }}
  {{- end }}
{{- end }}

{{- $resolvedDeck | toJson }}
{{- end }}
```

### Card Position System

Mystical positions define dependency relationships:

- **Foundation**: Starting cards (no dependencies)
- **Action**: Main workflow steps (depend on foundation)
- **Challenge**: Testing/validation steps (depend on action)
- **Outcome**: Final steps like deployment (depend on challenge)

### Parameter Binding

Cards receive parameters through:
1. **with**: Direct parameter specification
2. **lexicon**: Values from spellbook/chapter
3. **workflow.parameters**: Runtime parameters from triggers
4. **inheritance**: Default values from card definitions

## Card Library Organization

### Suits (Categories)

- **Source**: git-clone, git-push, svn-checkout
- **Build**: container-build, helm-package, npm-build
- **Test**: unit-tests, integration-tests, security-scan
- **Deploy**: kubernetes-deploy, helm-deploy, argocd-sync
- **Notify**: slack-notify, email-notify, webhook-call

### Major vs Minor Arcana

- **Major Arcana**: Core workflow cards used in most pipelines
- **Minor Arcana**: Specialized utility cards for specific use cases

## Benefits

### Dynamic Composability
- Cards can be mixed/matched from different decks
- Inline custom cards for specific needs
- Dependency resolution via mystical positions
- Parameter inheritance from book/chapter hierarchy

### Mystical Consistency
- Aligns with kast's arcane naming convention
- Natural fit with existing spellbook/lexicon concepts
- Intuitive metaphors for developers familiar with tarot

### Practical Advantages
- More flexible than static workflow templates
- Reusable components across different workflows
- Version-controlled card libraries in bookracks
- Testable individual cards + composed tarots
- GitHub Actions-like experience but kast-native

## Integration with Existing Systems

### Spellbook/Lexicon
- Triggers registered in lexicon with labels
- Cards registered in lexicon with type/labels
- Runic indexer provides selection logic
- Book/chapter hierarchy for defaults

### Event System
- Argo Events glyphs handle event infrastructure
- Triggers resolved from lexicon
- Sensors automatically created for selected triggers
- Parameter mapping from webhooks to workflows

### Workflow System
- Argo Workflows glyphs handle workflow infrastructure
- Cards generate workflow templates
- Dependency resolution via positions
- Parameter binding from deck + runtime

## Next Steps

1. **Create argo-events glyph** with lexicon integration
2. **Create argo-workflow glyph** with template generation
3. **Implement tarot trinket** with deck resolution
4. **Build card library** with common workflow steps
5. **Create comprehensive examples** and TDD tests
6. **Migrate deployment2** to use tarot system

This design creates a powerful, flexible workflow system that maintains kast's mystical identity while providing GitHub Actions-like composability.