# Contributing to Documentation

Guide for contributing to runik-system documentation.

## Local Development

### Prerequisites

```bash
# Install Python 3.x
python --version  # Should be 3.x

# Install MkDocs and dependencies
pip install mkdocs-material
pip install mkdocs-git-revision-date-localized-plugin
pip install pymdown-extensions
```

### Serve Documentation Locally

```bash
# From repository root
mkdocs serve

# Open browser to http://127.0.0.1:8000
```

**Live reload:** Changes to markdown files auto-refresh the browser.

### Build Documentation

```bash
# Build static site
mkdocs build

# Output in site/ directory
# Test by serving: python -m http.server 8000 -d site/
```

### Validate Configuration

```bash
# Check for errors
mkdocs build --strict

# Will fail on warnings (good for CI)
```

## Documentation Structure

```
docs/
├── index.md                    # Home page
├── NAVIGATION.md               # Documentation guide
├── GETTING_STARTED.md          # Tutorial
├── GLOSSARY.md                 # Terminology
├── [Component docs]            # Core components
├── glyphs/                     # Individual glyph docs
├── stylesheets/
│   └── extra.css               # Custom styles
└── CONTRIBUTING_DOCS.md        # This file

mkdocs.yml                      # Site configuration
.github/workflows/docs.yml      # Auto-deployment
```

## Writing Guidelines

### File Organization

- **Keep files in docs/**: All documentation goes in docs/ directory
- **Use clear names**: Descriptive filenames (TESTING.md, not test.md)
- **Group related docs**: Use subdirectories for related content (docs/glyphs/)

### Markdown Style

**Use clear headers:**
```markdown
# Top Level (Page Title)
## Major Sections
### Subsections
```

**Code blocks with language:**
```markdown
​```bash
make test
​```

​```yaml
name: my-app
​```
```

**Admonitions for callouts:**
```markdown
!!! tip "Helpful tip"
    This is a tip box

!!! warning "Important warning"
    This is a warning

!!! info "Information"
    This is informational

!!! success "Success"
    This is a success message
```

**Tables:**
```markdown
| Column 1 | Column 2 |
|----------|----------|
| Value    | Value    |
```

### Navigation

Update `mkdocs.yml` nav section when adding new pages:

```yaml
nav:
  - Section Name:
    - Page Title: FILE.md
```

### Cross-References

Use relative links:
```markdown
See [Testing Guide](TESTING.md) for details.
See [Vault Glyph](glyphs/vault.md) for Vault integration.
```

### Examples

Always include working examples:

```markdown
## Example

​```yaml
# Working example
name: my-app
image:
  repository: nginx
  tag: alpine
​```
```

## Style Guide

### Keep it Simple

- ✅ Direct technical language
- ✅ Short sentences
- ✅ Scannable sections
- ❌ No marketing fluff
- ❌ No unnecessary adjectives

### Be Concise

- ✅ One concept per section
- ✅ Clear code examples
- ✅ Practical use cases
- ❌ No rambling explanations
- ❌ No redundant content

### Be Holistic

- ✅ Show how components relate
- ✅ Link to related docs
- ✅ Provide learning paths
- ✅ Include "See Also" sections

## Common Tasks

### Add New Component Documentation

1. Create `docs/MY_COMPONENT.md`
2. Add to `mkdocs.yml` nav
3. Add cross-references from related docs
4. Test locally: `mkdocs serve`
5. Commit and push

### Update Existing Documentation

1. Edit markdown file in docs/
2. Test locally: `mkdocs serve`
3. Verify links work
4. Check formatting
5. Commit with descriptive message

### Add New Glyph Documentation

1. Create `docs/glyphs/my-glyph.md`
2. Add to `mkdocs.yml` under "Individual Glyphs"
3. Update `docs/GLYPHS_REFERENCE.md`
4. Test locally
5. Commit

## Deployment

### Automatic Deployment

GitHub Actions automatically deploys on push to `main`:

```yaml
# Triggered when these change:
- docs/**
- mkdocs.yml
- .github/workflows/docs.yml
- README.md
- CODING_STANDARDS.md
- GOOD_PRACTICES.md
```

**Process:**
1. Push to main branch
2. GitHub Actions runs
3. Builds site with `mkdocs build`
4. Deploys to `gh-pages` branch
5. Live at https://runik-spells.github.io/runik-system

**Check deployment:**
- Go to repo → Actions tab
- Look for "Deploy Documentation" workflow
- Check for green checkmark

### Manual Deployment

```bash
# Build and deploy to gh-pages
mkdocs gh-deploy

# Force deployment
mkdocs gh-deploy --force
```

## Troubleshooting

### "Can't find mkdocs command"

```bash
pip install mkdocs-material
```

### "Navigation not updating"

Clear browser cache or use incognito mode.

### "Build failing in GitHub Actions"

Check the Actions tab for error details. Common issues:
- Broken links
- Missing files
- YAML syntax errors in mkdocs.yml

### "Page not showing in navigation"

Verify entry in `mkdocs.yml` nav section.

### "Code blocks not highlighting"

Add language identifier:
```markdown
​```bash  # ← This!
command here
​```
```

## Testing Checklist

Before committing documentation changes:

- [ ] Test locally with `mkdocs serve`
- [ ] All links work (no 404s)
- [ ] Code blocks have language identifiers
- [ ] Navigation is logical
- [ ] Cross-references are accurate
- [ ] Examples are working
- [ ] Formatting is clean
- [ ] No spelling errors

## See Also

- [MkDocs Documentation](https://www.mkdocs.org/)
- [Material Theme](https://squidfunk.github.io/mkdocs-material/)
- [Markdown Guide](https://www.markdownguide.org/)
