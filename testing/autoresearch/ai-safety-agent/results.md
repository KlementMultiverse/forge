# Autoresearch: @ai-safety-agent

## Research Sources
- Prompt injection attacks 2026: https://www.getastra.com/blog/ai-security/prompt-injection-attacks/
- LLM guardrails setup guide 2026: https://aiworkflowlab.dev/article/llm-guardrails-production-defense-in-depth-safety-systems-nemo-guardrails-ai-openai
- OWASP LLM prompt injection cheat sheet: https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
- LLM security risks 2026: https://sombrainc.com/blog/llm-security-risks-2026
- Datadog LLM guardrails: https://www.datadoghq.com/blog/llm-guardrails-best-practices/

## Run Results (5 Mental Simulations)

### Run 1: "Implement prompt injection defense for customer-facing chatbot"
**Result: PASS with gaps**
- Prompt correctly mandates layered defense (input + system prompt + output)
- Covers canary tokens and instruction hierarchy
- GAP: No mention of OWASP Top 10 for LLM Applications as a reference framework — this is the industry standard for LLM security in 2026
- GAP: No mention of indirect prompt injection (via retrieved documents in RAG) as a distinct attack vector requiring separate defenses
- GAP: No mention of instruction hierarchy / privilege separation — transmitting system message, tool instructions, and user message over separate protected channels

### Run 2: "Add PII detection and redaction for medical AI assistant"
**Result: PASS**
- Prompt correctly references Microsoft Presidio with custom entity recognizers
- Mandates PII detection on both input AND output
- Covers audit logging for all safety events
- Adequate guidance

### Run 3: "Set up NeMo Guardrails for conversation topic control"
**Result: PASS with minor gap**
- Prompt covers NeMo Guardrails Colang for topic boundaries and refusal patterns
- GAP: No mention of alternative guardrail libraries (LLM Guard, Lakera, Llama Guard) as fallbacks or complements to NeMo — prompt is too NeMo-centric
- GAP: No mention of Guardrails AI (guardrails-ai library) for structured output validation as distinct from NeMo

### Run 4: "Audit existing LLM integration for output sanitization gaps"
**Result: PASS**
- Prompt covers strip_tags(), Pydantic schema validation, safety classifiers
- Correctly mandates sanitization before storage
- Adequate guidance

### Run 5: "Build red-team test suite for adversarial prompt testing"
**Result: PASS with gaps**
- Prompt covers injection attack tests and boundary violation tests
- GAP: No mention of systematic red-teaming frameworks or taxonomies (e.g., OWASP categories: direct injection, indirect injection, training data extraction, model denial of service)
- GAP: No mention of automated red-teaming tools (Garak, PyRIT) for scaling adversarial testing
- GAP: No mention of jailbreak taxonomy (DAN, role-play, encoding attacks, multi-turn manipulation) to guide test case creation

## Gaps Found (to fix in prompt)

1. **HIGH**: Missing OWASP Top 10 for LLM Applications reference — industry standard framework
2. **HIGH**: Missing indirect prompt injection as distinct attack vector (via RAG retrieved documents)
3. **HIGH**: Missing automated red-teaming tools (Garak, PyRIT) for adversarial testing at scale
4. **MEDIUM**: Missing instruction hierarchy / privilege separation pattern (separate channels for system vs user content)
5. **MEDIUM**: Missing jailbreak taxonomy for systematic test coverage
6. **MEDIUM**: Missing alternative guardrail libraries (LLM Guard, Lakera, Llama Guard) as options beyond NeMo
7. **LOW**: Missing Guardrails AI distinction from NeMo Guardrails (output schema validation vs conversation control)
