# Autoresearch V2 — @playwright-critic Results

**Date**: 2026-04-02
**Repos tested**: taxonomy (Next.js), clinic-portal (Django multi-tenant)

## Edge Case 1: taxonomy — Test the dark mode toggle
**Repo**: taxonomy

### Gap Found: No CSS theme testing patterns
Dark mode testing requires:
- Check `prefers-color-scheme` media query response
- Test `data-theme` or class-based toggle (`class="dark"` on `<html>`)
- Verify CSS custom properties change (e.g., `--background` switches from light to dark values)
- Test persistence: toggle dark mode, navigate, verify it persists
- Test system preference: emulate `prefers-color-scheme: dark` via Playwright's `colorScheme` option
- Verify no flash of unstyled content (FOUC) on page load in dark mode

### Gap Found: No `page.emulateMedia()` usage pattern
Playwright can emulate color scheme: `page.emulateMedia({ colorScheme: 'dark' })`. The agent doesn't mention this.

## Edge Case 2: taxonomy — Test the responsive navigation
**Repo**: taxonomy

### Gap Found: No responsive navigation testing patterns
Mobile navigation (hamburger menu) requires specific testing:
- Set viewport to mobile: `page.setViewportSize({ width: 320, height: 568 })`
- Verify desktop nav is hidden, mobile nav trigger is visible
- Click hamburger, verify menu opens with animation (wait for transition)
- Test all nav links in mobile menu
- Test closing: click outside, press Escape, click close button
- Verify no horizontal scroll at each breakpoint (320, 768, 1024, 1280)

### Gap Found: No CSS animation/transition waiting pattern
The agent's waiting patterns don't cover CSS transitions. Should use:
```python
# Wait for CSS transition to complete
page.locator(".nav-menu").wait_for(state="visible")
expect(page.locator(".nav-menu")).to_have_css("opacity", "1")
```

## Edge Case 3: taxonomy — Test authentication flow (if exists)
**Repo**: taxonomy

### Gap Found: No "feature absence" testing strategy
Taxonomy may or may not have auth. The agent should:
- First, detect if auth exists by checking for login pages, auth middleware, session cookies
- If auth exists: run full auth test suite
- If auth doesn't exist: explicitly report "No auth flow detected" and test that protected-looking routes are actually public
- Never silently skip — always report what was checked and what was found/not found

### Gap Found: No Next.js-specific auth testing patterns
Next.js auth (NextAuth.js) has specific testing needs:
- Session cookies with CSRF tokens
- API route auth (`/api/auth/session`)
- Middleware-based route protection (`middleware.ts`)
- Server-side auth checks in server components (not testable via browser — need API testing)

## Edge Case 4: taxonomy — Test SEO metadata rendering
**Repo**: taxonomy

### Gap Found: No SEO testing patterns
The agent tests interactive elements but not metadata:
- `<title>` tag content per page
- `<meta name="description">` per page
- Open Graph tags (`og:title`, `og:description`, `og:image`)
- Twitter Card tags (`twitter:card`, `twitter:title`)
- Canonical URL (`<link rel="canonical">`)
- JSON-LD structured data (`<script type="application/ld+json">`)
- Robots meta tag (no `noindex` on public pages)
- Sitemap existence (`/sitemap.xml`)
- Social share image dimensions and accessibility

### Gap Found: No `page.content()` or `page.evaluate()` usage for non-visible elements
SEO tags are in `<head>`, not visible. The agent should use:
```python
title = page.title()
description = page.locator('meta[name="description"]').get_attribute("content")
og_title = page.locator('meta[property="og:title"]').get_attribute("content")
```

## Edge Case 5: clinic-portal — Test tenant switching flow
**Repo**: clinic-portal

### Gap Found: No multi-tenant E2E testing patterns
Testing tenant isolation requires unique patterns:
- Test that Tenant A's data is NOT visible when logged into Tenant B
- Test tenant switching: login, switch tenant context, verify data changes
- Test subdomain-based routing (if applicable): `tenant1.app.com` vs `tenant2.app.com`
- Test shared data (public schema) is visible across tenants
- Test that API requests include tenant context (header, subdomain, or URL prefix)
- Test creating a new tenant and verifying isolation from day 1

### Gap Found: No schema-per-tenant test infrastructure
For django-tenants, E2E tests need:
- Multiple test tenants with different subdomains
- Test fixtures that create tenant-specific data
- Verification that database queries are scoped to the correct schema
- Cross-tenant data leak detection: create data in Tenant A, verify absence in Tenant B

## Summary of Gaps

| # | Gap | Severity | Fix Applied |
|---|-----|----------|-------------|
| 1 | No CSS theme/dark mode testing patterns | HIGH | YES |
| 2 | No `page.emulateMedia()` usage for theme testing | MEDIUM | YES |
| 3 | No responsive navigation testing patterns (hamburger, breakpoints) | HIGH | YES |
| 4 | No CSS animation/transition waiting pattern | MEDIUM | YES |
| 5 | No "feature absence" detection and reporting strategy | HIGH | YES |
| 6 | No Next.js-specific auth testing patterns (NextAuth, middleware) | MEDIUM | YES |
| 7 | No SEO metadata testing patterns | HIGH | YES |
| 8 | No `page.evaluate()` usage for non-visible elements | MEDIUM | YES |
| 9 | No multi-tenant E2E testing patterns | CRITICAL | YES |
| 10 | No schema-per-tenant test infrastructure guidance | HIGH | YES |

## Claude Code Pattern: Command Semantics
From Claude Code's `commandSemantics.ts`, different commands have different success criteria (grep exit code 1 = no matches, not error). Apply to E2E testing: different test assertions have different "success" definitions. A missing element could mean "feature not implemented" (not a bug) or "element not rendered" (a bug). The agent should classify test results with semantic context.
