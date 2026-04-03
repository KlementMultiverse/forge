# Claude Code Dialog and UI System: Technical Architecture

## Four-Layer Architecture

1. **Launchers** (`dialogLaunchers.tsx`) - Async functions with dynamic imports
2. **Helpers** (`interactiveHelpers.tsx`) - Promise-wrapping primitives
3. **Design System** - Ink component wrappers (Dialog, Pane, PermissionDialog)
4. **Feature Components** - Domain-specific dialogs

## Promise-Based Dialog Lifecycle

`showDialog` creates inversion of control — dialogs become awaitable async functions returning typed values.

## Permission Request Architecture

Single `switch` statement routes tools to UI components. `PermissionPromptOption<T>` unifies all approval UI.

## CustomSelect: Embedded Input Widget

The `'input'` option type embeds live text fields inside selection lists — powers "allow this prefix forever" options.

## Wizard Pattern

Provider pattern with hook-based navigation: `WizardProvider` holds state, `useWizard()` exposes navigation.

## Performance: Render Isolation

Isolate components with frequent internal updates (animation frames, network checks) to prevent parent tree re-renders.

## Design System Primitives

- **Dialog**: Standard confirm/cancel with keybindings
- **Pane**: Borderless region for slash-command screens
- **PermissionDialog**: Specialized chrome with WorkerBadge header
