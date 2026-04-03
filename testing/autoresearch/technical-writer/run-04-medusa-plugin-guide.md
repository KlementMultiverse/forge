# Run 04: medusa -- Write plugin/extension development guide

## Task
Write a plugin/extension development guide for Medusa (open-source e-commerce platform).

## Code Read
- No medusa repo available locally
- Would need plugin system architecture, plugin examples, API contracts

## Prompt Evaluation

### What the prompt guided well
1. **CONTEXT step** -- would correctly guide reading of plugin system docs
2. **STRUCTURE step** -- "tutorial -> progressive" format is right for plugin development
3. **Practical Examples** focus area -- "Working code samples, step-by-step procedures, real-world scenarios" is exactly what plugin docs need
4. **Chaos Resilience** -- "Generated code has no comments -> read function names and test names to infer behavior" -- useful for understanding plugin APIs

### What the prompt missed or was weak on
1. **No plugin architecture overview instruction** -- Before writing a plugin, developers need to understand hooks, events, lifecycle. Prompt doesn't push for architecture-first documentation
2. **No "hello world plugin" instruction** -- Every plugin guide needs a minimal working example. Prompt doesn't specify minimal vs complete example
3. **No API surface documentation instruction** -- What hooks are available? What events can I listen to? Prompt doesn't push for exhaustive API listing
4. **No testing instruction for plugins** -- How do you test a plugin in isolation? Prompt doesn't differentiate "testing the project" from "testing an extension"
5. **No versioning/compatibility instruction** -- Plugin guides need: "Which versions of the host platform is this compatible with?" Prompt ignores version compatibility
6. **No publishing/distribution instruction** -- How to package and share a plugin. Prompt doesn't cover distribution
7. **No debugging instruction** -- How to debug a plugin (breakpoints, logging, common errors). Not in prompt

### Documentation Quality Score: 4/10
- Without codebase, would produce generic plugin guide
- Plugin development docs are highly project-specific -- generic guidance is nearly useless
- Missing: architecture overview, hello world, API surface, testing, publishing

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No architecture overview instruction | High | Add: "For extension/plugin docs, start with host system architecture: hooks, events, lifecycle, plugin contract" |
| No minimal example instruction | High | Add: "Always include a 'hello world' minimal working example before complex examples" |
| No API surface documentation | Medium | Add: "List all available extension points/hooks/events with signatures and descriptions" |
| No plugin testing instruction | Medium | Add: "Include testing guide specific to extensions: mocking the host, integration testing" |
| No version compatibility section | Medium | Add: "Document version compatibility matrix: which host versions are supported" |
| No publishing/distribution guide | Low | Add: "Include packaging and distribution instructions for extensions" |
