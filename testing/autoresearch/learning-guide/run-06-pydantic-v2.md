# Run 06: Explain Pydantic v2 Model Validation (fastapi-template)

## Source Repo: fastapi-template
## Key Files: backend/app/models.py, backend/app/core/config.py

## Teaching Output

### What Pydantic Does in One Sentence

Pydantic validates data coming into your Python program and converts it to the right types — at runtime, with type hints.

### Starting Point: SQLModel = Pydantic + SQLAlchemy

In fastapi-template, models use SQLModel which combines Pydantic validation with SQLAlchemy ORM. Let's separate the two concerns:

```python
# This is a PYDANTIC model (validation only, no database)
class UserBase(SQLModel):
    email: EmailStr = Field(unique=True, index=True, max_length=255)
    is_active: bool = True
    is_superuser: bool = False
    full_name: str | None = Field(default=None, max_length=255)
```

When someone POST's `{"email": "not-an-email", "is_active": "yes"}`, Pydantic:
1. Rejects `"not-an-email"` because `EmailStr` validates email format
2. Converts `"yes"` to `True` because `bool` coerces truthy strings
3. Sets `full_name` to `None` because it wasn't provided

### The Inheritance Pattern: Input vs Output vs Database

fastapi-template uses a common v2 pattern — different models for different purposes:

```python
# What comes IN from the API (creation)
class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)

# What comes IN from the API (update — all optional)
class UserUpdate(UserBase):
    email: EmailStr | None = Field(default=None)
    password: str | None = Field(default=None, min_length=8, max_length=128)

# What's stored in the DATABASE
class User(UserBase, table=True):
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    hashed_password: str  # Never exposed in API

# What goes OUT to the API
class UserPublic(UserBase):
    id: uuid.UUID
    created_at: datetime | None = None
```

**Why four models for one entity?**
- `UserCreate` requires password (can't create user without one)
- `UserUpdate` makes everything optional (partial updates)
- `User` has `hashed_password` (never returned to client)
- `UserPublic` excludes sensitive fields

### v2 Features in Action: computed_field and model_validator

From `config.py`:

```python
class Settings(BaseSettings):
    POSTGRES_SERVER: str
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str = ""
    POSTGRES_DB: str = ""

    @computed_field
    @property
    def SQLALCHEMY_DATABASE_URI(self) -> PostgresDsn:
        return PostgresDsn.build(
            scheme="postgresql+psycopg",
            username=self.POSTGRES_USER,
            password=self.POSTGRES_PASSWORD,
            host=self.POSTGRES_SERVER,
            port=self.POSTGRES_PORT,
            path=self.POSTGRES_DB,
        )
```

`@computed_field` (v2-only) makes a property that's included in serialization. The database URI is computed from individual settings, not stored separately. If you serialize `settings.model_dump()`, `SQLALCHEMY_DATABASE_URI` appears in the output.

```python
    @model_validator(mode="after")
    def _enforce_non_default_secrets(self) -> Self:
        self._check_default_secret("SECRET_KEY", self.SECRET_KEY)
        return self
```

`@model_validator(mode="after")` runs AFTER all fields are validated. "After" mode means all fields exist and are typed correctly. "Before" mode would run on raw input dict.

### v1 to v2 Migration Cheat Sheet

| v1 Pattern | v2 Equivalent | In This Codebase |
|---|---|---|
| `class Config: env_file=".env"` | `model_config = SettingsConfigDict(env_file=".env")` | config.py line 27 |
| `@validator("field")` | `@field_validator("field")` | Not used (uses model_validator) |
| `@root_validator` | `@model_validator(mode="after")` | config.py line 108 |
| `.dict()` | `.model_dump()` | Throughout |
| `Field(...)` with `regex=` | `Field(...)` with `pattern=` | Not in this codebase |

### Key v2 Behavioral Change: Strict vs Lax Mode

By default, Pydantic v2 uses "lax" mode — it coerces types when possible (`"123"` becomes `123`). In v1, this was always on. In v2, you can opt into strict mode per-field or per-model to reject type mismatches.

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: PARTIAL - Assumed Pydantic familiarity but didn't anchor to a specific "what you know" framework
- **Progressive disclosure**: YES - Simple validation → inheritance pattern → advanced features → migration guide
- **Practical examples**: YES - Real fastapi-template code
- **Multiple explanation approaches**: YES - Code, tables, migration cheat sheet
- **Verify understanding**: NO - No exercises

### Prompt Gaps Identified
1. **No instruction to include version migration context** — when explaining a v2 feature, learners coming from v1 need a translation table. The prompt should instruct: "if the technology has a major version change, include a migration reference"
2. **No instruction to explain the 'why' behind design decisions** — "why four models for one entity?" is a design insight, not just a code explanation. The prompt should require: "explain the reasoning behind patterns, not just the syntax"
3. **Recurring gap: no exercises**
