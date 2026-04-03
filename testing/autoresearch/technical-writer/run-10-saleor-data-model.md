# Run 10: saleor -- Write data model documentation with entity relationship diagram

## Task
Write data model documentation with entity relationship diagram for Saleor.

## Code Read
- No saleor repo available locally
- Would need models.py across all apps, foreign key relationships, through tables

## Prompt Evaluation

### What the prompt guided well
1. **RESEARCH step** -- "Read the actual code being documented -> extract function signatures, class hierarchies" -- class hierarchies is exactly what data model docs need
2. **Content Structure** -- "Information architecture, navigation design" -- data models benefit from hierarchical organization
3. **Technical Specifications** output type -- "Clear system documentation with architecture details" covers data model docs

### What the prompt missed or was weak on
1. **No ER diagram generation instruction** -- Prompt mentions no diagramming tools or formats (Mermaid, dbdiagram.io, PlantUML). Data model docs without diagrams are incomplete
2. **No relationship documentation instruction** -- Foreign keys, many-to-many, one-to-one relationships need explicit documentation. Prompt doesn't push for relationship mapping
3. **No field-level documentation instruction** -- What does each field mean? What are the constraints (max_length, null, unique)? Prompt doesn't push for field catalog
4. **No migration history context** -- Data model docs should note: which fields were added when, what breaking changes occurred. Prompt doesn't push for evolution context
5. **No index documentation** -- Which fields are indexed? Why? Performance implications. Prompt doesn't push for index catalog
6. **No data flow documentation** -- Where does data enter the system? How does it flow between models? Prompt doesn't push for data flow diagrams
7. **No "common query patterns" instruction** -- Developers need to know: how to query for X, how to join Y with Z. Prompt doesn't push for query recipe documentation

### Documentation Quality Score: 4/10
- Without codebase, data model docs are impossible to write accurately
- Prompt has no diagram generation capability or instruction
- Missing: ER diagrams, relationship mapping, field catalog, query patterns

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No diagram generation instruction | High | Add: "For data model docs, produce ER diagrams using Mermaid syntax (```mermaid erDiagram ...```)" |
| No relationship documentation | High | Add: "Document all model relationships: type (FK, M2M, O2O), cascade behavior, related_name" |
| No field catalog instruction | Medium | Add: "Produce field catalog: name, type, constraints, description for each model" |
| No migration history context | Low | Add: "Note significant schema changes and migration history for evolved models" |
| No index documentation | Medium | Add: "Document database indexes: which fields, why, performance implications" |
| No common query patterns | Medium | Add: "Include 5-10 common query patterns with ORM code examples" |
