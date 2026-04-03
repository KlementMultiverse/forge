# Run 08: medusa -- Write package contribution guide for monorepo

## Task
Write a package contribution guide for Medusa's monorepo structure.

## Code Read
- No medusa repo available locally
- Would need monorepo structure, package manager config, contribution guidelines

## Prompt Evaluation

### What the prompt guided well
1. **CONTEXT step** -- Reading CONTRIBUTING.md and repo structure is the right first step
2. **Clear Communication** -- "Plain language usage, technical precision" -- important for contribution guides that target new contributors
3. **Chaos Resilience** -- "Empty codebase -> document architecture decisions" -- handles missing code

### What the prompt missed or was weak on
1. **No monorepo-specific documentation patterns** -- Monorepos need: package dependency graph, workspace commands, how changes in one package affect others. Prompt doesn't handle monorepo complexity
2. **No "how to add a new package" instruction** -- Contribution guides need: file structure template, registration steps, dependency declaration. Prompt doesn't push for scaffolding documentation
3. **No PR workflow documentation** -- Contribution guides need: branch naming, commit message format, review process, CI checks. Prompt doesn't push for workflow documentation
4. **No testing strategy per package** -- In monorepos, testing varies by package (unit, integration, e2e). Prompt doesn't push for per-package testing guidance
5. **No dependency management documentation** -- Monorepo dependency management (shared vs per-package, version resolution) is complex. Prompt doesn't address it
6. **No code style/linting documentation** -- Contribution guides need: formatter config, linter rules, pre-commit hooks. Prompt doesn't push for code standards documentation
7. **No "impact analysis" documentation** -- "I changed package X, what else might break?" is a critical monorepo question

### Documentation Quality Score: 4/10
- Monorepo contribution guides are highly project-specific
- Without codebase, would produce generic contribution guide
- Prompt's generic instructions produce generic output -- monorepo-specific patterns are missing

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No monorepo-specific patterns | High | Add: "For monorepos, document: package dependency graph, workspace commands, cross-package impact analysis" |
| No package scaffolding instruction | Medium | Add: "For extensible projects, document how to add new components/packages/modules" |
| No PR workflow documentation | High | Add: "Contribution guides MUST include: branch strategy, commit conventions, review process, CI checks" |
| No testing strategy per component | Medium | Add: "Document testing strategy per component: which test types, how to run, what coverage expected" |
| No dependency management docs | Medium | Add: "For multi-package projects, document dependency management: resolution strategy, version constraints" |
| No code standards documentation | Medium | Add: "Include code style guide: formatter, linter, pre-commit hooks, naming conventions" |
