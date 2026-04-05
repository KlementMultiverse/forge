# Observer Review Criteria

When the observer spawns a reviewer subagent, use these criteria per file type.

## CLAUDE.md (max score: 5)
- [ ] Under 100 lines (+1)
- [ ] Has ## Tech Stack table (+1)
- [ ] Has ## Architecture Rules with MUST/NEVER format (+1)
- [ ] Has ## What NOT to Build (+1)
- [ ] Has ## Testing with actual commands (+1)

## SPEC.md (max score: 5)
- [ ] 20+ [REQ-xxx] tags (+1)
- [ ] ## Models with exact field types (+1)
- [ ] ## API Endpoints table with method/path/auth (+1)
- [ ] ## Requirements Traceability table (+1)
- [ ] Each REQ has ONE clear behavior, not compound (+1)

## design-doc.md (max score: 5)
- [ ] All 10 sections present (+1)
- [ ] Pydantic schema classes defined (+1)
- [ ] 15+ test scenarios (+1)
- [ ] 8+ "Will implement" decisions (+1)
- [ ] API contracts with request/response JSON (+1)

## models.py (max score: 5)
- [ ] Every model has [REQ-xxx] comment (+1)
- [ ] Field types match SPEC.md exactly (+1)
- [ ] Relationships defined (ForeignKey, ManyToMany) (+1)
- [ ] Meta class with ordering/indexes if needed (+1)
- [ ] Under 300 lines (+1)

## api.py (max score: 5)
- [ ] Django Ninja router (not DRF) (+1)
- [ ] Pydantic schemas for input/output (+1)
- [ ] Auth decorator on protected endpoints (+1)
- [ ] [REQ-xxx] comments on each endpoint (+1)
- [ ] Error handling with proper status codes (+1)

## tests.py (max score: 5)
- [ ] [REQ-xxx] in every test docstring (+1)
- [ ] Minimum 5 tests per issue (+1)
- [ ] Tests for happy path + error cases (+1)
- [ ] Uses correct test base class (+1)
- [ ] No implementation code imported in test setup (+1)

## docker-compose.yml (max score: 5)
- [ ] Volume mount for live reload (+1)
- [ ] Dev command (runserver/--reload) not production (+1)
- [ ] Database with healthcheck (+1)
- [ ] .env file referenced (+1)
- [ ] No hardcoded secrets (+1)

## Rating Scale
- 5/5: Production-ready, no issues
- 4/5: Good, minor suggestions only → PASS
- 3/5: Functional but missing key elements → NEEDS_FIX
- 2/5: Significant gaps → NEEDS_FIX
- 1/5: Wrong approach or mostly empty → NEEDS_FIX
