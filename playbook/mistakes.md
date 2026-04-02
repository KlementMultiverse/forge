# Common Mistakes to Avoid

This file tracks error patterns with prevention strategies.

## Build Mistakes

1. **Retrying without investigating** — Got an error → just tried again → same error.
   Prevention: Always /investigate first. Understand WHY before fixing.

2. **Fixing one function, not all** — Added error handling to one S3 function but not the other two in the same module.
   Prevention: When improving a pattern, apply to ALL functions in the module.

3. **Late security middleware** — Built 6 phases before adding tenant access control.
   Prevention: Security middleware in Phase 1 (foundation), not as a patch.

4. **Mixing deployment into core** — Railway URLs, ngrok domains in settings.py from day 1.
   Prevention: Core build is local-only. Deployment config is a separate phase.

5. **Shared cookie domain** — Set SESSION_COOKIE_DOMAIN to shared domain → sessions leaked across subdomains.
   Prevention: Use per-subdomain cookies (SESSION_COOKIE_DOMAIN = None).

## Specification Mistakes

6. **Missing scope guards** — AI chat answered any question including politics, sports, jokes.
   Prevention: Scope guards designed in spec, not added after demo.

7. **Poor demo data** — Seed command created 2 workflows with 4 tasks. Not enough for demo.
   Prevention: Rich seed data (4+ workflows, 20+ tasks, multiple statuses) from first spec.

8. **Admin as afterthought** — Basic Django admin, no role badges, no tenant display.
   Prevention: Admin customizations specified in the spec alongside models.

## API Mistakes

9. **Using non-existent parameters** — Called NinjaAPI(csrf=True) which doesn't exist.
   Prevention: Verify API parameters exist in installed library version before using. Use context7.
