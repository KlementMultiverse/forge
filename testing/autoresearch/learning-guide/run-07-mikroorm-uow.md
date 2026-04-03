# Run 07: Explain the MikroORM Unit-of-Work Pattern (medusa)

## Source Repo: medusa
## Key Files: packages/modules/order/src/models/order.ts, packages/modules/cart/src/models/cart.ts

## Teaching Output

### What You Already Know: Django's "Save Each Object" Approach

In Django, when you change a model, you call `.save()` and it immediately writes to the database:

```python
order.status = "completed"
order.save()  # SQL UPDATE runs NOW

line_item.quantity = 5
line_item.save()  # Another SQL UPDATE runs NOW
```

Two changes = two separate database operations. If the second one fails, the first already happened. You have to manually wrap them in `transaction.atomic()`.

### MikroORM's Unit of Work: "Collect Changes, Flush Once"

MikroORM (used by Medusa) tracks all changes in memory and writes them all at once when you "flush":

```
order.status = "completed"     // Tracked in memory, nothing written yet
lineItem.quantity = 5          // Also tracked, still nothing written
await em.flush()               // NOW both changes write in one transaction
```

The "Unit of Work" pattern means: collect all the changes from a single business operation, then apply them as one atomic database transaction.

### How Medusa Models Define Relationships

Look at Medusa's Order model:

```typescript
const _Order = model
  .define("Order", {
    id: model.id({ prefix: "order" }).primaryKey(),
    status: model.enum(OrderStatus).default(OrderStatus.PENDING),
    currency_code: model.text(),
    items: model.hasMany<any>(() => OrderItem, { mappedBy: "order" }),
    shipping_methods: model.hasMany<any>(() => OrderShipping, { mappedBy: "order" }),
    transactions: model.hasMany<any>(() => OrderTransaction, { mappedBy: "order" }),
  })
  .cascades({
    delete: ["summary", "items", "shipping_methods", "transactions", "credit_lines"],
  })
```

Key differences from Django:

| Django ORM | MikroORM (Medusa) |
|---|---|
| `models.ForeignKey(Order, on_delete=CASCADE)` | `.cascades({ delete: ["items"] })` |
| `related_name="items"` | `mappedBy: "order"` |
| Implicit auto-increment ID | `model.id({ prefix: "order" }).primaryKey()` — prefixed IDs like `order_01ABC` |
| `models.Index(fields=[...])` | `.indexes([{ name: "...", on: [...], where: "..." }])` — conditional indexes |

### The Identity Map: No Duplicate Objects

Part of Unit of Work is the "Identity Map." If you load the same order twice:

```
const order1 = await orderRepo.findOne(id)
const order2 = await orderRepo.findOne(id)
order1 === order2  // TRUE — same JavaScript object
```

In Django, you'd get two separate Python objects. MikroORM guarantees one object per database row per Entity Manager session. This prevents conflicting updates.

### Cascade Deletes: Declarative, Not Imperative

Medusa's Cart model:
```typescript
.cascades({
    delete: ["items", "shipping_methods", "shipping_address", "billing_address"],
})
```

When you delete a Cart, MikroORM automatically deletes all its items, shipping methods, and addresses — in the correct dependency order, within the same Unit of Work flush. In Django, you'd configure this per-ForeignKey with `on_delete=CASCADE`, which works at the database level. MikroORM does it at the application level, giving more control over ordering.

### Why Unit of Work Matters for Commerce

An order placement involves: create order, create line items, create shipping, create transaction. If you do these as 4 separate INSERT statements and #3 fails, you have an order with items but no shipping. Unit of Work means all 4 inserts happen in one transaction — all succeed or all roll back.

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: YES - Django ORM as explicit comparison point
- **Progressive disclosure**: YES - Django save pattern → UoW concept → model definition → identity map → cascades → why it matters
- **Practical examples**: YES - Real medusa model code
- **Multiple explanation approaches**: YES - Code, comparison table, conceptual explanation
- **Verify understanding**: NO - No exercises

### Prompt Gaps Identified
1. **No instruction to explain the "pattern name" and its origin** — "Unit of Work" is a Martin Fowler pattern. Learners benefit from knowing the canonical source. The prompt should instruct: "when teaching a named pattern, cite the origin and link to further reading"
2. **No instruction to show the failure mode** — what happens when you DON'T use Unit of Work? Showing the broken case makes the solution click. The prompt should require: "show what goes wrong without the pattern before showing the pattern"
3. **Recurring: no exercises**
