# Getting Started

Use a clean repository to host your bookrack and add runik-system as a submodule for charts (librarian, kaster, summon, trinkets) and, if needed, the covenant chart. Books live in your repo; runik-system stays vendored.

## Prerequisites
- Kubernetes 1.20+, kubectl, Helm 3.8+
- ArgoCD in cluster
- Git access to create your own repo

## One-Time Setup (new bookrack repo)
1) Create a fresh repo
```bash
mkdir my-spellbooks && cd my-spellbooks
git init
```

2) Add runik-system as a submodule
```bash
git submodule add https://github.com/runik-spells/runik-system.git vendor/runik-system
```
- Librarian chart: `vendor/runik-system/librarian`
- Covenant chart (if you manage realms): `vendor/runik-system/covenant`

3) Create your bookrack structure
```bash
mkdir -p bookrack/my-book/{_lexicon,development}
cat > bookrack/my-book/index.yaml <<EOF2
name: my-book
description: "Example book"
chapters:
  - development
EOF2

cat > bookrack/my-book/development/example-app.yaml <<EOF2
name: example-app
namespace: example-app
image:
  repository: nginx
  tag: alpine
service:
  enabled: true
  ports:
    - port: 80
EOF2
```

4) Point tests to your bookrack
```bash
export COVENANT_BOOKRACK_PATH=$(pwd)/bookrack
export COVENANT_CHART_PATH=$(pwd)/vendor/runik-system/covenant
```

## Run Tests
```bash
# From your repo root
make -C vendor/runik-system test
make -C vendor/runik-system test book my-book --chapter development

# Covenant (if applicable)
make -C vendor/runik-system test-covenant BOOK=covenant-tyl --all-chapters
```

## Deploy
```bash
helm install librarian ./vendor/runik-system/librarian \
  --set name=my-book \
  --namespace argocd
# Package or mount your bookrack/ content alongside the release (e.g., include it in the chart package or sync via GitOps).
```

## Notes
- Keep bookrack content (books/chapters/spells) in your repo; do not place it inside the runik-system submodule.
- Update the submodule to pull chart fixes: `git submodule update --remote vendor/runik-system` (pin to a tag/commit for stability).
- Example fixtures in `vendor/runik-system/bookrack/example-tdd-book/` are for tests only; keep your production config in your repo.
