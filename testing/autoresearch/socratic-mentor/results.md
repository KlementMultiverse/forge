# Socratic Mentor Agent - Autoresearch Results (10 Runs)

**Date:** 2026-04-02
**Agent:** /home/intruder/projects/forge/agents/universal/socratic-mentor.md

---

## Run 1: Why schema-per-tenant instead of row-level isolation?

**Input:** Guide discovery of why clinic-portal uses schema-per-tenant.

**Real Code Reference:** `/home/intruder/projects/clinic-portal/CLAUDE.md` Rule #4: "Database engine MUST be `django_tenants.postgresql_backend`"

**Socratic Flow Applied:**
1. Observation: "Look at the SHARED_APPS vs TENANT_APPS separation in settings. What do you notice?"
2. Pattern: "What happens to a SQL query when the schema changes? How does that affect data isolation?"
3. Principle: "What's the difference between logical isolation (WHERE tenant_id=X) and physical isolation (separate schemas)?"
4. Application: "If a developer forgets a WHERE clause with row-level isolation, what happens? What about with schema-per-tenant?"

**Principle Discovered:** Defense in depth — schema isolation makes accidental data leakage structurally impossible, not just logically prevented.

**Gap Found:**
- Agent prompt has NO architecture-level questioning patterns. All examples are code-level (naming, functions, classes).
- Missing: questions about infrastructure decisions, deployment patterns, database architecture.
- No SOLID principles mapped to infrastructure choices (schema-per-tenant = Interface Segregation at the data layer).

---

## Run 2: What design pattern does saleor's plugin system implement?

**Input:** Guide discovery of strategy pattern in saleor plugins.

**Real Code Reference:** `/home/intruder/projects/forge-test-repos/saleor/saleor/plugins/base_plugin.py` line 100 — `class BasePlugin:` with ~15 concrete implementations (OpenIDConnectPlugin, WebhookPlugin, UserEmailPlugin, etc.)

**Socratic Flow Applied:**
1. Observation: "Look at BasePlugin. How many classes extend it? What do they have in common?"
2. Pattern: "Each plugin overrides different methods but shares the same interface. Where have you seen this before?"
3. Principle: "What GoF pattern lets you swap algorithms/behaviors at runtime through a common interface?"
4. Validation: "This is the Strategy pattern — each plugin is an interchangeable strategy for handling events."

**Principle Discovered:** Strategy Pattern (GoF Behavioral) — plugins are runtime-swappable strategies.

**Gap Found:**
- Agent has a good GoF section but no guidance for recognizing patterns in REAL codebases (vs textbook examples)
- Real code rarely names things "Strategy" or "Observer" — agent needs patterns for recognizing unnamed implementations
- Missing: "How to ask questions that lead from concrete code to abstract pattern recognition"

---

## Run 3: Why does fastapi-template use dependency injection?

**Input:** Guide discovery of IoC principle in FastAPI's Depends().

**Real Code Reference:** `/home/intruder/projects/forge-test-repos/fastapi-template/backend/app/api/deps.py` — `SessionDep = Annotated[Session, Depends(get_db)]`, `CurrentUser = Annotated[User, Depends(get_current_user)]`

**Socratic Flow Applied:**
1. Observation: "Look at `deps.py`. What does `Depends(get_db)` do? Where does the Session come from?"
2. Pattern: "The route function doesn't create its own database session — it receives one. What principle does this follow?"
3. Principle: "What happens in testing if the route created its own DB connection? How does DI help?"
4. Application: "FastAPI's Depends is actually a service locator + DI container. How does this compare to Django's middleware approach?"

**Principle Discovered:** Inversion of Control — dependencies flow inward, not outward. Functions declare WHAT they need, not HOW to get it.

**Gap Found:**
- Agent's "Systems: Separation of concerns, dependency injection" under Clean Code is too brief
- No framework-comparative questioning (Django middleware vs FastAPI Depends vs Spring @Autowired)
- No questions about testability as a design quality (DI enables mocking)

---

## Run 4: What's wrong with the 130-line function in documents/api.py?

**Input:** Guide SRP discovery through _summarize_with_claude().

**Real Code Reference:** `/home/intruder/projects/clinic-portal/apps/documents/api.py` lines 24-153 — `_summarize_with_claude()` is 130 lines doing:
1. S3 file retrieval (lines 36-48)
2. API key checking (lines 50-51)
3. Content type mapping (lines 55-61)
4. Base64 encoding (lines 63-99)
5. Prompt construction (lines 101-116)
6. HTTP request building (lines 118-135)
7. API call execution (lines 136-138)
8. Response parsing (lines 139-140)
9. HTML sanitization (lines 141-142)
10. Markdown stripping (lines 144-149)

**Socratic Flow Applied:**
1. Observation: "How many distinct operations does _summarize_with_claude() perform? List them."
2. Pattern: "If S3 retrieval fails, you get an error at line 47. If the API call fails, you get an error at line 152. Are these the same KIND of error?"
3. Principle: "What would happen if you extracted each operation into its own function? How would error handling change?"
4. Application: "Clean Code says functions should do ONE thing. This function does TEN things. What would the refactored version look like?"

**Principle Discovered:** Single Responsibility Principle — each function should have one reason to change.

**Gap Found:**
- Agent prompt says "Functions: Small, single responsibility" but provides no questioning technique for COUNTING responsibilities in a real function
- No "list the verbs" technique (each verb = potential separate function)
- No guidance for progressive extraction questioning (start with the easiest extraction, work up)

---

## Run 5: Why do medusa packages use a types package?

**Input:** Guide dependency inversion discovery through medusa's `/packages/core/types/`.

**Real Code Reference:** `/home/intruder/projects/forge-test-repos/medusa/packages/core/types/src/` — contains 20+ type directories (address, cart, customer, fulfillment, etc.) shared across all packages.

**Socratic Flow Applied:**
1. Observation: "Medusa has a `types` package that other packages import. Why not define types in each package?"
2. Pattern: "If package A and package B both need a `Customer` type, and each defines their own — what happens when Customer changes?"
3. Principle: "What direction should dependencies flow? Should concrete packages depend on each other, or on shared abstractions?"
4. Application: "This is Dependency Inversion — high-level modules depend on abstractions (types), not on each other."

**Principle Discovered:** Dependency Inversion Principle (SOLID D) — depend on abstractions, not concretions.

**Gap Found:**
- Agent has GoF patterns but NO SOLID principles questioning framework
- SOLID is arguably more important than GoF for modern architecture discussions
- Missing: questions about package/module dependency direction

---

## Run 6: What happens if TenantMainMiddleware isn't position 0?

**Input:** Guide middleware ordering discovery.

**Real Code Reference:** `/home/intruder/projects/clinic-portal/CLAUDE.md` Rule #3: "TenantMainMiddleware MUST be position 0 in MIDDLEWARE — no exceptions"

**Socratic Flow Applied:**
1. Observation: "What does TenantMainMiddleware do? What happens to database queries before it runs?"
2. Pattern: "If AuthenticationMiddleware runs BEFORE TenantMainMiddleware, which schema does the auth query hit?"
3. Principle: "Middleware is a pipeline — order matters. What's the earliest possible point to set tenant context?"
4. Application: "This is the Chain of Responsibility pattern applied to HTTP processing."

**Principle Discovered:** Chain of Responsibility ordering — the pipeline sequence determines system behavior.

**Gap Found:**
- Agent has no questions about ORDER-DEPENDENT systems (middleware, event handlers, migration order)
- No "what breaks if we reorder?" questioning technique
- Missing: temporal coupling as a code smell

---

## Run 7: Why does saleor use DataLoaders?

**Input:** Guide N+1 problem discovery.

**Real Code Reference:** DataLoader files found in 10+ directories under `/home/intruder/projects/forge-test-repos/saleor/saleor/graphql/` (warehouse, translations, tax, shipping, etc.)

**Socratic Flow Applied:**
1. Observation: "Saleor has DataLoader classes in nearly every GraphQL resolver module. What problem do they solve?"
2. Pattern: "In a list query, if each item fetches its own related data — how many DB queries for 100 items?"
3. Principle: "DataLoaders batch + cache individual lookups into bulk queries. This is the N+1 problem."
4. Application: "Where in clinic-portal might N+1 issues hide? (Hint: listing workflows with their task counts)"

**Principle Discovered:** N+1 Query Problem — batch loading as a performance optimization pattern.

**Gap Found:**
- Agent has no performance-related questioning patterns
- No questions about database query efficiency, caching strategies, or batch processing
- Missing: the link between Clean Code and performance (sometimes clean abstraction causes N+1)

---

## Run 8: What pattern is VALID_TRANSITIONS dict?

**Input:** Guide state machine pattern discovery.

**Real Code Reference:** `/home/intruder/projects/clinic-portal/apps/workflows/models.py` lines 61-67 — `VALID_TRANSITIONS` dict on Task model.

**Socratic Flow Applied:**
1. Observation: "Look at the VALID_TRANSITIONS dict. What does the key represent? What do the values represent?"
2. Pattern: "If status is 'completed' and someone tries to transition to 'assigned' — what happens? Why?"
3. Principle: "This is a state machine encoded as a dictionary. States are keys, valid transitions are edges."
4. Application: "Where else in software do you see state machines? (HTTP connections, TCP, UI components)"

**Principle Discovered:** Finite State Machine pattern — explicit state + transition validation prevents invalid states.

**Gap Found:**
- State Machine is NOT in the GoF pattern list — agent only covers GoF 23 patterns
- Many important patterns are missing: State Machine, Repository, Unit of Work, CQRS, Event Sourcing
- Agent should cover "patterns beyond GoF" for modern development

---

## Run 9: Why does medusa use events instead of direct calls?

**Input:** Guide event-driven architecture discovery.

**Real Code Reference:** `eventBus.emit()` found in 10+ medusa packages (product, pricing, notification, inventory, etc.)

**Socratic Flow Applied:**
1. Observation: "When a product is created, medusa emits an event instead of directly calling the notification module. Why?"
2. Pattern: "What happens if the notification module is down? Does product creation fail?"
3. Principle: "Events decouple the producer from the consumer. The product module doesn't know WHO listens."
4. Application: "This is the Observer/Pub-Sub pattern at the architecture level. It enables loose coupling."

**Principle Discovered:** Event-Driven Architecture — loose coupling through asynchronous communication.

**Gap Found:**
- Agent covers Observer as a GoF pattern but NOT as an architectural pattern
- No questions about coupling at the MODULE level (vs class level)
- Missing: architectural patterns vs design patterns distinction

---

## Run 10: What's the difference between CASCADE and SET_NULL?

**Input:** Guide referential integrity discovery using real FK definitions.

**Real Code Reference:** `/home/intruder/projects/clinic-portal/apps/workflows/models.py`:
- `created_by = ForeignKey(User, on_delete=CASCADE)` (Task)
- `assigned_to = ForeignKey(User, on_delete=SET_NULL, null=True)` (Task)

**Socratic Flow Applied:**
1. Observation: "In the Task model, `created_by` uses CASCADE but `assigned_to` uses SET_NULL. Why different?"
2. Pattern: "If a user is deleted — should their created tasks vanish? Should assigned tasks become unassigned?"
3. Principle: "CASCADE = ownership (task can't exist without creator). SET_NULL = association (task survives without assignee)."
4. Application: "What about the Document model? `uploaded_by` uses SET_NULL — does that make sense for audit purposes?"

**Principle Discovered:** Referential integrity strategies reflect domain relationships — ownership vs association.

**Gap Found:**
- Agent has NO database design questioning patterns
- No questions about data modeling decisions, FK strategies, or normalization
- Missing: domain-driven design concepts (aggregates, entities, value objects)

---

## Summary of ALL Gaps Found

| # | Gap | Severity | Fix |
|---|-----|----------|-----|
| 1 | No architecture-level questioning (only code-level) | HIGH | Add Architecture Discovery section |
| 2 | No SOLID principles questioning framework | HIGH | Add SOLID section alongside GoF |
| 3 | No pattern recognition in unnamed implementations | HIGH | Add "recognizing patterns in the wild" |
| 4 | No responsibility-counting technique for SRP | MEDIUM | Add to function_discovery |
| 5 | No database design questioning patterns | HIGH | Add Data Modeling section |
| 6 | No performance-related questioning | MEDIUM | Add Performance Patterns section |
| 7 | No framework-comparative questioning | MEDIUM | Add cross-framework examples |
| 8 | No order-dependent system questioning | MEDIUM | Add temporal coupling section |
| 9 | Missing State Machine, Repository, CQRS patterns | HIGH | Add "Beyond GoF" patterns |
| 10 | No architectural vs design pattern distinction | MEDIUM | Add architecture section |
