# Run 02: Extract E-Commerce Requirements from Saleor Code (Products, Orders, Payments)

## Source: saleor/graphql/product/resolvers.py, saleor/order/tasks.py, saleor/plugins/base_plugin.py

## Extracted Requirements

### Product Domain

- [REQ-F001] Product catalog with hierarchical categories
  - Given a product, When queried, Then categories are returned with children (nested hierarchy)
- [REQ-F002] Multi-channel product visibility
  - Given a product, When accessed by a customer, Then only products visible in their channel are returned
  - Evidence: `visible_to_user(requestor, channel_slug=channel_slug)` in resolvers
- [REQ-F003] Product attributes (custom fields per product type)
  - Given a product type, When products are queried, Then assigned attributes are returned per variant and per product
  - Evidence: Multiple attribute dataloaders (by product ID, by variant ID, by selection)
- [REQ-F004] Product media management
  - Given a product, When media is queried, Then thumbnails are served via proxy URLs with format conversion
- [REQ-F005] Permission-gated product access
  - Given a user without ProductPermissions, When querying all products, Then only published products are visible
  - Evidence: `ALL_PRODUCTS_PERMISSIONS` check in resolvers
- [REQ-F006] Translated product slugs
  - Given a product/category with translations, When queried by translated slug, Then the correct entity is returned
  - Evidence: `resolve_category_by_translated_slug(info, slug, slug_language_code)`

### Order Domain

- [REQ-F007] Bulk order recalculation
  - Given a set of order IDs, When prices change, Then orders are flagged for refresh via background task
  - Evidence: `recalculate_orders_task(order_ids)` marks `should_refresh_prices`
- [REQ-F008] Order expiration with batch processing
  - Given expired unconfirmed orders, When expiration task runs, Then orders are cancelled in batches of 100 with stock deallocation
- [REQ-F009] Order event notifications via webhook
  - Given an order update, When the update completes, Then ORDER_UPDATED webhook is fired to all registered subscribers
- [REQ-F010] Voucher usage tracking on order lifecycle
  - Given orders using voucher codes, When orders expire/cancel, Then voucher usage counts are decremented in bulk

### Payment Domain (from base_plugin.py)

- [REQ-F011] Payment gateway abstraction
  - Given multiple payment providers (Stripe, Braintree, Razorpay, etc.), When a payment is processed, Then the configured plugin handles it
- [REQ-F012] Stored payment method management
  - Given a customer, When they request stored payment methods, Then the plugin returns saved cards/methods
- [REQ-F013] Transaction tokenization flow
  - Given a payment method, When tokenization is requested, Then the plugin processes initialize/process/complete steps

### Cross-Cutting Requirements

- [REQ-NF001] Read replica routing: Background tasks use replicas by default, explicit writer opt-in required
- [REQ-NF002] Batch size limits: 100 for order expiration, 1000 for payload cleanup, 5000 for order deletion — all tuned to ~1MB memory
- [REQ-NF003] Task time limits: Self-recursive tasks include expiration_date to prevent infinite loops
- [REQ-NF004] OpenTelemetry tracing on all DataLoader batch loads and resolvers
- [REQ-NF005] Plugin system supports per-channel configuration

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery**: Extracted from code structure and patterns
- **REQ-xxx tagging**: YES
- **Acceptance criteria**: YES for functional, partial for NF
- **Completeness**: PARTIAL - only covered product, order, payment. Saleor has checkout, shipping, discount, warehouse, giftcard domains too
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No instruction for scoping when codebase is large** — Saleor has 20+ domains. The prompt doesn't say how to handle partial extraction or how to signal "more domains exist but were not covered." Should include: "if codebase is larger than task scope, explicitly list uncovered domains"
2. **No instruction to extract from code PATTERNS vs code FEATURES** — the read-replica routing, batch size tuning, and task time limits are architectural patterns that imply requirements. The prompt should instruct: "look for architectural patterns (retry logic, batch processing, caching) and extract the NFR they represent"
