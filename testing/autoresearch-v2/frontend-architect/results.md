# @frontend-architect — Autoresearch V2 Edge Cases

## Research Sources
- "How to Think About Security in Next.js" (Next.js official blog)
- "Frontend Architecture: Building Scalable Next.js Applications" (Bit.src)
- "React & Next.js in 2025 - Modern Best Practices" (Strapi)
- CVE-2025-29927 analysis (multiple sources)

## Edge Case Tests (all on taxonomy)

### Test 1: App Router patterns (layout nesting, error boundaries, loading states)

**Input**: Scan taxonomy for App Router edge cases.

**Findings**:
- **CRITICAL GAP FOUND**: No `error.tsx` files found anywhere in taxonomy. Agent prompt's checklist item "Error boundaries: top-level and per-route error boundaries" correctly identifies this, but the detection method isn't automated — agent should grep for `error.tsx` absence.
- **GAP FOUND**: No `loading.tsx` files found. Agent prompt mentions "Loading states: all async components have explicit loading state" but doesn't specifically scan for missing `loading.tsx` in route segments.
- **GAP FOUND**: No `global-error.tsx` — root layout errors crash without fallback. Agent prompt doesn't distinguish `error.tsx` (segment-level) from `global-error.tsx` (root-level).
- **EDGE CASE**: taxonomy has `app/(editor)/` and `app/(dashboard)/` route groups — these share `layout.tsx` patterns but agent doesn't check for consistency across route groups.
- **GAP FOUND**: Agent prompt has no App Router file convention checklist. Missing scans for: `error.tsx`, `loading.tsx`, `global-error.tsx`, `not-found.tsx`, `template.tsx` presence at appropriate levels.

**Recommendation**: Add App Router file convention scanner.

### Test 2: Accessibility (dialog/modal focus trap, dynamic content announcements)

**Input**: Scan taxonomy for a11y edge cases.

**Findings**:
- **PASS**: taxonomy uses Radix UI primitives (via shadcn) which handle focus trapping, ARIA attributes, and keyboard navigation built-in. Agent's a11y checklist would correctly identify these as adequate.
- **GAP FOUND**: Agent prompt checks for `aria-live` regions and `role="alert"` but doesn't verify these are used consistently across all dynamic content. taxonomy's toast notifications (via `components/ui/toaster.tsx`) need `aria-live="polite"` verification.
- **GAP FOUND**: Agent prompt checks `<html lang="xx">` but taxonomy's root layout would need inspection — agent doesn't specify WHERE to check (layout.tsx for App Router, _document.tsx for Pages Router).
- **EDGE CASE**: taxonomy uses `"use client"` on many UI components — when a Server Component renders a Client Component with dynamic content, the a11y announcement timing may differ from pure client rendering.

**Recommendation**: Add location-specific a11y scan instructions for Next.js.

### Test 3: Performance (RSC payload size, streaming SSR, dynamic imports)

**Input**: Scan taxonomy for performance edge cases.

**Findings**:
- **GAP FOUND**: Agent prompt has Core Web Vitals checklist but no RSC-specific performance patterns:
  - **RSC payload size**: Server Components serialize their output as a special format (not HTML) — large component trees create large payloads
  - **Streaming SSR**: `loading.tsx` enables streaming — without it, the entire page blocks until all data resolves
  - **Dynamic imports**: `next/dynamic` with `ssr: false` for heavy client-only components (editors, charts)
  - **Client component count**: 30+ `"use client"` components = 30+ separate bundles. Agent should flag unusually high client component ratios
- **GAP FOUND**: taxonomy's `components/editor.tsx` is marked `"use client"` — likely a heavy dependency (rich text editor). Agent should check if it uses `next/dynamic` with `ssr: false`.
- **EDGE CASE**: taxonomy imports `@editorjs/editorjs` — this is a large dependency that should be dynamically imported. Static import in a client component loads it eagerly.

**Recommendation**: Add RSC-specific performance patterns and dynamic import detection.

### Test 4: State management (server state vs client state, form handling)

**Input**: Analyze taxonomy's state management patterns.

**Findings**:
- **GAP FOUND**: Agent prompt mentions "state management" in passing but has no structured analysis framework:
  - **Server state**: Data fetched from APIs/DB — should use React Query/SWR or server-side fetching (RSC)
  - **Client state**: UI state (open/closed, selected tab) — should use useState/useReducer
  - **Form state**: taxonomy's `user-name-form.tsx` and `billing-form.tsx` use `"use client"` — agent should verify form handling pattern consistency
  - **URL state**: Search params, filters — should use `useSearchParams()` not local state
- **GAP FOUND**: Agent prompt doesn't check for "state location mismatches" — using client state where URL state is appropriate (breaks back button, sharing).

**Recommendation**: Add state management audit framework (server/client/form/URL state taxonomy).

### Test 5: SEO (metadata API, structured data, OG image generation)

**Input**: Scan taxonomy for SEO patterns.

**Findings**:
- **GAP FOUND**: Agent prompt has NO SEO checklist at all. Missing:
  - **Metadata API**: `generateMetadata()` or `export const metadata` in route segments
  - **Structured data**: JSON-LD for articles, products, organizations
  - **OG images**: `opengraph-image.tsx` or static images for social sharing
  - **Sitemap**: `sitemap.ts` or `sitemap.xml` generation
  - **robots.txt**: `robots.ts` or static file
  - **Canonical URLs**: Duplicate content prevention
- **EDGE CASE**: taxonomy is a blog/documentation platform — SEO is critical. Agent prompt's scope detection identifies "Full SPA" vs "Server-rendered" but doesn't add SEO checklist for content-heavy sites.

**Recommendation**: Add SEO checklist to frontend architect agent.

## Gaps Found in Agent Prompt

1. **No App Router file convention scanner** (error.tsx, loading.tsx, global-error.tsx, not-found.tsx)
2. **No RSC performance patterns** (payload size, streaming, dynamic imports, client boundary count)
3. **No SEO checklist** (metadata API, structured data, OG images, sitemap, robots.txt)
4. **No state management audit framework** (server/client/form/URL state categories)
5. **Location-specific a11y instructions** missing (where to check lang, where to check aria-live)
6. **No "content-heavy site" scope modifier** that adds SEO and content-specific checks
