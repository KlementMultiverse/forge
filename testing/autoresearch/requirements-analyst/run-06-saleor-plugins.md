# Run 06: Extract Plugin System Requirements from Saleor

## Source: saleor/plugins/base_plugin.py, saleor/payment/gateways/*/plugin.py

## Extracted Requirements

### Plugin Architecture

- [REQ-PLUG001] Plugin registration via class attributes
  - Given a plugin class, When registered, Then it provides PLUGIN_NAME, PLUGIN_ID, PLUGIN_DESCRIPTION
  - Evidence: `BasePlugin` class attributes
- [REQ-PLUG002] Plugin chain execution (previous_value pattern)
  - Given multiple plugins, When an event fires, Then each plugin receives the previous plugin's return value
  - Evidence: "All methods take previous_value parameter. previous_value contains a value calculated by the previous plugin in the queue."
- [REQ-PLUG003] Per-channel plugin configuration
  - Given a plugin, When configured, Then it can have different settings per sales channel
  - Evidence: `CONFIGURATION_PER_CHANNEL = True` default
- [REQ-PLUG004] Plugin active/inactive toggle
  - Given a plugin, When toggled, Then it can be activated/deactivated without removal
  - Evidence: `active: bool` in `__init__`, `DEFAULT_ACTIVE = False`
- [REQ-PLUG005] Hidden plugins (internal only)
  - Given a plugin, When HIDDEN=True, Then it does not appear in admin plugin list
  - Evidence: `HIDDEN = False` default
- [REQ-PLUG006] Plugin configuration types
  - Given a plugin config field, When defined, Then it must be one of: String, Multiline, Boolean, Secret, SecretMultiline, Password, OUTPUT (read-only)
  - Evidence: `ConfigurationTypeField` class with CHOICES

### Plugin Lifecycle Hooks (Account Domain)

- [REQ-PLUG007] Account confirmed hook
  - Given a user account confirmation, When confirmed, Then plugins receive `account_confirmed(user)` callback
- [REQ-PLUG008] Account confirmation request hook
  - Given a confirmation request, When initiated, Then plugins receive user + token + redirect URL
- [REQ-PLUG009] Account email change hook
  - Given an email change request, When initiated, Then plugins receive user + old email + new email + token
- [REQ-PLUG010] Account set password hook
  - Given a set password request, When initiated, Then plugins receive user + token + redirect URL

### Plugin Lifecycle Hooks (Commerce Domain — inferred from base_plugin interface)

- [REQ-PLUG011] Payment gateway abstraction
  - Given a payment, When processed, Then plugin receives PaymentData and returns GatewayResponse
- [REQ-PLUG012] Transaction handling hooks
  - Given a transaction, When session/action occurs, Then plugin receives TransactionActionData / TransactionSessionData
- [REQ-PLUG013] Stored payment method CRUD
  - Given a customer, When managing payment methods, Then plugin handles list/initialize/process/delete operations
- [REQ-PLUG014] Tax calculation extensibility
  - Given an order/checkout, When tax is calculated, Then plugin can provide custom tax calculations

### Plugin Memory Management

- [REQ-PLUG015] Plugin cleanup on destruction
  - Given a plugin instance, When garbage collected, Then channel, db_config, configuration, and requestor references are cleared
  - Evidence: `__del__` method explicitly clears references
- [REQ-PLUG016] Lazy requestor loading
  - Given a plugin, When requestor is needed, Then it's loaded lazily via SimpleLazyObject (not eagerly on init)
  - Evidence: `SimpleLazyObject(requestor_getter) if requestor_getter else requestor_getter`
- [REQ-PLUG017] Read replica awareness in plugins
  - Given a plugin, When database queries run, Then `allow_replica` flag controls read replica usage
  - Evidence: `allow_replica: bool = True` parameter

### Deprecation Tracking

- [REQ-DEP001] Plugin account hooks are deprecated
  - Given account lifecycle hooks, When used, Then they are marked as deprecated (moving to core modules)
  - Evidence: "Note: this method is deprecated and will be removed in a future release."

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery**: Good — extracted from interface definition (base class), configuration, and memory management
- **REQ-xxx tagging**: YES — domain-prefixed
- **Acceptance criteria**: PARTIAL — Given/When/Then for most
- **Completeness**: PARTIAL — only covered account and payment hooks. BasePlugin has 100+ hook methods (order, checkout, product, shipping, etc.)
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No instruction to extract from INTERFACE DEFINITIONS** — base classes and abstract methods are a rich source of requirements (they define the contract). The prompt should include: "when reverse-engineering, prioritize abstract classes, interfaces, and protocol definitions — they express the system's extension points"
2. **No instruction to track DEPRECATION as a requirement type** — deprecated features represent migration requirements. The prompt should add: "flag deprecated features as [REQ-DEP-xxx] — they represent future removal and migration needs"
3. **No instruction to distinguish "must implement" vs "can implement" hooks** — some plugin methods are required (must implement to function), others are optional. The prompt should instruct: "for extensibility requirements, note which are mandatory vs optional"
