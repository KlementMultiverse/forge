# Run 09: Saleor - Database Index Strategy for GraphQL Resolvers

## Target
- Repo: saleor (~400K lines, Python/Django + GraphQL)
- Focus: Database index strategy, index coverage for query patterns

## Files Read
- `saleor/order/models.py` - Order model indexes
- `saleor/graphql/order/types.py` - Order GraphQL resolvers
- `saleor/graphql/order/mutations/` - Various order mutations (select_related/prefetch_related usage)
- `saleor/graphql/product/resolvers.py` - Product query resolvers

## Findings

### 1. Comprehensive Index Strategy on Order Model (Good)
Order model has well-thought-out indexes:
```python
class Meta:
    indexes = [
        GinIndex(name="order_search_gin", fields=["search_document"], ...),
        # plus ModelWithMetadata.Meta.indexes
    ]
```
- `updated_at` has `db_index=True`
- `authorize_status` and `charge_status` have `db_index=True`
- Custom GIN index for full-text search

### 2. Deliberate Non-Indexing (Good)
```python
voucher_code = models.CharField(max_length=255, null=True, blank=True, db_index=False)
related = models.ForeignKey(..., db_index=False)
```
Saleor deliberately disables auto-indexing on columns that are rarely filtered. This reduces write overhead and storage.

### 3. BTree Indexes for Common Filters
OrderEvent model:
```python
indexes = [
    BTreeIndex(fields=["related"], name="order_orderevent_related_id_idx"),
    models.Index(fields=["type"]),
    BTreeIndex(fields=["date"], name="order_orderevent_date_idx"),
]
```
Well-aligned with query patterns (events filtered by type, ordered by date).

### 4. Fulfillment Status Index
```python
indexes = [BTreeIndex(fields=["status"], name="fulfillment_status_idx")]
```
Directly supports filtering fulfillments by status in GraphQL queries.

### 5. OrderLine Missing Product Type Index
OrderLine has `product_type_id` in a BTreeIndex on the product model but order lines reference variants, not product types directly. Queries joining order lines -> variants -> products -> product types may not benefit from this index.

### 6. select_related/prefetch_related Usage in Mutations
Mutations properly use these:
```python
qs=order_models.OrderLine.objects.select_related("variant")
qs=models.Order.objects.prefetch_related("lines__variant")
```
But GraphQL type resolvers rely on DataLoaders instead. The two approaches should be consistent.

## Does the Current Prompt Guide Finding This?
**PARTIAL**:
- **YES** mentions "query optimization" generically
- **NO** index coverage analysis methodology (compare query patterns to available indexes)
- **NO** index type awareness (BTree vs GIN vs GiST vs partial indexes)
- **NO** write overhead consideration (too many indexes slow writes)
- **NO** composite index ordering rules (selectivity, range scans)
- **NO** EXPLAIN ANALYZE interpretation guidance

## Gaps to Fix
1. Add index coverage analysis methodology
2. Add index type selection guidance (BTree, GIN, GiST, partial, covering)
3. Add write vs read tradeoff for index decisions
4. Add composite index column ordering rules
5. Add EXPLAIN ANALYZE interpretation checklist
