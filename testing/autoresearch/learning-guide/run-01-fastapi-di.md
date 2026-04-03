# Run 01: Explain FastAPI Dependency Injection to Django Developer

## Source Repo: fastapi-template
## Key Files: backend/app/api/deps.py, backend/app/api/routes/login.py

## Teaching Output

### What You Already Know (Django Anchor)

In Django, when you need the current user in a view, you use `@login_required` or check `request.user`. When you need a database connection, Django gives it to you automatically via the ORM. You never think about "injecting" these things — they're just there.

FastAPI makes you think about it explicitly. This is actually an advantage, not extra work.

### The Core Idea: Functions That Provide Things

In FastAPI, a "dependency" is just a function that returns something your endpoint needs. Look at this from `deps.py`:

```python
def get_db() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session
```

This is a generator that opens a DB session, hands it to your endpoint, and closes it after. In Django terms, it's like a context manager that wraps every view — but you pick which views use it.

### How Endpoints Consume Dependencies

```python
SessionDep = Annotated[Session, Depends(get_db)]

@router.post("/login/access-token")
def login_access_token(session: SessionDep, form_data: ...):
    user = crud.authenticate(session=session, ...)
```

`SessionDep` is a type alias: "give me a `Session`, and get it by calling `get_db()`." When FastAPI sees this parameter, it calls `get_db()` before your function runs, and passes the result as `session`.

### The Chain: Dependencies Can Have Dependencies

This is where it gets powerful. Look at how auth works:

```python
def get_current_user(session: SessionDep, token: TokenDep) -> User:
    payload = jwt.decode(token, ...)
    user = session.get(User, token_data.sub)
    return user

CurrentUser = Annotated[User, Depends(get_current_user)]
```

`get_current_user` itself depends on `SessionDep` (database) and `TokenDep` (OAuth2 token). FastAPI resolves the whole chain automatically.

### Django Equivalent (Conceptual)

| Django Pattern | FastAPI Dependency |
|---|---|
| `request.user` (from middleware) | `CurrentUser = Depends(get_current_user)` |
| Django ORM auto-connection | `SessionDep = Depends(get_db)` |
| `@login_required` decorator | Adding `current_user: CurrentUser` as parameter |
| `@user_passes_test(is_superuser)` | `Depends(get_current_active_superuser)` |

### Why This Matters

1. **Testability**: You can override any dependency in tests: `app.dependency_overrides[get_db] = get_test_db`
2. **Explicit**: No hidden middleware magic — you see exactly what each endpoint needs
3. **Composable**: Build complex auth chains from simple functions
4. **Type-safe**: IDE knows `session` is a `Session`, not `Any`

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: YES - Started with Django patterns the learner already knows
- **Progressive disclosure**: PARTIAL - Jumped from basic deps to chaining somewhat quickly. Could benefit from an intermediate step showing a simple custom dependency before the auth chain.
- **Practical examples**: YES - Used real code from the repo
- **Multiple explanation approaches**: PARTIAL - Used code + table, but no diagram/visual analogy
- **Verify understanding**: NO - No exercises or check questions provided

### Prompt Gaps Identified
1. **No explicit instruction to create a "bridge" from the learner's known framework** — the prompt says "assess knowledge level" but doesn't say "start from what they know"
2. **No instruction to provide exercises or self-check questions** — Focus Areas mention "Understanding Verification" but Key Actions don't require it in every output
3. **No instruction for visual/diagrammatic explanation** — some learners need flow diagrams, not just code
4. **No instruction to warn about common pitfalls** when transitioning between frameworks (e.g., "you might instinctively reach for middleware — here's why DI is different")
