# Run 09: MCP server security -- authentication, authorization, rate limiting patterns

## Research Topic
"MCP server security -- authentication, authorization, rate limiting patterns"

## Research Performed
- WebSearch: "MCP server security authentication authorization rate limiting patterns 2025 2026"
- WebFetch: Medium article on MCP security (403 - paywalled)

## Prompt Evaluation

### What the prompt guided well
1. **Current best practices** -- Captured OAuth 2.1 as new MCP standard, replacing custom auth
2. **Temporal Progression** -- Historical (no auth, 0.0.0.0 binding) -> Current (OAuth 2.1 spec) -> Future (June 2026 mandatory Resource Server classification)
3. **Gotchas** -- Critical finding: 53% of MCP servers use insecure hard-coded credentials
4. **Trend check** -- Noted TBAC (Task-Based Access Control) as emerging alternative to RBAC for AI agents
5. **Failure Escalation** -- When Medium 403'd, had sufficient data from other sources to complete

### What the prompt missed or was weak on
1. **No threat model instruction** -- MCP security research should start with threat modeling (what attacks? what's the blast radius?) but prompt doesn't push for it
2. **No implementation example guidance** -- Found patterns described abstractly but prompt doesn't push for "show me the code" or reference implementation
3. **No compliance framework mapping** -- How do MCP security patterns map to SOC 2, ISO 27001, etc.?
4. **No tool-specific security analysis** -- Each MCP tool has different risk profiles (file read vs network request vs code execution) but prompt treats security as monolithic
5. **No runtime vs design-time security distinction** -- Different security concerns for MCP tool registration vs tool invocation

### Research Quality Score: 8/10
- Sources found: 7 relevant including official MCP spec
- Alternatives compared: 3 auth methods (OAuth 2.1, JWT, Device Flow) + gateway approaches (Kong, Lasso)
- Actionable recommendation: Yes -- OAuth 2.1 + per-tool scopes + gateway pattern
- Key insight: 53% of MCP servers use hard-coded credentials; TBAC emerging as AI-native access control

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: MCP security is rapidly maturing. OAuth 2.1 is now the standard auth method (June 2025 spec). Per-tool scope enforcement is critical -- don't give agents blanket access. 53% of MCP servers still use hard-coded credentials. TBAC (Task-Based Access Control) is emerging as an AI-native alternative to RBAC.
### Approach Recommended: OAuth 2.1 with separated resource/auth servers. Per-tool scopes (calendar:read, email:send). Gateway pattern (Kong/Lasso) for centralized policy enforcement and rate limiting.
### Alternatives Considered:
- OAuth 2.1 Flow: Standard, PKCE-secured, session management. Recommended for HTTP transport.
- JWT Token Auth: Stateless, role-based. Good for service-to-service. Self-contained tokens.
- Device Flow: OAuth for local/CLI apps. User authenticates on separate device.
- API Gateway (Kong): Centralized OAuth + rate limiting + request screening. Enterprise pattern.
- Lasso Security: AI-specific security with prompt injection detection and MCP reputation scoring.
### Sources:
- https://modelcontextprotocol.io/specification/draft/basic/authorization
- https://aaronparecki.com/2025/11/25/1/mcp-authorization-spec-update
- https://auth0.com/blog/mcp-specs-update-all-about-auth/
- https://astrix.security/learn/blog/state-of-mcp-server-security-2025/
- https://www.infracloud.io/blogs/securing-mcp-servers/
### Delegation Hints: Next: @security-engineer should implement OAuth 2.1 with per-tool scopes for any MCP servers in the project.
### Risks/Unknowns: MCP spec is still evolving -- June 2026 update may change requirements. TBAC is nascent with limited tooling. Superuser DB connections bypass RLS (relevant if MCP connects to DB).
### Insights for Playbook:
INSIGHT: 53% of MCP servers use insecure hard-coded credentials -- always audit MCP server auth before deployment.
INSIGHT: TBAC (Task-Based Access Control) is emerging as AI-native alternative to RBAC -- authorize based on task, not role.
INSIGHT: Separate resource server from auth server for MCP -- the MCP server should validate tokens, not issue them.
INSIGHT: Per-tool scopes are non-negotiable -- blanket agent access is the #1 MCP security anti-pattern.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No threat model instruction | High | Add: "For security topics, start with threat modeling: attack vectors, blast radius, attacker capabilities" |
| No implementation example guidance | Medium | Add: "Seek reference implementations or code examples, not just abstract patterns" |
| No compliance framework mapping | Medium | Add: "Map security patterns to relevant compliance frameworks (SOC 2, ISO 27001, HIPAA)" |
| No per-component risk analysis | Medium | Add: "For system security, analyze risk per component/tool, not just the system as a whole" |
| No runtime vs design-time distinction | Low | Add: "Distinguish between design-time security (configuration) and runtime security (enforcement)" |
