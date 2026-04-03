# Run 10: Extract Integration Requirements from Saleor (Webhooks, External Services)

## Source: saleor/webhook/event_types.py, saleor/graphql/webhook/resolvers.py, saleor/plugins/webhook/plugin.py, saleor/plugins/base_plugin.py

## Extracted Requirements

### Webhook System

- [REQ-INT001] Async webhook event types covering all domain events
  - Given any entity mutation, When it occurs, Then an async webhook event is fired
  - Evidence: WebhookEventAsyncType defines events for: account, address, app, attribute, attribute_value, category, channel, gift_card (and many more based on the pattern)
- [REQ-INT002] Sync webhook event types for real-time operations
  - Given operations requiring external decision (payment, shipping, tax), When invoked, Then sync webhooks wait for response
  - Evidence: `WebhookEventSyncType` class exists alongside async type
- [REQ-INT003] Permission-gated webhook registration
  - Given an app or user, When registering webhooks, Then AppPermission.MANAGE_APPS is required
  - Evidence: `resolve_webhook()` checks `has_perm(AppPermission.MANAGE_APPS)`
- [REQ-INT004] Webhook scoped to app
  - Given an app, When querying webhooks, Then only that app's webhooks are returned
  - Evidence: `app.webhooks.filter(id=id).first()` in resolve_webhook
- [REQ-INT005] Sample payload generation for webhook testing
  - Given a webhook event type, When sample is requested, Then a test payload is generated
  - Evidence: `resolve_sample_payload()` calls `payloads.generate_sample_payload(event_name)`
- [REQ-INT006] Permission check per event type for sample payloads
  - Given an event type, When sample payload is requested, Then the user/app must have the specific permission for that event domain
  - Evidence: `WebhookEventAsyncType.PERMISSIONS.get(event_name)` lookup

### Event Domains Covered (from event_types.py)

- [REQ-INT007] Account events: confirmed, confirmation_requested, email_changed, set_password_requested, deleted
- [REQ-INT008] Address events: created, updated, deleted
- [REQ-INT009] App lifecycle events: installed, updated, deleted, status_changed
- [REQ-INT010] Attribute events: created, updated, deleted (both attribute and attribute_value)
- [REQ-INT011] Category events: created, updated, deleted
- [REQ-INT012] Channel events: created, updated, deleted, status_changed, metadata_updated
- [REQ-INT013] Gift card events: created (and presumably updated, deleted — pattern continues)

### Permission Matrix for Webhooks

- [REQ-INT014] Granular permissions per domain
  - Given webhook events, When permissions are checked, Then each domain maps to its permission enum:
    - Account events → AccountPermissions
    - App events → AppPermission
    - Order events → OrderPermissions
    - Product events → ProductPermissions
    - Checkout events → CheckoutPermissions
    - Payment events → PaymentPermissions
    - etc.
  - Evidence: Import of all permission enums in event_types.py

### External Service Integration Pattern

- [REQ-INT015] Plugin-based external service abstraction
  - Given an external service (payment gateway, email, webhook), When integrated, Then it's wrapped in a plugin class extending BasePlugin
  - Evidence: `saleor/plugins/webhook/plugin.py`, `saleor/plugins/user_email/plugin.py`, `saleor/plugins/admin_email/plugin.py`
- [REQ-INT016] Payment gateway integrations
  - Given payment processing, When a gateway is configured, Then the appropriate plugin handles it
  - Evidence: Plugins exist for: Stripe, Braintree, Razorpay, Authorize.net, plus dummy/test gateways
- [REQ-INT017] Email notification integration
  - Given account/order lifecycle events, When notifications are needed, Then user_email and admin_email plugins handle delivery
- [REQ-INT018] Read replica awareness for webhook queries
  - Given webhook resolution queries, When database is accessed, Then `get_database_connection_name(info.context)` is used to select appropriate replica
  - Evidence: All resolvers use `using(database_connection_name)` for queries

### Webhook Delivery (Inferred from EventDelivery model)

- [REQ-INT019] Webhook delivery tracking
  - Given a webhook event, When delivery is attempted, Then EventDelivery and EventDeliveryAttempt records are created
  - Evidence: EventDelivery model referenced in core/tasks.py cleanup logic
- [REQ-INT020] Webhook payload cleanup with retention period
  - Given old event payloads, When retention period expires, Then payloads are deleted in batches
  - Evidence: `delete_event_payloads_task` with `EVENT_PAYLOAD_DELETE_PERIOD` setting
- [REQ-INT021] Webhook payload file storage
  - Given large payloads, When stored, Then they can be saved to file storage (not just DB)
  - Evidence: `event_payload.payload_file.name` in cleanup task

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery**: Good — extracted from event types, resolvers, plugin registry, and delivery infrastructure
- **REQ-xxx tagging**: YES — INT-prefixed for integration domain
- **Acceptance criteria**: PARTIAL — some requirements are enumerations rather than Given/When/Then
- **Completeness**: PARTIAL — covered webhook system thoroughly but didn't cover other integrations (SQS, Sentry, external tax services)
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No instruction to extract the INTEGRATION PATTERN, not just individual integrations** — Saleor's plugin system IS the integration pattern. The prompt should instruct: "when extracting integration requirements, first identify the integration pattern (plugin, webhook, adapter, etc.) before listing individual integrations"
2. **No instruction to extract DELIVERY GUARANTEES** — webhooks need at-least-once delivery, retry logic, dead-letter handling. The prompt should add: "for event/message-based integrations, extract delivery guarantees (at-least-once, exactly-once, retry policy, dead-letter)"
3. **No instruction to extract the PERMISSION MODEL for integrations** — the per-event-type permission mapping is a security requirement for the integration system. The prompt should instruct: "for APIs and webhooks, extract the authorization model as separate requirements"
