# First Principles of Software

## The 4 Components

Every software system ever built has exactly 4 components:

1. **Data** — what the system stores (models, schemas, relationships, constraints)
2. **Logic** — what the system does with data (APIs, business rules, validations, services)
3. **Interface** — how users interact (pages, forms, buttons, responses)
4. **Infrastructure** — where it runs (database, server, cache, storage, deployment)

Plus **cross-cutting concerns** that touch everything: security, logging, error handling, testing.

## The Build Order

Dependencies dictate sequence:
```
Infrastructure FIRST → Data SECOND → Logic THIRD → Interface LAST
```

You can't build APIs without models. You can't build pages without APIs.

## Production vs Prototype

| Prototype | Production |
|-----------|-----------|
| Code runs | Code runs AND is tested |
| Data saves | Data saves AND is validated |
| Users log in | Users can't access other users' data |
| Errors crash | Errors caught, logged, shown helpfully |
| One user | Multiple concurrent users, isolated |
| Works today | Works after changes (regression tests) |
| Code exists | Code documented + auditable |

The difference: **verification at every step**.

## What You Need to Start

1. **Problem + User** — who has what problem?
2. **Data model** — what entities, fields, relationships?
3. **Tech stack** — what technologies fit?
4. **Rules** — security, permissions, business logic?
5. **Pages** — what does the user see and do?

These 5 answers become your SPEC.md.
