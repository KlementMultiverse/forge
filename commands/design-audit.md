# /design-audit — Visual & UX Audit

Post-frontend-implementation audit that checks visual consistency, accessibility, responsive behavior, and UX quality.

## Input
$ARGUMENTS — URL or template path to audit (e.g., "templates/dashboard.html" or "http://localhost:8000/")

## Execution

### 7-Pass Audit

**Pass 1: Information Architecture**
- Is navigation logical? Can users find what they need?
- Are labels clear and consistent?
- Is the page hierarchy correct (h1 → h2 → h3)?
- Rate: 0-10

**Pass 2: Interaction States**
- Does every button have: default, hover, active, disabled, loading states?
- Do forms show: empty, filled, error, success states?
- Are loading indicators present for async operations?
- Rate: 0-10

**Pass 3: User Journey**
- Can a new user complete the primary task without help?
- Are error messages helpful (tell what went wrong + what to do)?
- Is the happy path obvious?
- Rate: 0-10

**Pass 4: Consistency**
- Are colors, fonts, spacing consistent across pages?
- Do buttons look the same everywhere?
- Are similar patterns used for similar actions?
- Rate: 0-10

**Pass 5: Responsive Behavior**
- Does it work on mobile (320px)?
- Does it work on tablet (768px)?
- Does it work on desktop (1280px)?
- Are tables horizontally scrollable on small screens?
- Rate: 0-10

**Pass 6: Accessibility**
- Do all images have alt text?
- Are form labels associated with inputs?
- Is color contrast sufficient (WCAG AA)?
- Can the page be navigated with keyboard only?
- Rate: 0-10

**Pass 7: Edge Cases**
- What happens with empty data (no workflows, no documents)?
- What happens with very long text (overflow handling)?
- What happens with slow connection (loading states)?
- Rate: 0-10

## Output

```markdown
# Design Audit: [page/template]

## Score: [total/70]

| Pass | Area | Score | Issues |
|------|------|-------|--------|
| 1 | Information Architecture | /10 | |
| 2 | Interaction States | /10 | |
| 3 | User Journey | /10 | |
| 4 | Consistency | /10 | |
| 5 | Responsive | /10 | |
| 6 | Accessibility | /10 | |
| 7 | Edge Cases | /10 | |

## Fixes (max 30)
- [Priority] [File] [What to change]
```
