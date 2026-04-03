# Run 05: saleor — Plugin System Architecture, Extension Points

## Source Files
- `/home/intruder/projects/saleor/saleor/plugins/manager.py`
- `/home/intruder/projects/saleor/saleor/plugins/base_plugin.py`
- `/home/intruder/projects/saleor/saleor/plugins/` (directory listing)
- `/home/intruder/projects/saleor/saleor/plugins/models.py`

## Findings

### Plugin System Design: Strategy Pattern with Database Configuration

**Core Components:**

1. **`PluginsManager`** — Central orchestrator:
   - Inherits from `PaymentInterface` — plugins can intercept payment flows.
   - Maintains plugin instances per-channel and global.
   - Loads plugins dynamically via `import_string()`.
   - Database-backed configuration (`PluginConfiguration` model).
   - Supports read replica routing (`_allow_replica`).

2. **`BasePlugin`** — Plugin contract:
   - Abstract base class with hook methods for every lifecycle event.
   - Each plugin has a `PLUGIN_ID`, `PLUGIN_NAME`, `DEFAULT_CONFIGURATION`.
   - Plugins can be per-channel or global.
   - Configuration stored in DB, merged with defaults.

3. **Built-in Plugins:**
   - `admin_email` — Admin notification emails
   - `user_email` — Customer emails
   - `sendgrid` — SendGrid integration
   - `avatax` — Tax calculation (AvaTax)
   - `openid_connect` — SSO/OIDC
   - `webhook` — Webhook delivery for external integrations

### Extension Points

| Extension Point | Mechanism | Example |
|---|---|---|
| Payment processing | `PaymentInterface` methods on manager | Custom payment gateway |
| Tax calculation | Plugin hooks (calculate_checkout_line_total, etc.) | AvaTax, custom tax |
| Email sending | Plugin hooks (notify, send_email) | SendGrid, SES |
| Webhook events | Event → webhook plugin → HTTP POST | External systems |
| Authentication | Plugin hooks (external_authentication_url, etc.) | OpenID Connect |
| Product/order lifecycle | Hook methods on BasePlugin | Custom validations |

### Architectural Observations

**Strengths:**
1. Strategy pattern — plugin manager delegates to the correct plugin per channel.
2. Database-backed configuration — plugins configurable at runtime without code deployment.
3. Per-channel plugin activation — different channels can have different plugins.
4. Clean interface — BasePlugin defines ALL possible hooks, plugins override only what they need.

**Weaknesses:**
1. `PluginsManager` is a God Class — it knows about every module (checkout, order, payment, product, etc.). The TYPE_CHECKING imports span 20+ modules.
2. Synchronous plugin execution — hooks are called sequentially in a for loop. No async plugin support.
3. No plugin dependency management — plugins can't declare dependencies on other plugins.
4. No plugin versioning — no way to version plugin interfaces or handle breaking changes.

### Relevance to Agent Prompt

The system-architect agent should be able to:
1. Identify extension mechanisms in a codebase (plugin systems, middleware, hooks, events).
2. Evaluate the extension point design (Strategy pattern, Observer, etc.).
3. Assess coupling between the extension system and core modules.
4. Recommend improvements (async hooks, dependency management, versioning).

## Gaps Identified for Agent Prompt
1. **Extension point identification**: Agent should systematically identify all extension mechanisms in a codebase.
2. **Design pattern classification**: Agent should name the design patterns used (Strategy, Observer, Chain of Responsibility, etc.).
3. **God Class detection**: Agent should flag classes with too many responsibilities or dependencies.
4. **Sync vs async evaluation**: Agent should assess whether extension points should support async execution.
5. **Plugin/extension versioning**: Agent should evaluate if extensions have versioning and compatibility management.
