# Changelog Learnings for Forge Agents

Consolidated from 5 test repos + Claude Code leak. Last updated: 2026-04-02.

---

## 1. Axum (Rust web framework) -- v0.7 -> v0.8 -> unreleased

### Breaking Changes
- **Path parameter syntax changed**: `/:single` and `/*many` -> `/{single}` and `/{*many}` (matchit 0.8). Old syntax panics at runtime to prevent silent behavior change.
- **All handlers require `Sync`**: Every handler and service added to `Router`/`MethodRouter` must be `Sync`.
- **`Option<Path<T>>` no longer swallows errors**: Previously swallowed all error conditions; now rejects the request in many cases. Same for `Option<Query<T>>`.
- **WebSocket `Message` uses `Bytes`/`Utf8Bytes`**: Replaced `Vec<u8>` and `String` variants.
- **`WebSocket::close` removed**: Users must send explicit close messages.
- **`Host` extractor moved to `axum-extra`**: Import path changed.
- **`serve` is now generic**: Over listener and IO types. `tcp_nodelay` removed; use `ListenerExt` instead.
- **Router fallbacks properly merged**: For nested routers (was a bug, now fixed behavior).
- **`axum::serve` applies `header_read_timeout` by default**: Security hardening -- previously no timeout.
- **MSRV bumped**: 1.75 (v0.8), then 1.78 (v0.8.5), then 1.80 (unreleased).

### Security Fixes
- **JSON body trailing characters**: v0.8.5 now rejects JSON request bodies with trailing characters after the JSON document. Agents must not rely on lenient JSON parsing.
- **header_read_timeout applied by default**: Prevents slow-header DoS attacks.

### New Patterns
- `ListenerExt::limit_connections` for connection limiting on `axum::serve`.
- `WebSocketUpgrade::requested_protocols` / `set_selected_protocol` for flexible subprotocol selection.
- `MethodRouter::method_filter` for custom method matching.
- `Redirect` constructors now accept `impl Into<String>` (more ergonomic).
- `OptionalFromRequest` implemented for `Multipart`, `Json`, `Extension`.
- WebSockets over HTTP/2 supported (change `get(ws)` to `any(ws)`).
- `method_not_allowed_fallback` for custom 405 responses.

### Agent Actions
| Agent | Action |
|---|---|
| @code-archaeologist | Flag `/:param` path syntax -- must be `/{param}`. Flag `WebSocket::close()` calls. Flag `use axum::extract::Host` (moved to axum-extra). |
| @security-engineer | Flag missing `header_read_timeout` awareness. Flag lenient JSON parsing assumptions. |
| @root-cause-analyst | If handler compile errors mention `Sync`, check that all handlers are `Send + Sync`. If `Option<Path<T>>` returns unexpected 400s, the v0.8 behavior change is likely the cause. |

---

## 2. Chi (Go router) -- v1.5 -> v5.0.12

### Breaking Changes
- **Import path changed twice**: `github.com/go-chi/chi` (v1.x) vs `github.com/go-chi/chi/v5` (v5.x). Projects may have either.
- **`chi.ServerBaseContext` deprecated**: Use `http.Server.BaseContext` from stdlib instead.

### Deprecations
- `chi.ServerBaseContext` -- replaced by stdlib `http.Server#BaseContext`.

### Migration Mistakes
- Allocation optimization in v1.5.2 was reverted because `go test -race` failed. Lesson: always run race detector after performance optimizations.
- v0.8.2 (of axum, but same pattern) was yanked due to unforeseen breaking change -- agents should be cautious about "minor" releases.

### Agent Actions
| Agent | Action |
|---|---|
| @code-archaeologist | Flag `chi.ServerBaseContext` usage -- deprecated since v1.5.1. Flag `github.com/go-chi/chi` without `/v5` suffix (outdated import path). |

---

## 3. Django REST Framework -- v3.15 -> v3.16 -> v3.17

### Breaking Changes
- **Python 3.8 dropped** (v3.16), **Python 3.9 dropped** (v3.17).
- **CoreAPI support removed** (v3.17). `coreapi` was deprecated since v3.15.0 and fully removed.
- **`AutoSchema._get_reference` removed** (v3.16) -- was deprecated.
- **Deprecated request wrapper code removed** (v3.16).
- **`OR` permission semantics changed** (v3.15): `permission1 | permission2` now has different behavior.
- **`pytz` dependency removed** (v3.15): DRF now uses `ZoneInfo` as primary timezone source.

### Security Fixes
- **XSS in browsable API** (v3.15.2): Potential XSS vulnerability fixed. Agents MUST ensure browsable API is disabled in production or that v3.15.2+ is used.
- **Token overwrite risk** (v3.17): Small risk of `Token` overwrite prevented.
- **Token generation refactored to use `secrets` module** (v3.17): More cryptographically secure than previous approach.

### Deprecations
- CoreAPI support -- fully removed in v3.17.
- `AutoSchema._get_reference` -- removed in v3.16.
- Old request wrapper methods -- removed in v3.16.

### New Patterns
- `LoginRequiredMiddleware` support (Django 5.1+, DRF 3.16).
- `UniqueConstraint` support in validators (v3.15+), with several subsequent bugfixes around nullable fields and `source` attribute handling.
- Function-based view decorators: `@versioning_class()`, `@content_negotiation_class()`, `@metadata_class()` (v3.17).
- `BigInteger` serialization to string (v3.17) -- useful for JS compatibility.
- `DurationField` output format specification (v3.17).
- Decorator order validation with `@api_view` (v3.17) -- catches out-of-order decorators.
- `OrderedDict` replaced with plain `dict` (v3.15+).

### Migration Mistakes
- `UniqueTogetherValidator` has had many bugs around: fields with `source` attribute, `SerializerMethodField`, nullable fields, condition references to read-only fields. Test unique constraint validation thoroughly.
- `SearchFilter` behavior changed to align with `django.contrib.admin` search in v3.15, then had regressions reverted in v3.15.1. Be cautious with custom `get_search_terms`.
- `CursorPagination` with nulls in ordering field: fix added then reverted. Still a known issue area.

### Agent Actions
| Agent | Action |
|---|---|
| @code-archaeologist | Flag `import coreapi` or `CoreAPI` schema generators -- removed in DRF 3.17. Flag `from pytz import` in DRF context -- use `zoneinfo` instead. Flag `AutoSchema._get_reference` -- removed. |
| @security-engineer | Flag browsable API enabled in production (XSS risk pre-3.15.2). Flag token generation not using `secrets` module. Ensure DRF >= 3.15.2. |
| @django-ninja-agent | Note: Our project uses Django Ninja, NOT DRF. But if any DRF patterns leak in, flag `rest_framework` imports immediately per CLAUDE.md rule #1. |
| @root-cause-analyst | If `UniqueTogetherValidator` fails unexpectedly, check for: fields with `source`, `SerializerMethodField` presence, nullable fields. These are known multi-version bug areas. |

---

## 4. Pydantic -- v1 -> v2.0 -> v2.13 (current)

### Breaking Changes (v1 -> v2) -- CRITICAL migration

**Method renames (all models):**
| V1 | V2 |
|---|---|
| `__fields__` | `model_fields` |
| `construct()` | `model_construct()` |
| `copy()` | `model_copy()` |
| `dict()` | `model_dump()` |
| `json()` | `model_dump_json()` |
| `json_schema()` | `model_json_schema()` |
| `parse_obj()` | `model_validate()` |
| `parse_raw()` | `model_validate_json()` |
| `from_orm()` | `model_validate()` with `from_attributes=True` |
| `update_forward_refs()` | `model_rebuild()` |

**Config changes:**
- `class Config:` inside model -> `model_config = ConfigDict(...)` class attribute.
- `allow_mutation` -> `frozen` (inverted logic).
- `allow_population_by_field_name` -> `populate_by_name`.
- `anystr_lower` -> `str_to_lower`, `anystr_upper` -> `str_to_upper`, `anystr_strip_whitespace` -> `str_strip_whitespace`.
- `orm_mode` -> `from_attributes`.
- `json_encoders` deprecated -> use `@field_serializer` / `@model_serializer` decorators.
- `smart_union` removed -- V2 default is smart union mode.
- `fields` config removed entirely.
- `underscore_attrs_are_private` removed -- now always True behavior.

**Field changes:**
- `Field(const=...)` removed.
- `Field(min_items=...)` -> `Field(min_length=...)`.
- `Field(max_items=...)` -> `Field(max_length=...)`.
- `Field(regex=...)` -> `Field(pattern=...)`.
- `Field(allow_mutation=...)` -> `Field(frozen=...)`.
- Field constraints no longer pushed down into generics. Use `Annotated[str, Field(pattern="...")]` inside `list[...]`.

**Structural changes:**
- `GenericModel` removed -- use `class MyModel(BaseModel, Generic[T])` directly.
- `__root__` field removed -- use `RootModel` instead.
- `GetterDict` removed (was implementation detail of `orm_mode`).
- Dataclasses: `__post_init__` now called AFTER validation (was before). `__post_init_post_parse__` removed.
- Dataclasses: `extra='allow'` no longer stores extra fields as attributes.
- Subclass serialization: V2 only includes fields defined on the annotated type, not all subclass fields. Use `serialize_as_any` to opt out.

**Serialization behavior:**
- `model_dump_json()` is compact (no spaces after `:` and `,`).
- Non-string dict keys serialized via `str(key)` -- `None` becomes `"None"` not `"null"`.

### Breaking Changes (v2.12 -> v2.13) -- Recent
- `serialize_as_any` caused regressions; new `polymorphic_serialization` option added as replacement.
- `PydanticUserError` changed from `TypeError` to `RuntimeError`.
- `model_fields_set` now tracks extra fields set after init.
- Discriminated unions: no longer falls back to trying all members when discriminator-selected variant fails serialization.
- `pydantic-core` merged into main pydantic repo.

### Migration Tool
- `pip install bump-pydantic` then `bump-pydantic my_package` -- automated V1->V2 code transformation.

### Agent Actions
| Agent | Action |
|---|---|
| @code-archaeologist | Flag ALL V1 method names (`.dict()`, `.json()`, `.parse_obj()`, `.copy()`, `.construct()`, `.from_orm()`). Flag `class Config:` inside models. Flag `Field(regex=...)`, `Field(min_items=...)`, `Field(const=...)`. Flag `from pydantic.generics import GenericModel`. Flag `__root__` field usage. Flag `json_encoders` in config. |
| @security-engineer | V2 subclass serialization change prevents accidental data leakage -- this is a security improvement. Flag code that relies on V1 behavior of serializing all subclass fields. |
| @root-cause-analyst | Common V1->V2 migration errors: (1) `.dict()` still works but emits deprecation warning -- silent in tests. (2) `__post_init__` running after validation breaks code that mutated data pre-validation. (3) `Field` constraints on `list[str] = Field(pattern=...)` silently stop working -- must use `Annotated`. (4) `None` key serialization changes break JSON API contracts. (5) `serialize_as_any` in v2.12 had regressions -- use `polymorphic_serialization` in v2.13+. |

---

## 5. Taxonomy (Next.js app) -- v0.2.0

### Key Observations
- Single commit repo (`feat: add t3-env for env var`). No changelog, minimal history.
- Uses Next.js 13.3.2-canary, React 18, Prisma 4, next-auth 4.22.1, contentlayer 0.3.1.
- TypeScript 4.7.4 (very outdated -- current is 5.x).
- Zod 3.21.4 for validation.
- Tailwind CSS + Radix UI component library.
- `@t3-oss/env-nextjs` for environment variable validation.

### Deprecations/Risks
- `contentlayer` is effectively abandoned (no updates since 2023). Projects should migrate to alternatives.
- Next.js 13 canary is ancient -- current is Next.js 15.x. App Router API has changed significantly.
- `next-auth` v4 -> v5 (Auth.js) is a major migration with breaking changes.
- Prisma 4 -> Prisma 6 has multiple breaking changes.
- `@tailwindcss/line-clamp` is deprecated -- line-clamp is now built into Tailwind CSS v3.3+.

### Agent Actions
| Agent | Action |
|---|---|
| @code-archaeologist | Flag `contentlayer` usage -- abandoned project. Flag `@tailwindcss/line-clamp` -- built into Tailwind 3.3+. Flag `next-auth` v4 imports if migrating to v5. Flag TypeScript < 5.0. |
| @root-cause-analyst | If contentlayer builds fail, it is likely due to incompatibility with newer Node.js versions. Known issue with no upstream fix. |

---

## 6. Claude Code (v2.1.88 leaked source)

### Architecture Patterns
- **Agentic loop**: `while(true)` async generator pattern -- query -> tool calls -> results -> loop.
- **Tool system**: 40+ tools with consistent interface (`Tool.ts` type definitions, `tools.ts` registry).
- **Memory system**: 4-type file-based memory (user/feedback/project/reference) with `MEMORY.md` index files.
- **MCP integration**: Full Model Context Protocol support (stdio/http/sse/websocket transports).
- **Skills system**: Reusable workflow templates in `SKILL.md` format with YAML frontmatter.
- **Custom agents**: Defined via `.claude/agents/*.md` files with YAML frontmatter.
- **Feature flags**: `bun:bundle` `feature()` function controls gating. All features default to disabled.

### Key Feature Flags (unreleased/internal)
- `KAIROS` -- Assistant mode.
- `PROACTIVE` -- Proactive suggestions.
- `BRIDGE_MODE` -- IDE bridge integration.
- `VOICE_MODE` -- Voice input.
- `COORDINATOR_MODE` -- Multi-agent orchestration.
- `EXTRACT_MEMORIES` -- Background memory extraction.
- `TEAMMEM` -- Team-shared memory.

### Extension Points (no source modification needed)
| Mechanism | Location | Format |
|---|---|---|
| Custom Skills | `.claude/skills/name/SKILL.md` | YAML frontmatter + Markdown |
| Custom Agents | `.claude/agents/name.md` | YAML frontmatter + Markdown |
| MCP Servers | `.mcp.json` | JSON config |
| Hooks | `~/.claude/settings.json` | JSON event-action mappings |

### Agent Actions
| Agent | Action |
|---|---|
| All agents | Use the skill/agent extension points rather than modifying source. Understand the agentic loop pattern for debugging agent behavior. |
| @security-engineer | Note: OAuth or API key auth required. If `ANTHROPIC_API_KEY` is set, it must be valid. Feature flags control access to unreleased capabilities. |

---

## Cross-Cutting Lessons for All Agents

### 1. Version pinning matters
Every repo shows cases where minor/patch releases introduced regressions (DRF 3.15.0 -> 3.15.1 reverts, Pydantic v2.12 serialize_as_any issues, axum 0.8.2 yanked). **Always pin exact versions in production.**

### 2. Deprecation warnings are real deadlines
DRF removed CoreAPI after 2+ years of deprecation warnings. Pydantic V1 methods still work in V2 but emit warnings. **Treat deprecation warnings as bugs, not noise.**

### 3. Security fixes hide in patch releases
DRF XSS fix was in 3.15.2, axum header_read_timeout in unreleased. **Always read patch release notes, not just major versions.**

### 4. Breaking changes in "non-breaking" releases
Pydantic v2.12's `serialize_as_any` behavior change was considered non-breaking per their versioning policy but broke many users. Chi v1.5.2 had a race condition from an "optimization." **Test thoroughly after any upgrade.**

### 5. Migration tools exist -- use them
Pydantic has `bump-pydantic`. DRF has deprecation warnings you can enable. **Always check if the library provides automated migration assistance.**

### 6. Validator/serializer edge cases are bug magnets
Both DRF and Pydantic have long histories of bugs around: nullable fields in unique constraints, nested serialization, discriminated unions, and custom field sources. **Test these patterns with explicit edge-case tests.**
