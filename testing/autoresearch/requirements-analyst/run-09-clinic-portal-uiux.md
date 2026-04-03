# Run 09: Extract UI/UX Requirements from clinic-portal Templates

## Source: templates/dashboard.html, templates/ directory listing, SPEC.md (Frontend section), static/app.js (implied)

## Extracted Requirements

### Navigation

- [REQ-UI001] Persistent navigation bar across all tenant pages
  - Given any tenant page, When rendered, Then nav shows: Dashboard, Workflows, Documents, Search, Chat, Staff (admin only)
  - Evidence: SPEC.md "Navigation bar shows: Dashboard, Workflows, Documents, Search, Chat, Staff (admin only)"
- [REQ-UI002] Staff link visibility based on role
  - Given a non-admin user, When viewing nav, Then "Staff" link is hidden
- [REQ-UI003] All templates extend base.html
  - Given any page, When rendered, Then it inherits base layout with Pico CSS CDN + app.js
  - Evidence: `{% extends "base.html" %}` in dashboard.html

### Dashboard Page

- [REQ-UI004] Stats cards for key metrics
  - Given the dashboard, When loaded, Then cards show: Workflows count, Documents count, Staff Members count
  - Evidence: Three `<article>` cards with IDs `stat-workflows`, `stat-documents`, `stat-staff`
- [REQ-UI005] Tasks by status breakdown
  - Given the dashboard, When stats are loaded, Then tasks are grouped by status with badge styling
  - Evidence: `tasks-by-status` section iterates over `data.tasks_by_status`
- [REQ-UI006] Async data loading pattern
  - Given any page, When loaded, Then data is fetched via `apiFetch()` JavaScript function (not server-rendered)
  - Evidence: `const resp = await apiFetch('/api/dashboard/stats')` in template script block
- [REQ-UI007] Error feedback via alerts
  - Given an API failure, When response is not OK, Then `showAlert('message', 'error')` is displayed
- [REQ-UI008] Loading states with placeholder text
  - Given initial page load, When data hasn't arrived, Then `--` and `Loading...` placeholders are shown
  - Evidence: `<p class="stat-value" id="stat-workflows">--</p>` and `<p>Loading...</p>`
- [REQ-UI009] Personalized welcome message
  - Given a logged-in user, When viewing dashboard, Then "Welcome, [name or email]" is shown
  - Evidence: `Welcome, {{ user.name|default:user.email }}.`

### Page Inventory

- [REQ-UI010] Landing page at portal subdomain
  - Given an unauthenticated visitor, When visiting portal.localhost, Then landing page with signup + login links is shown
- [REQ-UI011] Login page with email + password
  - Given any subdomain, When visiting /login/, Then email + password form is shown
- [REQ-UI012] Registration page with name + email + password
  - Given registration URL, When visiting /register/, Then three-field form is shown
- [REQ-UI013] Workflows page with CRUD + AI generation
  - Given an authenticated user, When visiting /workflows/, Then workflow list with task status badges and AI generate button is shown
- [REQ-UI014] Documents page with upload + download + summarize
  - Given an authenticated user, When visiting /documents/, Then file list with upload (presigned URL), download, and summarize actions is shown
- [REQ-UI015] Staff management page (admin only)
  - Given an admin user, When visiting /staff/, Then invite-by-email form and staff list with remove action is shown
- [REQ-UI016] Clinical search page with RAG results
  - Given an authenticated user, When visiting /search/, Then query input with trials + papers + AI summary results is shown
- [REQ-UI017] Chat page with thread sidebar
  - Given an authenticated user, When visiting /chat/, Then conversation interface with thread list sidebar is shown

### Frontend Architecture

- [REQ-UI018] No build step (vanilla JS + Pico CSS CDN)
  - Given the frontend, When deployed, Then no webpack/vite build is needed — static files served directly
- [REQ-UI019] CSRF handling via apiFetch wrapper
  - Given any API call from JavaScript, When making fetch request, Then CSRF token is automatically included
  - Evidence: SPEC.md mentions "CSRF helper, apiFetch wrapper" in static/app.js
- [REQ-UI020] Status badges with CSS classes per status
  - Given a task status, When displayed, Then `badge-{status}` CSS class is applied
  - Evidence: `'badge badge-' + status` in dashboard.html script

### Accessibility / UX (Implied by Pico CSS)

- [REQ-UI021] Semantic HTML via Pico CSS
  - Given any page, When rendered, Then Pico CSS provides baseline styling from semantic HTML (no utility classes needed)
- [REQ-UI022] Responsive grid layout
  - Given any screen size, When viewing dashboard, Then `.grid` class provides responsive multi-column layout

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery**: Good — extracted from templates, SPEC.md frontend section, and HTML patterns
- **REQ-xxx tagging**: YES — UI-prefixed
- **Acceptance criteria**: YES — Given/When/Then
- **Completeness**: Good — covered navigation, pages, frontend architecture, UX patterns
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No instruction to extract UI PATTERNS vs UI PAGES** — the apiFetch wrapper, loading states, error alerts, and badge styling are reusable patterns, not page-specific features. The prompt should instruct: "separate page-specific requirements from reusable UI patterns"
2. **No instruction to extract ACCESSIBILITY requirements** — Pico CSS implies semantic HTML and baseline accessibility, but the prompt doesn't mention a11y as a requirement category. Should add: "check for accessibility patterns (ARIA, semantic HTML, keyboard nav) and extract as requirements"
3. **No instruction to note CLIENT-SIDE vs SERVER-SIDE rendering split** — the fact that dashboard.html server-renders the shell but client-fetches data is an architectural decision. The prompt should instruct: "document the rendering strategy (SSR, CSR, hybrid) as a requirement"
