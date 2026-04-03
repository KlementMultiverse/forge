# Run 08: Clinic Portal - S3/Lambda Latency Patterns, boto3 Client Reuse

## Target
- Repo: clinic-portal (Python/Django multi-tenant)
- Focus: S3 and Lambda call patterns, boto3 client reuse

## Files Read
- `apps/documents/services.py` - Full file (S3 + Lambda + LLM integration)
- `apps/documents/api.py` - Document API endpoints

## Findings

### 1. boto3 Client Created on EVERY Call (Critical)
```python
def get_s3_client():
    return boto3.client("s3", region_name=..., aws_access_key_id=..., aws_secret_access_key=...)
```
Every function that touches S3 calls `get_s3_client()`:
- `generate_upload_url()` -> `get_s3_client()`
- `generate_download_url()` -> `get_s3_client()`
- `delete_s3_object()` -> `get_s3_client()`

boto3 client creation involves:
- TLS handshake setup
- Credential validation
- Connection pool initialization
- Service model loading

Per web research, this adds ~50-200ms overhead per call. For a page that shows 10 documents (each needing a download URL), that's 500ms-2s of pure client creation overhead.

### 2. Lambda Client Also Created Per Call (Critical)
```python
def invoke_summarize_lambda(text, user_context=None):
    lambda_client = boto3.client("lambda", region_name=..., ...)
```
Same pattern in `invoke_generate_tasks_lambda()`. Two separate functions, each creating a new Lambda client.

### 3. Fix is Simple: Module-Level Client or Lazy Singleton
```python
# Module-level (best for Django)
_s3_client = None
def get_s3_client():
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client("s3", ...)
    return _s3_client
```
boto3 clients are thread-safe, so a single module-level client works fine in Django's multi-threaded WSGI model.

### 4. Synchronous Lambda Invocation Blocks Django Worker
```python
response = lambda_client.invoke(
    FunctionName=lambda_arn,
    InvocationType="RequestResponse",
    Payload=json.dumps(payload_data),
)
```
`RequestResponse` blocks the Django worker thread until Lambda returns (could be 5-30s for LLM calls). During this time, the worker cannot serve other requests. With default Gunicorn workers (2-4), a few concurrent LLM requests can exhaust the worker pool.

### 5. urllib.request for LLM API (No Connection Pooling)
The direct Claude API call uses `urllib.request.urlopen()`:
```python
with urllib.request.urlopen(req, timeout=30) as resp:
```
No connection pooling, no keep-alive. Each call creates a new TCP+TLS connection. `requests` or `httpx` with a Session would reuse connections.

### 6. No Response Caching for Repeated Summaries
If the same document is summarized twice, it calls Lambda/LLM both times. No caching of summaries at the service layer.

## Does the Current Prompt Guide Finding This?
**NO** for cloud service client patterns:
- **NO** boto3/cloud client reuse as explicit check
- **NO** synchronous external API blocking detection
- **NO** connection pooling for HTTP clients
- **NO** cloud service latency budgeting
- **NO** response caching for expensive external calls

## Gaps to Fix
1. Add cloud client reuse detection (boto3, GCP, Azure SDKs)
2. Add synchronous external call blocking detection
3. Add HTTP client connection pooling checklist
4. Add external call latency budgeting
5. Add response caching for expensive external operations
