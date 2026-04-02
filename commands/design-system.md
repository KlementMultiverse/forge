# /design-system — Create Design System

Build a complete design system from scratch: typography, colors, spacing, components. Ensures visual consistency across all pages.

## Input
$ARGUMENTS — project style (e.g., "minimal", "corporate", "playful") or "detect" to analyze existing

## Execution

### 1. Research Current Trends
- Web search: "design system best practices [year]"
- Check: what CSS framework is in use? (Pico, Tailwind, Bootstrap, custom)
- Analyze existing templates for current patterns

### 2. Define Foundations

**Typography:**
- Font stack (system fonts vs web fonts)
- Scale: h1 → h6 sizes with consistent ratio
- Line heights and spacing

**Color Palette:**
- Primary, secondary, accent colors
- Semantic colors: success (green), warning (amber), error (red), info (blue)
- Dark mode variants (if applicable)

**Spacing Scale:**
- Base unit (8px recommended)
- Scale: xs(4), sm(8), md(16), lg(24), xl(32), 2xl(48)

**Component Patterns:**
- Buttons: primary, secondary, outline, danger, disabled, loading
- Cards: header, body, footer, hover states
- Forms: input, select, textarea, validation states
- Navigation: active, hover, mobile collapse
- Alerts: success, warning, error, info with dismiss
- Badges: status colors, sizes
- Tables: striped, hover, responsive
- Dialogs: modal with backdrop, close button

### 3. Generate Design Tokens

```css
:root {
  /* Colors */
  --color-primary: #...;
  --color-secondary: #...;
  --color-accent: #...;
  --color-success: #28a745;
  --color-warning: #ffc107;
  --color-error: #dc3545;
  --color-info: #17a2b8;

  /* Typography */
  --font-family: system-ui, -apple-system, sans-serif;
  --font-size-base: 1rem;
  --font-size-sm: 0.875rem;
  --font-size-lg: 1.125rem;
  --line-height: 1.5;

  /* Spacing */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;

  /* Borders */
  --border-radius: 4px;
  --border-color: #dee2e6;
}
```

### 4. Output

Save to `static/design-system.css` or update existing CSS:
- Design tokens (CSS custom properties)
- Component styles
- Utility classes (if not using a framework)
- `DESIGN.md` documenting all decisions

## When To Run
- Phase 3: before frontend implementation
- When starting a new project with UI
- When visual inconsistency is detected by /design-audit
