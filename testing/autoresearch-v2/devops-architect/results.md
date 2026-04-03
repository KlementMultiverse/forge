# Autoresearch V2 — @devops-architect Results

**Date**: 2026-04-02
**Repos tested**: axum (Rust), chi (Go), drf (Django REST Framework), pydantic (Python), taxonomy (Next.js)

## Edge Case 1: axum — Rust Dockerfile multi-stage build, cargo caching
**Repo**: axum

### Gap Found: No Rust-specific Dockerfile patterns
The agent's Dockerfile knowledge is Python-centric. Rust needs:
- Multi-stage build: `cargo-chef` for dependency caching (cook deps separate from app)
- `cargo build --release` in builder stage, copy only the binary to scratch/distroless
- `CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse` for faster downloads
- Static linking with `musl` target for scratch images: `rustup target add x86_64-unknown-linux-musl`
- Binary size: strip debug symbols with `strip` or `RUSTFLAGS="-C strip=symbols"`
- Final image can be `FROM scratch` (Rust binary needs no runtime) — not just `-slim`

### Gap Found: No compiled-language build caching strategies
The agent knows `pip cache` and `npm cache` but not `cargo-chef`, Go module caching, or general compiled-language dependency caching.

## Edge Case 2: chi — Go Dockerfile, minimal alpine image
**Repo**: chi

### Gap Found: No Go-specific Dockerfile patterns
Go needs:
- Multi-stage: `FROM golang:1.22-alpine AS builder` then `FROM scratch` or `FROM alpine:3.19`
- `CGO_ENABLED=0` for static binary (critical for scratch images)
- `go mod download` as separate layer for caching
- `GOPROXY=direct` or explicit proxy for corporate environments
- Copy only the binary: `COPY --from=builder /app/server /server`
- Health check with Go binary itself (no curl in scratch): use `CMD` with built-in health endpoint

## Edge Case 3: drf — Django deployment with gunicorn, static files
**Repo**: drf

### Gap Found: No Django static file collection in Dockerfile
The agent's Django Dockerfile patterns miss:
- `collectstatic` must run DURING build (not at runtime) with `DJANGO_SETTINGS_MODULE` set
- WhiteNoise for self-hosted static files (no separate nginx for simple deployments)
- `STATIC_ROOT` must be a volume or baked into the image
- `gunicorn --bind 0.0.0.0:8000 --workers $(( 2 * $(nproc) + 1 ))` worker formula
- Timeout settings: `--timeout 120 --graceful-timeout 30` for long DRF serialization

## Edge Case 4: pydantic — CI/CD for library (publish to PyPI)
**Repo**: pydantic

### Gap Found: No library CI/CD pipeline patterns
The agent knows app deployment but not library publishing:
- PyPI publishing workflow: build sdist + wheel, upload via `twine` or `uv publish`
- Version management: `hatch-vcs`, `setuptools-scm`, or manual in `pyproject.toml`
- Matrix testing: Python 3.9-3.13, with and without optional deps
- Type checking CI: `mypy --strict` or `pyright` as mandatory CI step
- Property-based testing with `hypothesis` in CI
- Trusted publishers (OIDC) for PyPI — no API tokens stored in secrets
- Changelog generation from conventional commits
- Pre-release publishing: `--pre` flag, test PyPI

## Edge Case 5: taxonomy — Next.js Docker, standalone output, edge runtime
**Repo**: taxonomy

### Gap Found: No Next.js-specific Docker/deployment patterns
Next.js has unique deployment needs:
- `output: 'standalone'` in `next.config.mjs` — copies only needed `node_modules`
- Three-stage build: deps install, build, run (copy `.next/standalone` + `.next/static` + `public`)
- `NEXT_TELEMETRY_DISABLED=1` in Dockerfile
- `sharp` for image optimization needs native deps in builder
- Environment variables at build time vs runtime: `NEXT_PUBLIC_*` baked at build, others at runtime
- `server.js` as entrypoint (not `next start`) for standalone
- Health check: `curl -f http://localhost:3000/api/health` (must create health endpoint)
- Edge runtime functions need different deployment (Vercel Edge, Cloudflare Workers)

## Summary of Gaps

| # | Gap | Severity | Fix Applied |
|---|-----|----------|-------------|
| 1 | No Rust Dockerfile patterns (cargo-chef, musl, scratch) | HIGH | YES |
| 2 | No compiled-language build caching strategies | HIGH | YES |
| 3 | No Go Dockerfile patterns (CGO_ENABLED=0, scratch, static binary) | HIGH | YES |
| 4 | No Django collectstatic in Dockerfile pattern | MEDIUM | YES |
| 5 | No library CI/CD pipeline patterns (PyPI, matrix testing, trusted publishers) | HIGH | YES |
| 6 | No Next.js Docker patterns (standalone output, sharp, build vs runtime env) | HIGH | YES |
| 7 | No edge runtime deployment patterns | MEDIUM | YES |

## Claude Code Pattern: Gate-Based Execution
From Claude Code's `autoDream.ts`, the three-gate pattern (time gate -> session gate -> lock gate) ensures expensive operations only run when truly needed, with cheapest checks first. Apply to CI/CD: structure pipeline stages with cheapest checks first (lint before build, unit tests before integration).
