# Run 04: Extract Commerce API Requirements from Medusa Routes

## Source: packages/medusa/src/api/admin/stores/route.ts, packages/modules/order/src/models/order.ts, packages/modules/cart/src/models/cart.ts

## Extracted Requirements

### Store Management

- [REQ-STORE001] Admin can list stores with filtering and pagination
  - Given an authenticated admin, When GET /admin/stores, Then stores are returned with count, offset, limit
  - Evidence: `GET` handler uses `remoteQuery` with `filters`, `pagination`, `fields`
- [REQ-STORE002] Field selection is client-driven
  - Given a query, When fields parameter is provided, Then only requested fields are returned
  - Evidence: `req.queryConfig.fields` passed to `remoteQueryObjectFromString`

### Order Model

- [REQ-ORDER001] Orders have prefixed IDs (e.g., order_01ABC)
  - Given a new order, When created, Then ID has "order" prefix
  - Evidence: `model.id({ prefix: "order" }).primaryKey()`
- [REQ-ORDER002] Orders have human-readable auto-increment display IDs
  - Given a new order, When created, Then a searchable auto-increment display_id is assigned
  - Evidence: `display_id: model.autoincrement().searchable()`
- [REQ-ORDER003] Order status lifecycle
  - Given an order, When status changes, Then it follows OrderStatus enum (PENDING default)
  - Evidence: `status: model.enum(OrderStatus).default(OrderStatus.PENDING)`
- [REQ-ORDER004] Orders support draft mode
  - Given an order, When `is_draft_order=true`, Then it is treated as a draft
  - Evidence: `is_draft_order: model.boolean().default(false)`
- [REQ-ORDER005] Order addresses are one-to-one with cascade ownership
  - Given an order, When it has shipping/billing address, Then addresses are owned (foreign key, not shared)
  - Evidence: `shipping_address: model.hasOne(() => OrderAddress, { mappedBy: undefined, foreignKey: true })`
- [REQ-ORDER006] Order deletion cascades to related entities
  - Given an order, When deleted, Then summary, items, shipping_methods, transactions, credit_lines are deleted
  - Evidence: `.cascades({ delete: ["summary", "items", "shipping_methods", "transactions", "credit_lines"] })`
- [REQ-ORDER007] Soft delete support
  - Given an order, When "deleted", Then `deleted_at` timestamp is set (not hard deleted)
  - Evidence: Index conditions like `where: "deleted_at IS NULL"`
- [REQ-ORDER008] Orders are searchable by shipping address
  - Given an order, When searched, Then shipping_address fields are included in search
  - Evidence: `.searchable()` on shipping_address

### Cart Model

- [REQ-CART001] Carts have prefixed IDs (cart_01ABC)
  - Evidence: `model.id({ prefix: "cart" }).primaryKey()`
- [REQ-CART002] Cart completion tracking
  - Given a cart, When checkout completes, Then `completed_at` is set
  - Evidence: `completed_at: model.dateTime().nullable()`
- [REQ-CART003] Cart deletion cascades to items, shipping, and addresses
  - Given a cart, When deleted, Then items, shipping_methods, shipping_address, billing_address are cascade deleted
- [REQ-CART004] Locale support for cart
  - Given a cart, When locale is set, Then BCP 47 language tag is stored
  - Evidence: `locale: model.text().nullable()` with JSDoc showing BCP 47 format

### Cross-Cutting (Architectural)

- [REQ-ARCH001] Remote query abstraction for data fetching
  - Given any admin API, When data is needed, Then `remoteQuery` resolves it from the correct module
  - Evidence: `ContainerRegistrationKeys.REMOTE_QUERY` pattern in all route handlers
- [REQ-ARCH002] Conditional database indexes for soft-deleted records
  - Given a table with soft delete, When indexing, Then indexes exclude deleted records via `WHERE deleted_at IS NULL`
- [REQ-ARCH003] Metadata JSON field on all entities
  - Given any entity, When custom data is needed, Then `metadata` JSON field is available
  - Evidence: `metadata: model.json().nullable()` on both Order and Cart

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery**: Good from model definitions and API routes
- **REQ-xxx tagging**: YES — domain-prefixed
- **Acceptance criteria**: YES — Given/When/Then
- **Completeness**: PARTIAL — only covered stores, orders, carts. Medusa has products, payments, fulfillment, pricing, promotions, etc.
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No instruction to extract from MODEL DEFINITIONS** — ORM model definitions are a rich source of requirements (field constraints, relationships, indexes, cascades). The prompt should explicitly list "model/schema definitions" as a source for reverse-engineering requirements.
2. **No instruction to note ARCHITECTURAL PATTERNS as requirements** — the RemoteQuery pattern, prefixed IDs, and soft-delete are architectural decisions that are effectively requirements. The prompt should add: "extract architectural conventions as [REQ-ARCH-xxx] requirements"
