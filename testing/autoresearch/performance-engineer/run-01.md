# Run 01: Saleor - GraphQL N+1 (DataLoader Usage)

## Target
- Repo: saleor (~400K lines, Python/Django + GraphQL)
- Focus: N+1 query patterns in GraphQL resolvers, DataLoader coverage

## Files Read
- `saleor/graphql/product/types/products.py` - Product type resolvers
- `saleor/graphql/product/dataloaders/products.py` - Product dataloaders
- `saleor/graphql/product/resolvers.py` - Top-level resolvers
- `saleor/graphql/order/types.py` - Order type resolvers

## Findings

### 1. DataLoader Coverage is Extensive
Saleor has **42 DataLoader references** in product types alone. Every resolver that fetches related data uses a DataLoader pattern:
- `CategoryByIdLoader`, `ProductByIdLoader`, `ProductVariantByIdLoader`
- `ProductChannelListingByProductIdLoader`, `VariantChannelListingByVariantIdLoader`
- Dataloaders exist in **20+ files** across all GraphQL domains

### 2. DataLoader Architecture Pattern
Each DataLoader uses `batch_load` with Django's `in_bulk()` for efficient batching:
```python
class ProductByIdLoader(DataLoader[int, Product]):
    def batch_load(self, keys):
        products = Product.objects.using(self.database_connection_name).in_bulk(keys)
        return [products.get(product_id) for product_id in keys]
```

### 3. Chained DataLoaders for Deep Relations
`ProductByVariantIdLoader` chains through `ProductVariantByIdLoader` -> extract product_ids -> `ProductByIdLoader.load_many()`. This avoids N+1 on nested relationships.

### 4. Potential Issue: No select_related in DataLoaders
The DataLoaders batch queries but don't use `select_related()` or `only()` to limit fields. Every `in_bulk()` call fetches all columns, which can be wasteful for large models.

### 5. Database Replica Usage
Tasks and some queries use `settings.DATABASE_CONNECTION_REPLICA_NAME` for read replicas, showing read/write split awareness.

## Does the Current Prompt Guide Finding This?
**PARTIAL** - The prompt mentions "query optimization" and "caching strategies" but:
- **NO** specific mention of N+1 detection patterns
- **NO** guidance on DataLoader patterns for GraphQL
- **NO** checklist for what to look for in ORM queries (select_related, prefetch_related, in_bulk, only/defer)
- **NO** mention of read replica routing as a performance pattern

## Gaps to Fix
1. Add N+1 query detection as explicit checklist item
2. Add DataLoader/batching pattern recognition for GraphQL
3. Add ORM-specific optimization checklist (select_related, prefetch_related, only/defer, in_bulk)
4. Add read replica routing as a pattern to identify
