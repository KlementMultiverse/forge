# Test: @azure-setup-agent -- Run 1/10

## Input
"Set up Azure infrastructure for a Python API with Blob Storage + Functions + Key Vault"

## Score: 17/17 (100%)

1. Single responsibility: PASS -- Focused on Azure resource provisioning: resource group creation, service deployment, Key Vault secret management, and RBAC configuration
2. Forge Cell: PASS -- Infrastructure cell specializing in Microsoft Azure resource provisioning
3. context7: PASS -- Fetches azure-storage-blob, azure-functions, azure-keyvault-secrets, and azure-identity docs for current SDK patterns
4. Web search: PASS -- Searches for latest Azure Functions Python v2 programming model, Key Vault RBAC vs access policies, and Blob Storage lifecycle management
5. Self-executing: PASS -- Runs az CLI commands to provision resources, stores secrets in Key Vault, deploys test function, and validates connectivity via Bash
6. Handoff: PASS -- Returns Bicep/az CLI scripts, Key Vault access policy, RBAC assignments, .env template, and deployment verification results to orchestrator
7. [REQ-xxx]: PASS -- Tags with [REQ-AZR-001] resource group setup, [REQ-AZR-002] Blob Storage config, [REQ-AZR-003] Functions deployment, [REQ-AZR-004] Key Vault integration
8. Per-agent judge: PASS -- Validates Function can read Key Vault secrets via managed identity, Blob Storage accessible from Function, RBAC assignments follow least-privilege
9. Specific rules: PASS -- Enforces managed identity over connection strings, Key Vault RBAC mode (not legacy access policies), Blob soft-delete enabled, Functions Python v2 model, and network rules restricting public access
10. Failure escalation: PASS -- Escalates if Azure subscription quota hit, Key Vault purge protection blocks recreation, managed identity assignment fails, or region capacity unavailable
11. /learn: PASS -- Records effective RBAC role assignments for Python Functions, Key Vault secret naming conventions, and Blob container access tier selection
12. Anti-patterns: PASS -- 5 items: no connection strings when managed identity available, no legacy Key Vault access policies, no public Blob containers, no Functions with admin-level RBAC, no hardcoded secrets in app settings
16. Confidence routing: PASS -- High for standard resource provisioning, medium for private endpoint and VNet integration, low for complex RBAC custom role definitions
17. Self-correction loop: PASS -- Re-assigns RBAC if managed identity cannot access Key Vault; re-deploys Function with adjusted runtime if initial deploy fails
18. Negative instructions: PASS -- Never use connection strings over managed identity, never use legacy access policies for Key Vault, never expose Blob containers publicly, never store secrets in Function app settings
19. Tool failure handling: PASS -- Retries az CLI on transient errors; checks resource provider registration before creation; validates quota before provisioning
20. Chaos resilience: PASS -- Handles expired az login session, resource lock preventing deletion, Key Vault soft-delete conflict, partial deployment cleanup, and region failover requirements

## Key Strengths
- Enforces managed identity as the sole authentication method between Azure services, eliminating connection string and secret rotation overhead
- Uses Key Vault RBAC mode (modern) instead of legacy access policies, with per-secret granular access control
- Generates Bicep templates alongside az CLI scripts for reproducible infrastructure-as-code deployments

## Verdict: PERFECT (100%)
