# /create-mcp — Build a Custom MCP Server

Create a production-grade MCP server from a description. Uses patterns from Claude Code's tool system and MCP specification.

## Input
$ARGUMENTS — description of what the MCP server should do (e.g., "MCP server for querying PostgreSQL databases")

## Phase 0: Context Loading (MANDATORY)

<system-reminder>
Read CLAUDE.md and existing MCP servers before creating anything.
Fetch MCP SDK docs via context7 BEFORE writing any code.
</system-reminder>

1. Read CLAUDE.md → understand project context
2. Fetch MCP SDK docs: `resolve-library-id("@modelcontextprotocol/sdk")` or `resolve-library-id("mcp")` → `query-docs`
3. Read existing MCP servers in the project (if any) for patterns
4. Web search "MCP server [domain] best practices [current year]"

## Phase 1: Design

Spawn `@mcp-architect` with:
  TASK: Design MCP server for "$ARGUMENTS"
  CONTEXT: MCP SDK docs + project CLAUDE.md
  EXPECTED OUTPUT: Tool definitions, resource definitions, transport choice, auth requirements

## Phase 2: Scaffold

Choose SDK based on project stack:
- Python project → FastMCP (Python SDK)
- TypeScript project → @modelcontextprotocol/sdk

### Python MCP Server Template:
```python
"""MCP Server: [name]"""
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("[server-name]")

@mcp.tool()
def tool_name(param: str) -> str:
    """Clear description of what this tool does — LLM reads this to decide when to use it."""
    # Implementation
    return result

@mcp.resource("resource://[name]/{id}")
def get_resource(id: str) -> str:
    """Resource description."""
    return data

if __name__ == "__main__":
    mcp.run(transport="stdio")
```

### TypeScript MCP Server Template:
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

const server = new McpServer({ name: "[server-name]", version: "1.0.0" });

server.tool("tool_name", { param: z.string() }, async ({ param }) => {
  return { content: [{ type: "text", text: result }] };
});

server.run();
```

## Phase 3: Implement

1. Create the MCP server file
2. Define tools with clear descriptions (LLM reads these)
3. Add error handling for every tool
4. Add input validation via Pydantic (Python) or Zod (TypeScript)
5. Test the server:
   ```bash
   # Python
   uv run python mcp_server.py  # Should start without errors
   # TypeScript
   npx tsx mcp_server.ts
   ```

## Phase 4: Register

Add to Claude Code settings:
```json
{
  "mcpServers": {
    "[server-name]": {
      "command": "uv",
      "args": ["run", "python", "mcp_server.py"]
    }
  }
}
```

## Phase 5: Verify

1. Start the MCP server
2. Test each tool via Claude Code
3. Verify error handling works

## Handoff

```
## Handoff: create-mcp → [next step]
### Task Completed: MCP server "[name]" created with [N] tools and [N] resources
### Files Changed: [list]
### Test Results: Server starts, tools callable, errors handled
### Context for Next Agent: MCP server ready. Add to settings.json to enable.
### Blockers: [any issues]
```
