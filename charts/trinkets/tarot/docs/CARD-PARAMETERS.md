# Card Parameters and Secrets - Examples

Ejemplos de cómo usar parámetros y secrets específicos de cards.

## Problema que Resuelve

Antes, todos los secrets y parámetros estaban en el nivel `tarot`, lo que significaba:
- ❌ Tenías que saber qué secrets necesita cada card
- ❌ Todos los secrets se exponían a todas las cards
- ❌ No podías reutilizar cards fácilmente (estaban "acopladas" al workflow)

Ahora, con secrets y parámetros a nivel de card:
- ✅ Cada card define sus propios secrets y parámetros
- ✅ Secrets solo se exponen a las cards que los necesitan
- ✅ Cards son reutilizables y portables
- ✅ El workflow solo necesita saber qué cards usar, no sus dependencias

## 1. Parámetros de Cards con Defaults

### Definición de Card con Parámetros

```yaml
cards:
  - name: build-image
    type: card
    labels: {stage: build, category: container}
    # Parámetros con valores por defecto
    envs:
      CONTAINERFILE_NAME: "Containerfile"  # Default
      BUILD_FORMAT: "docker"
      BUILD_ARGS: ""
    container:
      image: quay.io/buildah/stable:latest
      command: ["/bin/sh", "-c"]
      args:
        - |
          buildah bud \
            --format=${BUILD_FORMAT} \
            -f ${CONTAINERFILE_NAME} \
            ${BUILD_ARGS} \
            -t ${IMAGE_NAME}:${IMAGE_TAG} .
```

### Uso con Defaults (no hace falta especificar nada)

```yaml
tarot:
  reading:
    build:
      selectors: {stage: build, category: container}
      position: action
      # Usa Containerfile por defecto
```

### Override de Parámetros en el Reading

```yaml
tarot:
  reading:
    build:
      selectors: {stage: build, category: container}
      position: action
      # Override: usar Dockerfile en lugar de Containerfile
      envs:
        CONTAINERFILE_NAME: "Dockerfile"
        BUILD_ARGS: "--no-cache --pull"
```

## 2. Secrets Específicos de Cards

### Card con Secrets Propios (Vault)

```yaml
cards:
  - name: push-image
    type: card
    labels: {stage: push, category: registry}
    # Esta card define sus propios secrets de Vault
    secrets:
      harbor-creds:
        location: vault
        path: chapter  # Vault path: secret/{spellbook}/{chapter}/publics/harbor-creds
        format: env
        keys: [HARBOR_USER, HARBOR_PASSWORD]
        staticData:
          HARBOR_REGISTRY: "harbor.fwck.svc.cluster.local"
          HARBOR_PROJECT: "fwck"
    container:
      image: quay.io/buildah/stable:latest
      command: ["sh", "-c"]
      args:
        - |
          buildah login -u ${HARBOR_USER} -p ${HARBOR_PASSWORD} ${HARBOR_REGISTRY}
          buildah push ${IMAGE_NAME}:${IMAGE_TAG}
```

**Ventajas:**
- ✅ Solo la card `push-image` tiene acceso a `HARBOR_USER` y `HARBOR_PASSWORD`
- ✅ Puedes reutilizar esta card en otros workflows sin configurar secrets
- ✅ El workflow no necesita saber sobre Harbor credentials

### Card con Secrets K8s

```yaml
cards:
  - name: deploy-k8s
    type: card
    labels: {stage: deploy}
    # Secrets K8s inline
    secrets:
      kubeconfig:
        contentType: file
        mountPath: /root/.kube/config
        content:
          config: |
            apiVersion: v1
            kind: Config
            clusters:
            - cluster:
                server: https://k8s.example.com
              name: prod
    container:
      image: bitnami/kubectl:latest
      command: ["kubectl", "apply", "-f", "deployment.yaml"]
```

## 3. Herencia y Merge de Secrets/Envs

### Jerarquía de Merge

```
tarot.secrets/envs (nivel workflow - compartido)
    ↓
baseCard.secrets/envs (definición de card)
    ↓
reading.secrets/envs (override en reading)
```

### Ejemplo Completo

```yaml
# Card con defaults
cards:
  - name: notify-slack
    type: card
    labels: {category: notification}
    # Defaults de la card
    envs:
      SLACK_CHANNEL: "#general"
      SLACK_USERNAME: "CI/CD Bot"
    secrets:
      slack-webhook:
        location: vault
        path: chapter
        keys: [SLACK_WEBHOOK_URL]
    container:
      image: curlimages/curl
      command: ["sh", "-c"]
      args:
        - |
          curl -X POST ${SLACK_WEBHOOK_URL} \
            -d "{\"channel\":\"${SLACK_CHANNEL}\",\"username\":\"${SLACK_USERNAME}\",\"text\":\"${MESSAGE}\"}"

# Workflow level - compartido por todas las cards
tarot:
  envs:
    MESSAGE: "Build completed"  # Compartido

  reading:
    # Uso 1: Defaults de la card
    notify-general:
      selectors: {category: notification}
      position: outcome

    # Uso 2: Override del channel
    notify-team:
      selectors: {category: notification}
      position: outcome
      envs:
        SLACK_CHANNEL: "#team-alerts"  # Override
        MESSAGE: "Deployment to production"  # Override

    # Uso 3: Override completo
    notify-urgent:
      selectors: {category: notification}
      position: outcome
      envs:
        SLACK_CHANNEL: "#alerts"
        SLACK_USERNAME: "🚨 ALERT BOT"
        MESSAGE: "URGENT: Build failed!"
```

**Resultado:**
- `notify-general`: usa #general con "Build completed"
- `notify-team`: usa #team-alerts con "Deployment to production"
- `notify-urgent`: usa #alerts con nombre y mensaje custom

## 4. Secrets Mixtos (Card + Workflow)

```yaml
# Card que necesita sus propios secrets
cards:
  - name: docker-build-push
    type: card
    labels: {category: docker}
    # Secrets específicos de la card
    secrets:
      registry-creds:
        location: vault
        path: chapter
        keys: [REGISTRY_USER, REGISTRY_PASSWORD]
    container:
      image: docker:latest
      command: ["sh", "-c"]
      args:
        - |
          docker login -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_URL}
          docker build -t ${IMAGE_NAME}:${VERSION} .
          docker push ${IMAGE_NAME}:${VERSION}

# Workflow level - secrets compartidos
tarot:
  secrets:
    # Config compartido por todas las cards
    build-config:
      contentType: env
      content:
        IMAGE_NAME: "myapp"
        VERSION: "1.0.0"
        REGISTRY_URL: "registry.company.com"

  reading:
    build:
      selectors: {category: docker}
      position: action
      # La card hereda build-config del workflow
      # Y usa registry-creds de su propia definición
```

**Resultado:**
- `IMAGE_NAME`, `VERSION`, `REGISTRY_URL` vienen del workflow (tarot.secrets)
- `REGISTRY_USER`, `REGISTRY_PASSWORD` vienen de la card (card.secrets)

## 5. Ejemplo Real: Pipeline Flexible

### Definición de Cards Reutilizables

```yaml
cards:
  # Card genérica de build
  - name: container-build
    type: card
    labels: {action: build}
    envs:
      DOCKERFILE: "Dockerfile"      # Configurable
      BUILD_CONTEXT: "."            # Configurable
      EXTRA_BUILD_ARGS: ""
    container:
      image: quay.io/buildah/stable
      command: ["sh", "-c"]
      args:
        - |
          buildah bud \
            -f ${DOCKERFILE} \
            ${EXTRA_BUILD_ARGS} \
            -t ${IMAGE} ${BUILD_CONTEXT}

  # Card genérica de push
  - name: registry-push
    type: card
    labels: {action: push}
    # Secrets específicos (no del workflow)
    secrets:
      registry:
        location: vault
        path: chapter
        keys: [REGISTRY_USER, REGISTRY_PASSWORD]
        staticData:
          REGISTRY_URL: "harbor.company.com"
    container:
      image: quay.io/buildah/stable
      command: ["sh", "-c"]
      args:
        - |
          buildah login -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY_URL}
          buildah push ${IMAGE}
```

### Uso en Diferentes Scenarios

**Scenario 1: Build estándar con Dockerfile**
```yaml
tarot:
  envs:
    IMAGE: "myapp:latest"
  reading:
    build:
      selectors: {action: build}
      position: action
      # Usa defaults (Dockerfile)
    push:
      selectors: {action: push}
      position: outcome
      depends: [build]
```

**Scenario 2: Build con Containerfile custom**
```yaml
tarot:
  envs:
    IMAGE: "myapp:latest"
  reading:
    build:
      selectors: {action: build}
      position: action
      envs:
        DOCKERFILE: "Containerfile.alpine"  # Override
        BUILD_CONTEXT: "./src"              # Override
    push:
      selectors: {action: push}
      position: outcome
      depends: [build]
```

**Scenario 3: Multi-arch build**
```yaml
tarot:
  envs:
    IMAGE_BASE: "myapp"
    VERSION: "v1.0.0"
  reading:
    build-amd64:
      selectors: {action: build}
      position: action
      envs:
        IMAGE: "${IMAGE_BASE}:${VERSION}-amd64"
        EXTRA_BUILD_ARGS: "--platform linux/amd64"

    build-arm64:
      selectors: {action: build}
      position: action
      envs:
        IMAGE: "${IMAGE_BASE}:${VERSION}-arm64"
        EXTRA_BUILD_ARGS: "--platform linux/arm64"

    push-amd64:
      selectors: {action: push}
      position: outcome
      depends: [build-amd64]
      envs:
        IMAGE: "${IMAGE_BASE}:${VERSION}-amd64"

    push-arm64:
      selectors: {action: push}
      position: outcome
      depends: [build-arm64]
      envs:
        IMAGE: "${IMAGE_BASE}:${VERSION}-arm64"
```

## Beneficios del Approach

1. **Encapsulación**: Cada card es auto-contenida con sus dependencias
2. **Reusabilidad**: Misma card en múltiples workflows sin reconfigurar secrets
3. **Seguridad**: Secrets solo expuestos a cards que los necesitan
4. **Flexibilidad**: Parámetros pueden ser overridden según necesidad
5. **Simplicidad**: Workflow no necesita conocer detalles internos de las cards
6. **Mantenibilidad**: Cambios en secrets de card no afectan al workflow

## Best Practices

✅ **DO**: Define secrets en la card si solo esa card los necesita
✅ **DO**: Define parámetros con defaults razonables
✅ **DO**: Usa envs a nivel workflow para config compartida
✅ **DO**: Override parámetros en reading cuando sea necesario

❌ **DON'T**: Pongas todos los secrets en tarot.secrets
❌ **DON'T**: Dupliques secrets entre cards y tarot
❌ **DON'T**: Uses valores hardcodeados cuando deberían ser parámetros
❌ **DON'T**: Expongas secrets innecesariamente a todas las cards
