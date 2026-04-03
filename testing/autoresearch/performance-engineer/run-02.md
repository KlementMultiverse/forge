# Run 02: FastAPI Template - Async Patterns, Connection Pooling, SQLAlchemy

## Target
- Repo: fastapi-template (Python/FastAPI + SQLModel/SQLAlchemy)
- Focus: async patterns, connection pooling, query optimization

## Files Read
- `backend/app/main.py` - FastAPI app setup
- `backend/app/models.py` - SQLModel models
- `backend/app/crud.py` - CRUD operations
- `backend/app/api/deps.py` - Dependencies (DB session, auth)
- `backend/app/api/routes/items.py` - Item CRUD routes
- `backend/app/api/routes/users.py` - User routes
- `backend/app/core/db.py` - Database engine setup
- `backend/app/core/config.py` - Settings

## Findings

### 1. Sync Route Handlers in FastAPI (Major Issue)
ALL route handlers use `def` instead of `async def`:
```python
@router.get("/", response_model=ItemsPublic)
def read_items(session: SessionDep, current_user: CurrentUser, ...):
```
This forces FastAPI to run each handler in a thread pool worker instead of the async event loop. For I/O-bound operations (DB queries), this wastes thread pool capacity. However, since SQLModel's `Session` is synchronous, this is actually correct behavior - using `async def` with sync DB calls would block the event loop.

### 2. No Async Database Engine
```python
engine = create_engine(str(settings.SQLALCHEMY_DATABASE_URI))
```
Uses `postgresql+psycopg` (sync driver). No `create_async_engine` or async session. For high-concurrency FastAPI, this limits throughput to thread pool size.

### 3. No Connection Pool Configuration
`create_engine()` is called with zero pool configuration:
- No `pool_size`, `max_overflow`, `pool_timeout`, `pool_recycle`
- SQLAlchemy defaults (pool_size=5, max_overflow=10) may be too low for production

### 4. Count + Fetch = Two Queries
```python
count_statement = select(func.count()).select_from(Item)
count = session.exec(count_statement).one()
statement = select(Item).offset(skip).limit(limit)
items = session.exec(statement).all()
```
Every list endpoint runs two separate queries. Could use window functions or a single query with `ROW_COUNT`.

### 5. N+1 in User Listing
`read_users` returns user objects that have an `items` relationship. If the response model ever includes items count/data, it would trigger N+1. Currently safe because `UserPublic` excludes `items`.

### 6. No Index on Item.created_at
Item queries use `.order_by(col(Item.created_at).desc())` but the model doesn't have `index=True` on `created_at`:
```python
created_at: datetime | None = Field(default_factory=get_datetime_utc, sa_type=DateTime(timezone=True))
```
This will cause a full table scan + sort for pagination.

## Does the Current Prompt Guide Finding This?
**PARTIAL** - The prompt mentions "API response times" and "query optimization" but:
- **NO** guidance on async vs sync patterns in ASGI frameworks
- **NO** connection pool tuning checklist
- **NO** mention of missing database indexes as a detection target
- **NO** pattern for "two queries for pagination" anti-pattern
- **NO** mention of ASGI-specific considerations (thread pool vs event loop)

## Gaps to Fix
1. Add async/sync pattern analysis for ASGI frameworks (FastAPI, Starlette)
2. Add connection pool configuration checklist
3. Add missing index detection (query patterns vs model indexes)
4. Add pagination query optimization patterns
5. Add ASGI thread pool vs event loop guidance
