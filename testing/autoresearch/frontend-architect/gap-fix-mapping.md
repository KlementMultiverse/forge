# Gap-to-Fix Mapping: Frontend Architect Agent

## Prompt Changes Made

**File:** `/home/intruder/projects/forge/agents/universal/frontend-architect.md`

### What Changed
1. **Updated WCAG reference** from 2.1 AA to 2.2 AA with new criteria (Focus Appearance, Target Size, Dragging Movements)
2. **Added 8 Review Checklists** with concrete, actionable detection patterns organized by category:
   - Accessibility (11 items)
   - Performance & Core Web Vitals (8 items)
   - Component Architecture (7 items)
   - CSS & Theming (7 items)
   - JavaScript Patterns (6 items)
   - Forms & Validation UX (7 items)
   - i18n & l10n (5 items)
   - Build & Asset Pipeline (6 items)
3. **Added scope detection** — agent should identify backend-only projects and redirect effort
4. **Expanded Chaos Resilience** with vanilla JS, inline script, and no-framework fallback scenarios

### Gap Coverage

| Gap ID | Fixed By | Checklist Item |
|--------|----------|----------------|
| GAP-01 | Performance | CDN fallback strategy (local copy as fallback) |
| GAP-02 | CSS & Theming | Static file organization patterns |
| GAP-03 | Build & Asset Pipeline | Dependency health audit (version currency, CVEs) |
| GAP-04 | Build & Asset Pipeline | Build tool config review (Vite, Webpack, esbuild) |
| GAP-05 | Build & Asset Pipeline | Frontend linter/formatter detection |
| GAP-06 | Build & Asset Pipeline | Auto-generated code boundary evaluation |
| GAP-07 | Component Architecture | Component library evaluation (coverage, consistency, story/test ratios) |
| GAP-08 | Component Architecture | Variant system evaluation (CVA, Stitches) |
| GAP-09 | Component Architecture | Composition pattern evaluation (Slot/asChild, compound components) |
| GAP-10 | Component Architecture | Storybook/visual testing coverage |
| GAP-11 | Accessibility | Skip navigation link requirement |
| GAP-12 | Accessibility | ARIA live region checklist |
| GAP-13 | Accessibility | Form error accessibility (aria-invalid, aria-describedby) |
| GAP-14 | Accessibility | Color-only indicator detection |
| GAP-15 | Accessibility | Focus management (dialog, async ops, route changes) |
| GAP-16 | Accessibility | WCAG 2.2 criteria (Focus Appearance, Target Size 24x24px, Dragging Movements) |
| GAP-17 | Scope Detection | Backend-only project identification and redirect |
| GAP-18 | CSS & Theming | Design token evaluation (naming, light/dark, semantic vs primitive) |
| GAP-19 | CSS & Theming | Dark mode / theming review |
| GAP-20 | Performance | Font loading strategy (font-display, preload, FOIT/FOUT) |
| GAP-21 | CSS & Theming | Responsive strategy evaluation (breakpoints, container queries, fluid type) |
| GAP-22 | JavaScript Patterns | Inline script complexity threshold |
| GAP-23 | JavaScript Patterns | innerHTML security audit |
| GAP-24 | JavaScript Patterns | Event delegation pattern |
| GAP-25 | JavaScript Patterns | Scope hygiene (IIFE, modules, namespace pollution) |
| GAP-26 | JavaScript Patterns | CSP awareness (inline scripts/styles/handlers) |
| GAP-27 | Build & Asset Pipeline | Build config review (code splitting, tree shaking, chunks) |
| GAP-28 | Performance | Asset optimization pipeline (WebP/AVIF, responsive images) |
| GAP-29 | Build & Asset Pipeline | Frontend test runner awareness (Playwright, Vitest, Jest) |
| GAP-30 | Performance | Bundle analysis and size budgets |
| GAP-31 | Forms & Validation UX | Client-side validation beyond HTML5 |
| GAP-32 | Forms & Validation UX | Field-level error display and scroll-to-error |
| GAP-33 | Forms & Validation UX | Submit button state management (loading/disabled/success) |
| GAP-34 | Accessibility | autocomplete attribute (WCAG 1.3.5) |
| GAP-35 | Forms & Validation UX | File upload UX (progress, drag-drop, preview, limits) |
| GAP-36 | i18n & l10n | i18n architecture evaluation |
| GAP-37 | i18n & l10n | RTL support checklist |
| GAP-38 | i18n & l10n | Locale-aware formatting (dates, numbers, currencies) |
| GAP-39 | i18n & l10n | Translation coverage (missing keys, plurals, interpolation) |
| GAP-40 | i18n & l10n | Locale detection strategy |

### Score Impact (Projected)

| Run | Before | After (projected) | Reason |
|-----|--------|-------------------|--------|
| 1: clinic-portal templates | 3/5 | 5/5 | CDN fallback, static file org checklists |
| 2: fastapi-template stack | 2/5 | 4/5 | Build config, linter, dependency health checklists |
| 3: medusa components | 2/5 | 5/5 | Component library, variant system, composition checklists |
| 4: clinic-portal a11y | 1/5 | 5/5 | Full accessibility checklist with WCAG 2.2 |
| 5: saleor (no frontend) | 2/5 | 4/5 | Scope detection redirects to API review |
| 6: medusa CSS/tokens | 2/5 | 5/5 | Token evaluation, dark mode, font loading checklists |
| 7: clinic-portal JS | 1/5 | 5/5 | Inline script, innerHTML, event delegation, CSP checklists |
| 8: fastapi-template build | 1/5 | 4/5 | Build config, bundle analysis, test runner checklists |
| 9: clinic-portal forms | 1/5 | 5/5 | Full form validation UX checklist |
| 10: medusa i18n | 1/5 | 5/5 | Complete i18n/l10n/RTL checklists |

**Average: 1.6/5 -> 4.7/5 (projected)**
