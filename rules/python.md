# Python Rules

1. Use `uv` for package management — NEVER `pip install`
2. Format with `black` — run after every code generation
3. Lint with `ruff check --fix` — run after every code generation
4. Type hints on all function signatures
5. Use `logging` module — NEVER `print()` for operational output
6. External API calls: always `try/except` for timeout, connection, auth errors
7. Use `os.environ.get()` for config — NEVER hardcode values
8. Use `httpx` for async HTTP — NEVER `requests` in async context
9. Use `.get()` with defaults for dict access — NEVER bare `dict["key"]` on external data
10. Test with `pytest` or framework's test runner — NEVER manual verification
