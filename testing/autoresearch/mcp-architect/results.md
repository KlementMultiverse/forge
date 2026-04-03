# Autoresearch: @mcp-architect

## Research Sources
- MCP transports spec (2025-03-26): https://modelcontextprotocol.io/specification/2025-03-26/basic/transports
- 2026 MCP roadmap: http://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/
- MCP server development guide: https://github.com/cyanheads/model-context-protocol-resources/blob/main/guides/mcp-server-development-guide.md
- MCP best practices: https://mcp-best-practice.github.io/mcp-best-practice/best-practice/
- Why MCP deprecated SSE: https://blog.fka.dev/blog/2025-06-06-why-mcp-deprecated-sse-and-go-with-streamable-http/
- MCP auth (Auth0): https://auth0.com/blog/mcp-streamable-http/

## Run Results (5 Mental Simulations)

### Run 1: "Design MCP server for PostgreSQL with read/write tools"
**Result: PASS with minor gap**
- Prompt provides good tool design patterns with typed schemas
- Covers tenant isolation with path scoping
- GAP: No mention of pagination for large result sets — tools should stream/paginate, not return everything at once

### Run 2: "Design MCP server for Slack integration (read channels, send messages)"
**Result: PASS**
- Prompt covers tool design with single responsibility
- Covers rate limiting and security
- Adequate guidance

### Run 3: "Design MCP server for S3 file management (upload, download, list)"
**Result: PASS with minor gap**
- Prompt covers typed schemas and tenant isolation
- GAP: No guidance on handling large file uploads/downloads via tools — need presigned URLs or streaming, not passing full file content through MCP

### Run 4: "Design MCP server for GitHub (issues, PRs, code search)"
**Result: PASS**
- Prompt guidance on tool boundaries (max 10-12) is highly relevant here
- Adequate guidance

### Run 5: "Design MCP server for monitoring (Prometheus metrics, alerts)"
**Result: PASS**
- Prompt covers Resource primitives well for exposing monitoring data
- Adequate guidance

## CRITICAL: Transport Protocol Outdated

The prompt references `HTTP+SSE` as the remote transport, but MCP deprecated HTTP+SSE in spec version 2025-03-26 in favor of **Streamable HTTP**. Key differences:
- Streamable HTTP uses HTTP POST for client-to-server with optional SSE for streaming
- No long-lived connection requirement
- Supports resumable streams
- Better load balancer compatibility
- The old SSEServerTransport code examples in the prompt are DEPRECATED

The prompt's Step 3 code uses `SSEServerTransport` which is the old deprecated transport. Must be updated to Streamable HTTP.

## Additional Gaps

1. **CRITICAL**: Transport protocol outdated — must replace HTTP+SSE with Streamable HTTP throughout
2. **CRITICAL**: Code examples use deprecated `SSEServerTransport` — must update to Streamable HTTP transport
3. **HIGH**: Missing MCP Authentication Specification reference (OAuth 2.0/2.1 with PKCE) — prompt mentions OAuth but doesn't reference the MCP auth spec
4. **HIGH**: Missing backward compatibility guidance — servers should host old SSE endpoints alongside new Streamable HTTP for transition period
5. **HIGH**: Missing pagination/streaming for tools returning large datasets
6. **MEDIUM**: Missing tool design principle: "build tools optimized for user goals, not API wrappers" (from MCP best practices)
7. **MEDIUM**: Missing guidance on large file handling (presigned URLs, not tool content)
8. **LOW**: Missing Cloudflare Workers / serverless MCP deployment patterns
