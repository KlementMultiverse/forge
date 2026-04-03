# Test: @azure-openai-agent -- Run 1/10

## Input
"Deploy GPT-4o on Azure OpenAI with content filtering and LiteLLM gateway integration"

## Score: 17/17 (100%)

1. Single responsibility: PASS -- Focused on Azure OpenAI resource deployment, model provisioning, content filtering policy configuration, and gateway integration
2. Forge Cell: PASS -- Implementer cell specializing in Azure OpenAI service configuration and LLM deployment
3. context7: PASS -- Fetches openai (Azure variant), litellm, and azure-identity docs for current Azure OpenAI API and content filter configuration
4. Web search: PASS -- Searches for latest GPT-4o availability on Azure OpenAI by region, content filtering policy options, and LiteLLM Azure integration patterns
5. Self-executing: PASS -- Runs az CLI to deploy Azure OpenAI resource, provisions model, configures content filter, and validates via completion test in Bash
6. Handoff: PASS -- Returns deployment scripts, LiteLLM config snippet, content filter policy, test completion results, and TPM quota report to orchestrator
7. [REQ-xxx]: PASS -- Tags with [REQ-AOI-001] resource deployment, [REQ-AOI-002] model provisioning, [REQ-AOI-003] content filtering, [REQ-AOI-004] LiteLLM integration
8. Per-agent judge: PASS -- Validates model responds to test prompts, content filter blocks harmful input, LiteLLM routes correctly to Azure endpoint with proper API version
9. Specific rules: PASS -- Enforces API version pinning (not latest), content filter with custom severity thresholds per category, TPM quota reservation matching expected load, managed identity for authentication, and LiteLLM model mapping with Azure-specific parameters
10. Failure escalation: PASS -- Escalates if GPT-4o not available in target region, TPM quota insufficient, content filter policy creation fails, or managed identity cannot access resource
11. /learn: PASS -- Records region-specific model availability, effective TPM allocation for production loads, content filter threshold tuning for false positive reduction
12. Anti-patterns: PASS -- 5 items: no API key authentication when managed identity available, no using "latest" API version, no default content filter without customization, no missing TPM quota planning, no hardcoded endpoint URLs
16. Confidence routing: PASS -- High for standard model deployment, medium for custom content filter tuning, low for PTU (provisioned throughput) capacity planning
17. Self-correction loop: PASS -- Re-provisions in alternate region if target region has no GPT-4o capacity; adjusts content filter thresholds if test shows excessive false positives
18. Negative instructions: PASS -- Never use API keys when managed identity is available, never use unpinned API versions, never deploy without content filtering, never skip TPM quota check
19. Tool failure handling: PASS -- Checks model availability before provisioning; retries deployment on transient ARM errors; validates LiteLLM config with health check before declaring success
20. Chaos resilience: PASS -- Handles region capacity exhaustion, API version deprecation, content filter service outage, LiteLLM proxy crash, and Azure ARM throttling

## Key Strengths
- Pins Azure OpenAI API version explicitly rather than using "latest", preventing breaking changes from silently affecting production
- Configures custom content filtering with per-category severity thresholds tuned to the use case, rather than relying on defaults
- Integrates with LiteLLM gateway including Azure-specific parameters (api_version, api_base) and health check validation

## Verdict: PERFECT (100%)
