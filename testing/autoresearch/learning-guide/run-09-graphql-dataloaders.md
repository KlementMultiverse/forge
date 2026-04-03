# Run 09: Explain GraphQL DataLoaders (saleor)

## Source Repo: saleor
## Key Files: saleor/graphql/core/dataloaders.py, saleor/graphql/product/resolvers.py

## Teaching Output

### The Problem: N+1 Queries

You query 10 orders, each with a customer. Without DataLoaders:

```
SELECT * FROM orders LIMIT 10;              -- 1 query
SELECT * FROM customers WHERE id = 1;       -- query per order
SELECT * FROM customers WHERE id = 2;
SELECT * FROM customers WHERE id = 3;
... (10 more queries)
```

11 queries for 10 orders. With 1000 orders, you'd have 1001 queries. This is the "N+1 problem."

### The Solution: Batch and Cache

A DataLoader collects all the IDs requested during one tick of the event loop, then fires ONE query:

```
SELECT * FROM orders LIMIT 10;              -- 1 query
SELECT * FROM customers WHERE id IN (1,2,3,...10);  -- 1 batched query
```

2 queries instead of 11.

### How Saleor Implements DataLoaders

Saleor extends the `promise` library's `DataLoader` with custom behavior:

```python
class DataLoader[K, R](BaseLoader):
    context_key: str        # Unique key per loader type
    context: SaleorContext   # Request context (user, DB connection)

    def __new__(cls, context: SaleorContext):
        # Singleton per request: if this loader already exists, return it
        if key not in context.dataloaders:
            context.dataloaders[key] = super().__new__(cls)
        return context.dataloaders[key]
```

Key design decisions:

**1. One instance per request** (via `__new__`): All resolvers in the same GraphQL query share the same DataLoader instance. This means if `resolve_order` and `resolve_order_line` both need customer #5, the customer is loaded once.

**2. Thread safety guard**:
```python
def __init__(self, context):
    thread_id = threading.get_native_id()
    current_thread_id = getattr(self, "thread_id", None)
    if current_thread_id != thread_id:
        assert current_thread_id is None, (
            "Dataloaders cannot be shared between threads"
        )
```

DataLoaders cache data in memory. Sharing between threads would cause race conditions. Saleor explicitly prevents this with a thread ID check.

**3. Batch with telemetry**:
```python
def batch_load_fn(self, keys):
    with tracer.start_as_current_span(self.__class__.__name__):
        with allow_writer_in_context(self.context):
            results = self.batch_load(keys)
```

Every batch load is traced (OpenTelemetry) so you can see in your APM dashboard which DataLoaders are slow.

### How Resolvers Use DataLoaders

From the product resolvers, the pattern is:

```python
# In a resolver (simplified):
def resolve_customer(order, info):
    return CustomerByIdLoader(info.context).load(order.customer_id)
```

`.load(id)` doesn't query immediately — it returns a Promise. The DataLoader collects all `.load()` calls from all resolvers, then fires `batch_load_fn` with all the collected IDs at once.

### DataLoader vs Django's prefetch_related

| Aspect | Django prefetch_related | GraphQL DataLoader |
|---|---|---|
| Scope | Per-queryset | Per-request |
| Declaration | On the queryset: `.prefetch_related("items")` | In the resolver: `Loader(ctx).load(id)` |
| Knows what's needed | You must declare upfront | Collects dynamically based on query shape |
| Caching | Django's queryset cache | In-memory dict per DataLoader instance |
| Batching | One query per prefetch | One query per batch_load_fn call |

The key difference: `prefetch_related` requires you to know which relations will be needed at query time. DataLoaders adapt to whatever the GraphQL client requests.

### The Identity Map Bonus

Because DataLoaders cache results per-request, they also serve as an identity map: loading the same customer ID twice returns the same object from cache. This prevents duplicate queries AND duplicate objects.

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: YES - N+1 problem (universal) and Django prefetch_related comparison
- **Progressive disclosure**: YES - Problem → solution concept → implementation → usage → comparison
- **Practical examples**: YES - Real saleor DataLoader code
- **Multiple explanation approaches**: YES - Query examples, code, comparison table
- **Verify understanding**: NO - No exercises

### Prompt Gaps Identified
1. **No instruction to start with the PROBLEM before the solution** — this is a fundamental teaching technique. I did it naturally, but the prompt should mandate: "always present the problem/pain point before introducing the solution"
2. **No instruction to quantify impact** — saying "11 queries vs 2" makes the benefit concrete. The prompt should instruct: "when explaining performance patterns, include concrete numbers showing the before/after difference"
3. **Recurring: no exercises**
4. **No instruction to compare with the learner's framework equivalent** — the DataLoader vs prefetch_related table is critical for a Django developer. The prompt should require: "always provide a comparison table with the learner's existing tool for the same problem"
