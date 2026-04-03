# Run 10: medusa — TypeScript `any` types hiding security bugs, innerHTML usage, IDOR patterns

## Target
- Repo: `/home/intruder/projects/forge-test-repos/medusa`
- Scope: TypeScript type safety, XSS, authorization

## Files Examined
- `packages/core/` — 62 occurrences of `: any` or `as any` in core packages alone
- `www/packages/docs-ui/src/components/MermaidDiagram/index.tsx` — dangerouslySetInnerHTML
- `www/packages/docs-ui/src/components/Breadcrumbs/index.tsx` — dangerouslySetInnerHTML
- `packages/medusa/src/utils/middlewares/authenticate-middleware.ts` — re-export
- `packages/medusa/src/api/` — route handlers

## Security Findings

### 1. Widespread `any` usage in core packages (MEDIUM)
- 62+ occurrences of `: any` or `as any` in `packages/core/` alone.
- **Files of concern**:
  - `packages/core/orchestration/src/joiner/remote-joiner.ts` — 35 occurrences
  - `packages/core/orchestration/src/workflow/local-workflow.ts` — type-unsafety in workflow execution
- **Issue**: `any` types bypass TypeScript's type checker, allowing runtime type errors that could be security-relevant (e.g., expected string gets object, enabling injection).

### 2. dangerouslySetInnerHTML in docs components (LOW)
- **File**: `www/packages/docs-ui/src/components/MermaidDiagram/index.tsx:86`
  - `dangerouslySetInnerHTML={result ? { __html: result.svg } : undefined}`
- **File**: `www/packages/docs-ui/src/components/Breadcrumbs/index.tsx:110`
  - `dangerouslySetInnerHTML={{ __html: jsonLdData }}`
- **Context**: These are in the docs site (www/), not the core API. The SVG comes from mermaid rendering (not user input), and jsonLdData is structured data. Low risk but should use DOMPurify for SVG.

### 3. Route parameters used without ownership validation (MEDIUM)
- **Files**: Multiple route handlers in `packages/medusa/src/api/admin/` and `packages/medusa/src/api/store/`
- Pattern: `req.params.id` used directly in service calls like:
  ```ts
  req.params.id,
  req.queryConfig.fields
  ```
- While admin routes have authentication middleware, store routes accessing resources by ID (e.g., `GET /store/product-tags/:id`) need to verify the caller has access to that specific resource (IDOR check).
- The authenticate middleware is a thin re-export: `export const authenticate = originalAuthenticate` — actual implementation is in `@medusajs/framework/http`.

### 4. qs.parse vulnerability (reinforced from Run 03) (HIGH)
- `arrayLimit: Infinity` on all query parsing — this is a DoS vector.

### 5. No Content-Security-Policy evident (LOW)
- For the admin dashboard and storefront, no CSP headers found. Lower priority for API-first architecture.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| TypeScript `any` abuse | NO | Prompt has no TypeScript-specific guidance |
| dangerouslySetInnerHTML | NO | Not in grep patterns |
| IDOR in route params | PARTIAL | Prompt says "check auth on endpoints" but not IDOR specifically |
| qs.parse DoS | NO | No input parsing DoS guidance |
| Missing CSP | NO | No security headers checklist |

## GAPs Identified
1. **GAP: No TypeScript/frontend security checklist** — needs: `any` type audit, dangerouslySetInnerHTML, innerHTML, XSS via template literals, IDOR via route params
2. **GAP: No IDOR-specific checklist** — needs: verify resource ownership on every endpoint that takes an ID parameter, check that store endpoints filter by customer/session
3. **GAP: No Content-Security-Policy guidance** — needs: CSP headers for admin panels and dashboards
