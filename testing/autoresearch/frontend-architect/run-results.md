# Autoresearch: Frontend Architect Agent — 10 Test Runs

## Research Phase: Web Search Findings (2025-2026 Frontend Patterns)

Key patterns the agent prompt should cover but currently misses:
1. **Atomic design methodology** — atoms/molecules/organisms/templates/pages hierarchy; prompt mentions "component architecture" but has no concrete decomposition methodology
2. **Design tokens / CSS custom properties** — Medusa's entire design system is token-based (`--fg-base`, `--bg-field`); prompt says "design tokens" in focus areas but has no review checklist
3. **WCAG 2.2 new criteria** — Focus Appearance, Dragging Movements, Target Size (24x24px minimum), Consistent Help, Redundant Entry; prompt only mentions WCAG 2.1 AA
4. **INP (Interaction to Next Paint)** — replaced FID in Core Web Vitals; prompt mentions "Core Web Vitals" generically but has no specific metric thresholds or detection methods
5. **i18n/l10n patterns** — RTL support, locale-aware date formatting, translation key management; prompt has zero mention
6. **Inline style abuse detection** — common in vanilla JS codebases; prompt has no style organization guidance for non-framework projects
7. **Form validation UX patterns** — inline errors, aria-describedby for error messages, aria-invalid states; prompt mentions "keyboard navigation" but not form-specific accessibility
8. **Progressive enhancement** — ensuring core functionality works without JavaScript; prompt assumes JS is always available
9. **Dark mode / theme switching** — data-theme attributes, CSS custom property theming; prompt has no guidance
10. **Content Security Policy (CSP) awareness** — inline scripts and styles violate strict CSP; prompt has no security guidance

Sources:
- [Frontend Architecture Patterns 2026 - DEV Community](https://dev.to/sizan_mahmud0_e7c3fd0cb68/the-complete-guide-to-frontend-architecture-patterns-in-2026-3ioo)
- [WCAG 2.2 Compliance Checklist - AllAccessible](https://www.allaccessible.org/blog/wcag-22-compliance-checklist-implementation-roadmap)
- [Core Web Vitals 2026 Guide - Mewa Studio](https://www.mewastudio.com/en/blog/seo-core-web-vitals-2026)
- [Accessibility Audit Checklist 2026 - Web Accessibility Checker](https://web-accessibility-checker.com/en/blog/accessibility-audit-checklist)
- [A11Y Project Checklist](https://www.a11yproject.com/checklist/)

---

## Run 1: clinic-portal — Django Template Structure, Base Template Inheritance, Static Files

**Repo:** `/home/intruder/projects/clinic-portal`
**Focus:** Template inheritance hierarchy, static file organization, base template patterns

### Real Issues Found
1. **Template inheritance is clean** — `base.html` defines `{% block title %}`, `{% block content %}`, `{% block extra_js %}` blocks. All 9 child templates extend it properly. No orphaned templates.
2. **CDN dependency for Pico CSS** — `base.html` loads Pico CSS from `cdn.jsdelivr.net`. No local fallback. If CDN is down, the entire UI breaks. The prompt has no guidance on CDN fallback strategies.
3. **Single static CSS + single static JS** — Only `styles.css` (101 lines) and `app.js` (84 lines). For this project size, fine. But the prompt has no guidance on when to split vs keep monolithic.
4. **CSRF meta tag pattern** — `<meta name="csrf-token" content="{{ csrf_token }}">` in base.html, consumed by `app.js` `getCsrfToken()`. Clean pattern but prompt has no Django-specific template security guidance.
5. **No `{% load static %}` in child templates** — Only `base.html` loads the `static` tag. Child templates rely on inheritance. Correct but fragile if templates are ever used standalone.

### Prompt Gaps
- **GAP-01**: No CDN fallback strategy guidance (local copy as fallback)
- **GAP-02**: No guidance on static file organization patterns (when to split, when to bundle, directory structure conventions)

### Score: PROMPT 3/5 for this scenario

---

## Run 2: fastapi-template — Frontend Directory Analysis (React + Vite + Tailwind + shadcn/ui)

**Repo:** `/home/intruder/projects/forge-test-repos/fastapi-template`
**Focus:** Framework detection, build pipeline, component organization

### Real Issues Found
1. **Tech stack: React 19 + Vite 7 + Tailwind 4 + TanStack Router + shadcn/ui (Radix primitives)** — `package.json` reveals a modern SPA stack. The prompt says "follow CLAUDE.md tech stack" but has no guidance for EVALUATING an existing stack's health.
2. **Auto code-splitting** — `vite.config.ts` uses `tanstackRouter({ autoCodeSplitting: true })`. Good for performance. The prompt mentions "bundle optimization" but has no specific Vite/Webpack config review checklist.
3. **Component hierarchy: ui/ -> Common/ -> domain/** — `src/components/ui/` has 20+ shadcn primitives, `Common/` has shared layouts (`AuthLayout`, `DataTable`, `ErrorComponent`), then domain folders (`Admin/`, `Items/`, `Sidebar/`). This follows atomic-like separation. The prompt mentions "component architecture" but has no detection criteria for evaluating organizational quality.
4. **OpenAPI client generation** — `openapi-ts.config.ts` + `src/client/` has auto-generated API SDK. The prompt has no guidance on evaluating generated code vs hand-written code boundaries.
5. **Biome for linting** — Not ESLint. The prompt's quality step uses Python linters only (`black`, `ruff`). No frontend linter awareness.

### Prompt Gaps
- **GAP-03**: No existing stack health evaluation checklist (dependency age, bundle analysis, framework version currency)
- **GAP-04**: No build tool configuration review guidance (Vite, Webpack, esbuild, Turbopack)
- **GAP-05**: No frontend linter/formatter awareness (ESLint, Biome, Prettier)
- **GAP-06**: No guidance on evaluating auto-generated code boundaries (API clients, type definitions)

### Score: PROMPT 2/5 for this scenario

---

## Run 3: medusa — Admin UI Component Patterns, Shared Component Library

**Repo:** `/home/intruder/projects/forge-test-repos/medusa`
**Focus:** Design system architecture, component library organization, shared components

### Real Issues Found
1. **Dedicated design system package** — `packages/design-system/ui/` has 44 components (alert, avatar, badge, button, calendar, checkbox, code-block, command, command-bar, container, copy, currency-input, date-picker, etc). Each component has its own directory with `{name}.tsx`, `{name}.stories.tsx`, and optionally `{name}.spec.tsx`. The prompt has no guidance on evaluating component library completeness or Storybook story coverage.
2. **CVA (class-variance-authority) pattern** — `button.tsx` uses `cva()` for variant management: primary/secondary/transparent/danger variants, small/base/large/xlarge sizes. The prompt mentions "design tokens" but not variant systems.
3. **Composition via Slot/asChild** — Button uses `Slot.Root` from Radix for polymorphic rendering. This is the modern composition pattern replacing render props. The prompt has no guidance on evaluating component composition patterns.
4. **Loading state pattern** — Button has `isLoading` prop that overlays a spinner while preserving layout (prevents CLS). The prompt mentions Core Web Vitals but not component-level CLS prevention patterns.
5. **Monorepo structure** — `packages/admin/dashboard/` consumes `packages/design-system/ui/`. Cross-package import paths (`@medusajs/ui`). The prompt has no monorepo-aware component evaluation.

### Prompt Gaps
- **GAP-07**: No component library evaluation criteria (coverage, consistency, story/test ratios)
- **GAP-08**: No variant system evaluation (CVA, Stitches, vanilla-extract recipes)
- **GAP-09**: No component composition pattern evaluation (Slot/asChild, render props, compound components)
- **GAP-10**: No Storybook/visual testing guidance

### Score: PROMPT 2/5 for this scenario

---

## Run 4: clinic-portal — Accessibility Audit (ARIA Labels, Keyboard Nav, Semantic HTML)

**Repo:** `/home/intruder/projects/clinic-portal`
**Focus:** WCAG compliance, keyboard navigation, screen reader support

### Real Issues Found
1. **`<html lang="en">`** — Present. Good.
2. **Missing skip navigation link** — No "Skip to main content" link in `base.html`. Screen reader / keyboard users must tab through entire nav on every page. This is a WCAG 2.4.1 failure.
3. **Dialog accessibility is partial** — `workflows.html` uses `<dialog>` with `aria-label="Close"` on close buttons. Good. But dialogs lack `aria-labelledby` pointing to their heading. Screen readers announce dialog without knowing its purpose.
4. **Missing ARIA live region for alerts** — `showAlert()` in `app.js` sets `role="alert"` (good), but the `#alert-container` div in `base.html` has no `aria-live="polite"` attribute. Dynamic alert injection may not be announced reliably.
5. **Form error display is visual-only** — Login/register forms show alerts via `showAlert()` at page top, not inline next to the field. No `aria-invalid` on inputs, no `aria-describedby` linking errors to fields. WCAG 1.3.1 and 3.3.1 failures.
6. **Color-only status indication** — Badge classes (`.badge-created`, `.badge-completed`, etc.) use color alone. No icons or patterns. WCAG 1.4.1 failure (Use of Color).
7. **Inline onclick handlers in search.html** — `onclick="trialsPage++;renderTrials();"` — no keyboard equivalent, violates CSP best practices.
8. **No focus management after dialog open/close** — When workflow dialog opens/closes, focus is not explicitly managed. `<dialog>` handles some of this natively, but after async operations (create workflow -> close dialog -> reload list), focus is lost.
9. **Target size** — `.task-actions button` has `padding: 0.3em 0.8em` which may produce clickable areas under the 24x24px WCAG 2.2 minimum.

### Prompt Gaps
- **GAP-11**: No skip navigation link requirement
- **GAP-12**: No ARIA live region checklist (aria-live, role="status", role="alert")
- **GAP-13**: No form error accessibility checklist (aria-invalid, aria-describedby, inline error placement)
- **GAP-14**: No color-only indicator detection (badges, status, charts must have non-color differentiation)
- **GAP-15**: No focus management checklist (dialog open/close, after async operations, route changes)
- **GAP-16**: No WCAG 2.2-specific criteria (Focus Appearance, Target Size 24x24px minimum, Dragging Movements)

### Score: PROMPT 1/5 for this scenario

---

## Run 5: saleor — React Component Architecture (Backend-only, no dashboard in this repo)

**Repo:** `/home/intruder/projects/forge-test-repos/saleor`
**Focus:** React component architecture evaluation

### Real Issues Found
1. **Saleor core has NO frontend** — Only 3 HTML templates: `index.html` (home), `playground.html` (GraphQL playground), `price.html`. The dashboard is a separate repo (`saleor-dashboard`). The prompt has no guidance on detecting "frontend-less" backends and adjusting scope.
2. **GraphQL playground template** — `templates/graphql/playground.html` loads a CDN script. No accessibility concerns beyond what the playground library provides.
3. **Minimal template patterns** — Templates are Django-rendered with `{% extends %}` but have almost no interactivity. Nothing meaningful to evaluate.

### Prompt Gaps
- **GAP-17**: No scope detection — agent should identify "this project has no meaningful frontend" and redirect effort (e.g., review API response shape for frontend consumption, review CORS config, evaluate API documentation)

### Score: PROMPT 2/5 for this scenario (wasted analysis on a backend-only project)

---

## Run 6: medusa — CSS Strategy, Design Tokens, Responsive Patterns

**Repo:** `/home/intruder/projects/forge-test-repos/medusa`
**Focus:** CSS architecture, design token system, responsive design

### Real Issues Found
1. **Full design token system** — `ui-preset/src/theme/tokens/` has `colors.ts`, `typography.ts`, `effects.ts`, `components.ts`. Colors defined as semantic CSS custom properties (`--fg-base`, `--bg-field`, `--border-error`) with both light and dark theme values. The prompt says "design tokens" but has no evaluation criteria for token completeness or naming conventions.
2. **Dark mode support** — Token file has separate `dark` and `light` objects mapping identical property names to different values. Theme switching is via CSS custom property override. The prompt has zero dark mode guidance.
3. **Tailwind CSS with custom theme** — `index.css` uses `@tailwind base/components/utilities` with custom `@apply` directives referencing design tokens (`@apply bg-ui-bg-subtle text-ui-fg-base antialiased`). Token-to-utility bridge. No prompt guidance on evaluating this pattern.
4. **Custom font loading** — `@font-face` declarations load Inter and Roboto Mono from local files (not CDN). Good for performance and privacy. But no `font-display: swap` — causes FOIT (Flash of Invisible Text), hurts LCP. The prompt mentions Core Web Vitals but not font loading strategies.
5. **No responsive breakpoint system visible** — Token files have no breakpoint definitions. Responsive behavior likely handled by Tailwind's built-in breakpoints. Prompt has no guidance on evaluating whether a project's responsive strategy is explicit or implicit.

### Prompt Gaps
- **GAP-18**: No design token evaluation checklist (naming convention, light/dark coverage, semantic vs primitive tokens)
- **GAP-19**: No dark mode / theming review criteria
- **GAP-20**: No font loading strategy evaluation (`font-display`, preloading, local vs CDN, FOIT/FOUT)
- **GAP-21**: No responsive strategy evaluation (explicit breakpoints, container queries, fluid typography)

### Score: PROMPT 2/5 for this scenario

---

## Run 7: clinic-portal — JavaScript Patterns, Inline Scripts, Event Handling

**Repo:** `/home/intruder/projects/clinic-portal`
**Focus:** JS architecture in vanilla JS project, inline script patterns, event delegation

### Real Issues Found
1. **Shared utilities well-structured** — `app.js` provides `getCsrfToken()`, `apiFetch()`, `showAlert()`, `escapeHtml()`, logout handler. Clean, documented, under 85 lines. Good.
2. **Inline `<script>` blocks in every template** — All page logic is in `{% block extra_js %}` inline scripts. Each page (dashboard, workflows, documents, search, chat, staff) has 50-250 lines of inline JS. Total inline JS across all templates: ~800+ lines. The prompt's 300-line limit applies to files but not inline scripts.
3. **XSS prevention via `escapeHtml()`** — Used consistently when inserting user content. Good. But `innerHTML` assignments are everywhere. A single missed `escapeHtml()` call means XSS. The prompt has no `innerHTML` audit guidance.
4. **No event delegation** — `workflows.html` and `documents.html` re-bind event listeners after every data load (`container.querySelectorAll('.transition-btn').forEach(...)`). Event delegation on the container would be more efficient and prevent memory leaks. Prompt has no event pattern guidance.
5. **Global function pollution** — `search.html` defines `renderTrials()`, `renderPapers()`, `renderFilters()`, `loadHistory()` plus global variables (`allTrials`, `allPapers`, `trialsPage`, `papersPage`, `activeFilter`) in an inline script without IIFE wrapping. `dashboard.html` correctly uses an IIFE. Inconsistent. Prompt has no namespace/scope hygiene guidance for vanilla JS.
6. **Mixed `var`/`const`/`let`** — `search.html` uses `var` everywhere while `workflows.html` uses `const`/`let`. Inconsistent style within the same project. Prompt has no vanilla JS code style guidance.
7. **Inline `onclick` attributes** — `search.html` pagination buttons use `onclick="trialsPage++;renderTrials();"`. Mixed with `addEventListener` in other templates. Violates strict CSP. Prompt has no CSP awareness.

### Prompt Gaps
- **GAP-22**: No inline script size/complexity limit — should flag when inline JS exceeds a threshold and recommend extraction to static files
- **GAP-23**: No `innerHTML` security audit guidance — should flag every `innerHTML` assignment and verify escaping
- **GAP-24**: No event delegation pattern guidance
- **GAP-25**: No vanilla JS scope hygiene guidance (IIFE, modules, namespace pollution)
- **GAP-26**: No CSP-awareness guidance (inline scripts, inline styles, inline event handlers)

### Score: PROMPT 1/5 for this scenario

---

## Run 8: fastapi-template — Build Pipeline, Bundle Optimization, Asset Loading

**Repo:** `/home/intruder/projects/forge-test-repos/fastapi-template`
**Focus:** Vite config, code splitting, tree shaking, asset optimization

### Real Issues Found
1. **Vite 7 with SWC** — `@vitejs/plugin-react-swc` for fast HMR. Good. But no explicit chunk strategy configured — relies on TanStack Router's `autoCodeSplitting`. The prompt has no build configuration review checklist.
2. **Tailwind 4 via Vite plugin** — `@tailwindcss/vite` — no PostCSS config needed. Clean. But no purge verification — Tailwind 4 handles this automatically, but the agent should know to check output bundle size.
3. **No image optimization config** — No `vite-imagetools`, no WebP/AVIF conversion. `public/` directory has static assets served as-is. Prompt mentions "loading strategies" but not asset optimization pipeline.
4. **Playwright for E2E testing** — `playwright.config.ts` exists but the prompt's testing guidance is Python-only (`uv run python manage.py test`). No frontend test runner awareness.
5. **Dockerfile uses multi-stage build** — `Dockerfile` has `nginx.conf` for production serving with separate backend/frontend containers. Prompt has no deployment asset serving review.
6. **No bundle analysis tool configured** — No `rollup-plugin-visualizer` or `source-map-explorer`. Can't evaluate bundle composition without adding one. Prompt should recommend bundle analysis as a review step.

### Prompt Gaps
- **GAP-27**: No build configuration review checklist (code splitting, tree shaking, chunk strategy, source maps)
- **GAP-28**: No asset optimization pipeline checklist (image formats, compression, responsive images, preloading)
- **GAP-29**: No frontend test runner awareness (Playwright, Cypress, Vitest, Jest) — prompt assumes Python testing only
- **GAP-30**: No bundle analysis guidance (visualizer tools, size budgets, dependency audit)

### Score: PROMPT 1/5 for this scenario

---

## Run 9: clinic-portal — Form Handling, Validation UX, Error Display

**Repo:** `/home/intruder/projects/clinic-portal`
**Focus:** Form submission patterns, client-side validation, error UX

### Real Issues Found
1. **HTML5 validation attributes present** — `required`, `type="email"`, `minlength="8"` on registration form. Good baseline.
2. **No client-side validation beyond HTML5** — No JavaScript validation before submit. Password strength indicator absent. Email format only checked by browser. Prompt has no client-side validation checklist.
3. **Error display is page-level, not field-level** — All errors shown via `showAlert()` at page top. User must scroll up to see error, then scroll back to find the problematic field. Poor UX. Prompt has no form error UX guidance.
4. **No loading states on submit buttons** — Login form submits but button doesn't show loading state (no `aria-busy`, no text change). Compared to landing.html which correctly sets `aria-busy` on submit. Inconsistent. Prompt has no form submission state guidance.
5. **No `autocomplete` attributes** — Login form has `type="email"` and `type="password"` but no `autocomplete="email"` or `autocomplete="current-password"`. Password managers may not auto-fill correctly. WCAG 1.3.5 (Identify Input Purpose).
6. **Confirm dialog for destructive actions** — `documents.html` uses `confirm()` for delete. Functional but not accessible (can't be styled, no custom messaging). Prompt has no destructive action confirmation pattern.
7. **File upload has no progress indicator** — `documents.html` S3 upload has no progress bar or percentage. User sees nothing during large file uploads. `fetch()` doesn't support progress natively — needs XMLHttpRequest or ReadableStream. Prompt mentions "loading strategies" but not upload progress.

### Prompt Gaps
- **GAP-31**: No client-side validation checklist (beyond HTML5: real-time feedback, strength indicators, format hints)
- **GAP-32**: No form error UX pattern (field-level errors, scroll-to-error, summary + field association)
- **GAP-33**: No form submission state management guidance (loading, disabled, success, error states)
- **GAP-34**: No `autocomplete` attribute checklist (WCAG 1.3.5 — Identify Input Purpose)
- **GAP-35**: No file upload UX checklist (progress, drag-and-drop, file type preview, size limits)

### Score: PROMPT 1/5 for this scenario

---

## Run 10: medusa — i18n/l10n Patterns, RTL Support, Locale Handling

**Repo:** `/home/intruder/projects/forge-test-repos/medusa`
**Focus:** Internationalization architecture, RTL support, locale-aware formatting

### Real Issues Found
1. **Full i18n infrastructure** — `i18n/config.ts` uses i18next with `fallbackLng: "en"`, detection order: cookie -> localStorage -> header. `i18n/languages.ts` defines 30+ languages with explicit `ltr: boolean` flag per language.
2. **RTL support is explicit** — Arabic (`ar`), Hebrew (`he`), and Farsi (`fa`) all have `ltr: false`. The dashboard must apply `dir="rtl"` attribute. Prompt has zero RTL guidance.
3. **Date locale binding** — Each language entry includes a `date_locale` from `date-fns/locale`. Date formatting is locale-aware. Prompt has no date/number formatting guidance.
4. **Translation files as JSON** — `i18n/translations/` has 20+ JSON files (en.json, fr.json, ja.json, zhCN.json, etc). Structured by namespace. Prompt has no translation file management guidance.
5. **No plural rules visible** — i18next supports pluralization but the config doesn't show explicit plural configuration. Agent should check for plural form coverage in translation files. Prompt has no pluralization awareness.
6. **Language detection cascade** — cookie -> localStorage -> header is correct for SSR-capable apps. For pure SPAs, URL-based detection (`/en/`, `/fr/`) might be preferred. Prompt has no locale detection strategy guidance.

### Prompt Gaps
- **GAP-36**: No i18n architecture evaluation (framework choice, key management, namespace organization)
- **GAP-37**: No RTL support checklist (dir attribute, CSS logical properties, mirrored layouts, bidirectional text)
- **GAP-38**: No locale-aware formatting guidance (dates, numbers, currencies, relative time)
- **GAP-39**: No translation coverage evaluation (missing keys, plural forms, interpolation patterns)
- **GAP-40**: No locale detection strategy guidance (URL, cookie, header, browser preference)

### Score: PROMPT 1/5 for this scenario
