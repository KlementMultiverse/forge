# Run 05: Explain Celery Task Architecture in Saleor

## Source Repo: saleor
## Key Files: saleor/core/tasks.py, saleor/order/tasks.py

## Teaching Output

### The Problem: Work That's Too Slow for a Request

When a user places an order, you need to: update stock, send emails, trigger webhooks, recalculate prices. If you do all of this inside the HTTP request, the user waits 10 seconds. Celery lets you say "do this later, in the background."

### Basic Pattern: @app.task

```python
from ..celeryconf import app

@app.task
def delete_from_storage_task(path):
    default_storage.delete(path)
```

That's it. `@app.task` registers this function with Celery. Instead of calling `delete_from_storage_task(path)` directly, you call `delete_from_storage_task.delay(path)` — this puts a message on Redis/RabbitMQ, and a Celery worker picks it up later.

**Mental model**: `.delay()` = "put a sticky note on the fridge for someone else to handle."

### Saleor's Base Task: RestrictWriterDBTask

Saleor adds a custom base class for database safety:

```python
class RestrictWriterDBTask(Task):
    def __call__(self, *args, **kwargs):
        wrapper_fun = import_string(settings.CELERY_RESTRICT_WRITER_METHOD)
        with connections[settings.DATABASE_CONNECTION_DEFAULT_NAME].execute_wrapper(
            wrapper_fun
        ):
            return super().__call__(*args, **kwargs)
```

This wraps every task execution with a DB connection guard. In tests, it raises an exception if a task tries to write to the "writer" database without explicitly opting in. In production, it logs a warning.

**Why**: With read replicas, background tasks shouldn't write to the primary DB unless they explicitly need to. This prevents accidental writes from tasks that should only read.

### Real-World Pattern: Batch Processing with Self-Recursion

```python
@app.task
def delete_event_payloads_task(expiration_date=None):
    # ... query for batch of 1000 payloads to delete ...
    ids = list(payloads_to_delete.values_list("pk", flat=True)[:BATCH_SIZE])
    if ids:
        if expiration_date > timezone.now():
            qs = EventPayload.objects.filter(pk__in=ids)
            with allow_writer():
                qs.delete()
            # Schedule next batch
            delete_event_payloads_task.delay(expiration_date)
        else:
            task_logger.error("Task invocation time limit reached, aborting")
```

Pattern breakdown:
1. Process a batch of 1000 records
2. If there are more, **re-queue yourself** with `.delay()` for the next batch
3. Include a time limit to prevent infinite loops

This is better than processing millions of records in one task because:
- Each batch is a separate Celery task (can be retried independently)
- Memory stays bounded (~1MB per batch, per the comment)
- Other tasks get CPU time between batches

### Order Tasks: @allow_writer() Decorator

```python
@app.task
@allow_writer()
def recalculate_orders_task(order_ids: list[int]):
    orders = Order.objects.filter(id__in=order_ids)
    for order in orders:
        invalidate_order_prices(order)
    Order.objects.bulk_update(orders, ["should_refresh_prices"])
```

`@allow_writer()` explicitly opts this task into writing to the primary DB. Without it, `RestrictWriterDBTask` would block the write.

### Task Chaining: One Task Triggers Another

```python
# In delete_event_payloads_task:
with allow_writer():
    qs.delete()
delete_files_from_private_storage_task.delay(files_to_delete)  # Next task
delete_event_payloads_task.delay(expiration_date)               # Self-recurse
```

After deleting DB records, it queues file deletion as a separate task. Separation of concerns: DB cleanup and file cleanup are independent operations that can fail independently.

### Summary: Saleor's Celery Patterns

| Pattern | Example | Purpose |
|---|---|---|
| Simple async | `delete_from_storage_task.delay(path)` | Fire and forget |
| Batch + self-recurse | `delete_event_payloads_task` | Process millions without OOM |
| Writer restriction | `RestrictWriterDBTask` base class | Prevent accidental DB writes |
| Explicit writer opt-in | `@allow_writer()` | Tasks that must write |
| Task chaining | `.delay()` inside a task | Decompose complex workflows |

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: PARTIAL - Used "work too slow for request" but didn't anchor to a specific framework the learner knows
- **Progressive disclosure**: YES - Simple task → base class → batch pattern → chaining
- **Practical examples**: YES - Real saleor code throughout
- **Multiple explanation approaches**: YES - Code, mental model (sticky note), table
- **Verify understanding**: NO - No exercises

### Prompt Gaps Identified
1. **No instruction to specify the "audience bridge"** — the task says "explain Celery task architecture" but doesn't specify what the learner already knows. The prompt should require: "if audience context is given, anchor every new concept to something they already know"
2. **No instruction to explain WHEN NOT to use the pattern** — Celery has overhead (broker, worker process, serialization). When is a simple `threading.Thread` enough? The prompt should include: "for every pattern taught, explain when it's overkill"
3. **Pattern recognition gap**: The prompt doesn't instruct the agent to name the patterns it sees (e.g., "self-recursion batch", "explicit opt-in guard"). Naming patterns helps learners build a vocabulary.
