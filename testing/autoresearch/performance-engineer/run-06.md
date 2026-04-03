# Run 06: FastAPI Template - Pydantic Validation Overhead, Response Serialization

## Target
- Repo: fastapi-template (Python/FastAPI + SQLModel/Pydantic)
- Focus: Pydantic model validation overhead, response serialization

## Files Read
- `backend/app/models.py` - All Pydantic/SQLModel models
- `backend/app/api/routes/items.py` - Item endpoints (response_model usage)
- `backend/app/api/routes/users.py` - User endpoints
- `backend/app/crud.py` - CRUD with model_validate

## Findings

### 1. Double Serialization in CRUD Operations
```python
def create_user(*, session: Session, user_create: UserCreate) -> User:
    db_obj = User.model_validate(user_create, update={"hashed_password": ...})
    session.add(db_obj)
    session.commit()
    session.refresh(db_obj)  # re-fetches from DB
    return db_obj
```
Then FastAPI serializes the returned User into UserPublic via `response_model`. So the flow is:
1. Pydantic validates input (UserCreate)
2. model_validate creates User from UserCreate
3. session.refresh re-reads from DB
4. FastAPI serializes User -> UserPublic via response_model

Step 3 is unnecessary if we trust the data we just wrote. Could skip refresh and return the object directly.

### 2. response_model Causes Full Re-serialization
Every endpoint uses `response_model=ItemPublic` or `response_model=UserPublic`. FastAPI internally calls `.model_validate()` on the return value to ensure it matches the response model. This is a Pydantic v2 validation pass on every response.

For list endpoints returning 100 items, this means 100 Pydantic validation calls.

### 3. No response_model_exclude_unset
List endpoints return full objects including null fields. Using `response_model_exclude_unset=True` could reduce JSON payload size.

### 4. Password Hashing Blocks the Thread
```python
hashed_password = get_password_hash(body.new_password)
```
Password hashing (Argon2) is CPU-intensive. Since all endpoints are sync (`def`, not `async def`), this runs in a thread pool worker. But the thread is blocked during hashing, reducing available workers. For high-concurrency, this could be a bottleneck.

### 5. Settings Parsed on Import
```python
settings = Settings()  # type: ignore
```
`pydantic_settings.BaseSettings` parses environment variables and runs validators on import. Includes `model_validator` for checking secrets. Minor cold-start cost.

## Does the Current Prompt Guide Finding This?
**NO** for serialization-specific patterns:
- **NO** Pydantic/serialization overhead analysis
- **NO** response_model performance implications
- **NO** session.refresh() cost awareness
- **NO** CPU-bound operation detection in async/threaded contexts
- **NO** cold start / import-time cost analysis

## Gaps to Fix
1. Add serialization/deserialization overhead analysis
2. Add framework-specific response pipeline cost (response_model, middleware chain)
3. Add CPU-bound vs I/O-bound operation detection in async contexts
4. Add unnecessary re-fetch detection (refresh after write)
