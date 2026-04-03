# Run 02: Explain GraphQL Resolvers to REST Developer

## Source Repo: saleor
## Key Files: saleor/graphql/product/resolvers.py, saleor/graphql/webhook/resolvers.py

## Teaching Output

### What You Already Know (REST Anchor)

In REST, you have endpoints like `GET /products/123` that return a fixed JSON shape. The server decides what fields come back. If the client needs both product details and the vendor, that's two requests: `GET /products/123` then `GET /vendors/456`.

GraphQL flips this: the client writes a query asking for exactly the fields it wants, and the server figures out how to get each field.

### The Core Idea: One Function Per Field

A "resolver" is a function that knows how to fetch one piece of data. Think of it like this:

| REST | GraphQL |
|---|---|
| One view returns entire JSON object | One resolver returns one field (or a set of related fields) |
| `GET /products` = list of product dicts | `resolve_products()` returns a queryset; individual field resolvers handle nested data |

From saleor's `product/resolvers.py`:

```python
def resolve_categories(info: ResolveInfo, level=None):
    qs = models.Category.objects.using(
        get_database_connection_name(info.context)
    ).prefetch_related("children")
    if level is not None:
        qs = qs.filter(level=level)
    return qs
```

This looks like a Django view that returns a queryset — because it basically is. The difference: it doesn't serialize to JSON. GraphQL handles that part, calling sub-resolvers for each field the client requested.

### Step-by-Step: How a Query Resolves

Client sends:
```graphql
query { categories(level: 0) { name, children { name } } }
```

1. GraphQL calls `resolve_categories(info, level=0)` -- returns Category queryset
2. For each category, GraphQL calls the `name` resolver (default: `category.name`)
3. For each category, GraphQL calls the `children` resolver (from `prefetch_related`)
4. For each child, GraphQL calls `name` again

This is the "resolver tree" — it walks down the query shape, calling a resolver at each node.

### The info Object = Your request

In REST, you have `request` with user, headers, etc. In GraphQL, `info: ResolveInfo` carries the same data:

```python
def resolve_webhook(info: ResolveInfo, id, app):
    user = info.context.user  # Like request.user in Django
    database_connection_name = get_database_connection_name(info.context)
```

`info.context` is saleor's `SaleorContext` — equivalent to Django's `request`, holding the authenticated user, database connection preferences, and dataloaders.

### Permission Checking in Resolvers

In REST, you'd use `@permission_required('can_view_products')`. In saleor's GraphQL:

```python
def resolve_webhook(info, id, app):
    user = info.context.user
    if user and user.has_perm(AppPermission.MANAGE_APPS):
        # ... return the webhook
    raise PermissionDenied(permissions=[AppPermission.MANAGE_APPS])
```

Same `has_perm()` you know from Django, just called inside the resolver instead of a decorator.

### Key Insight: Resolvers Are Just Data-Fetching Functions

Strip away the GraphQL terminology and resolvers are functions that:
1. Accept the parent object + arguments
2. Check permissions
3. Query the database
4. Return data (not serialized — GraphQL handles serialization)

If you can write a Django view that returns a queryset, you can write a resolver.

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: YES - REST comparison throughout
- **Progressive disclosure**: YES - Built from concept (one function per field) to real code to permission patterns
- **Practical examples**: YES - Used actual saleor resolver code
- **Multiple explanation approaches**: PARTIAL - Used code + table + step-by-step, but no visual tree diagram
- **Verify understanding**: NO - No exercises provided

### Prompt Gaps Identified
1. **Same gap as Run 01**: No explicit instruction to start from the learner's existing framework
2. **No instruction to address misconceptions** — REST developers often think "one resolver = one endpoint" when it's actually "one resolver = one field." The prompt should instruct: "identify and correct likely misconceptions from the source framework"
3. **No instruction to explain tradeoffs** — when is REST better? When is GraphQL better? The prompt's Chaos Resilience section mentions "present all with trade-offs" but this isn't in the main Key Actions
