# Forge Agent Full System Verification Report

**Date:** 2026-04-02
**Scope:** All 49 agent files across 6 directories
**Checks:** 12 quality gates per agent (588 total checks)

---

## Per-Agent Results

### azure-openai-agent
**File:** `stacks/azure/azure-openai-agent.md` | **Lines:** 309 | **Result:** 9/12 — 3 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (309 lines)

---

### azure-setup-agent
**File:** `stacks/azure/azure-setup-agent.md` | **Lines:** 302 | **Result:** 10/12 — 2 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (302 lines)

---

### django-ninja-agent
**File:** `stacks/django/django-ninja-agent.md` | **Lines:** 185 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (185 lines)

---

### django-tenants-agent
**File:** `stacks/django/django-tenants-agent.md` | **Lines:** 155 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (155 lines)

---

### s3-lambda-agent
**File:** `stacks/django/s3-lambda-agent.md` | **Lines:** 168 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (168 lines)

---

### gcp-setup-agent
**File:** `stacks/gcp/gcp-setup-agent.md` | **Lines:** 272 | **Result:** 9/12 — 3 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (272 lines)

---

### vertex-ai-agent
**File:** `stacks/gcp/vertex-ai-agent.md` | **Lines:** 238 | **Result:** 9/12 — 3 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (238 lines)

---

### agent-orchestrator
**File:** `stacks/genai/agent-orchestrator.md` | **Lines:** 171 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (171 lines)

---

### ai-safety-agent
**File:** `stacks/genai/ai-safety-agent.md` | **Lines:** 172 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (172 lines)

---

### chatbot-builder
**File:** `stacks/genai/chatbot-builder.md` | **Lines:** 169 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (169 lines)

---

### eval-engineer
**File:** `stacks/genai/eval-engineer.md` | **Lines:** 170 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (170 lines)

---

### llm-integration-agent
**File:** `stacks/genai/llm-integration-agent.md` | **Lines:** 168 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (168 lines)

---

### rag-architect
**File:** `stacks/genai/rag-architect.md` | **Lines:** 168 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (168 lines)

---

### voice-agent-builder
**File:** `stacks/genai/voice-agent-builder.md` | **Lines:** 172 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (172 lines)

---

### langchain-agent
**File:** `stacks/langchain/langchain-agent.md` | **Lines:** 291 | **Result:** 9/12 — 3 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (291 lines)

---

### langgraph-agent
**File:** `stacks/langchain/langgraph-agent.md` | **Lines:** 284 | **Result:** 9/12 — 3 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (284 lines)

---

### langsmith-agent
**File:** `stacks/langchain/langsmith-agent.md` | **Lines:** 323 | **Result:** 9/12 — 3 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (323 lines)

---

### agent-factory
**File:** `universal/agent-factory.md` | **Lines:** 182 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): **FAIL**
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (182 lines)

---

### api-architect
**File:** `universal/api-architect.md` | **Lines:** 149 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): **FAIL**
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (149 lines)

---

### aws-setup-agent
**File:** `universal/aws-setup-agent.md` | **Lines:** 289 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (289 lines)

---

### backend-architect
**File:** `universal/backend-architect.md` | **Lines:** 139 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (139 lines)

---

### business-panel-experts
**File:** `universal/business-panel-experts.md` | **Lines:** 317 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (317 lines)

---

### code-archaeologist
**File:** `universal/code-archaeologist.md` | **Lines:** 163 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): **FAIL**
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (163 lines)

---

### context-loader-agent
**File:** `universal/context-loader-agent.md` | **Lines:** 166 | **Result:** 8/12 — 4 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: **FAIL**
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: **FAIL**
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (166 lines)

---

### deep-researcher
**File:** `universal/deep-researcher.md` | **Lines:** 264 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (264 lines)

---

### devops-architect
**File:** `universal/devops-architect.md` | **Lines:** 123 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (123 lines)

---

### frontend-architect
**File:** `universal/frontend-architect.md` | **Lines:** 140 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (140 lines)

---

### learning-guide
**File:** `universal/learning-guide.md` | **Lines:** 118 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (118 lines)

---

### mcp-architect
**File:** `universal/mcp-architect.md` | **Lines:** 350 | **Result:** 9/12 — 3 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (350 lines)

---

### pattern-auditor-agent
**File:** `universal/pattern-auditor-agent.md` | **Lines:** 865 | **Result:** 7/12 — 5 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: **FAIL**
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: **FAIL**
  9. <system-reminder> tag: PASS
  10. /learn mentioned: **FAIL**
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (865 lines)

---

### performance-engineer
**File:** `universal/performance-engineer.md` | **Lines:** 125 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (125 lines)

---

### playbook-curator
**File:** `universal/playbook-curator.md` | **Lines:** 129 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): **FAIL**
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (129 lines)

---

### playwright-critic
**File:** `universal/playwright-critic.md` | **Lines:** 141 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): **FAIL**
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (141 lines)

---

### pm-orchestrator
**File:** `universal/pm-orchestrator.md` | **Lines:** 349 | **Result:** 9/12 — 3 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): PASS
  8. Forge Integration section: **FAIL**
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (349 lines)

---

### python-expert
**File:** `universal/python-expert.md` | **Lines:** 139 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (139 lines)

---

### quality-engineer
**File:** `universal/quality-engineer.md` | **Lines:** 122 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (122 lines)

---

### refactoring-expert
**File:** `universal/refactoring-expert.md` | **Lines:** 123 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (123 lines)

---

### repo-index
**File:** `universal/repo-index.md` | **Lines:** 101 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (101 lines)

---

### requirements-analyst
**File:** `universal/requirements-analyst.md` | **Lines:** 121 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (121 lines)

---

### retrospective-miner
**File:** `universal/retrospective-miner.md` | **Lines:** 130 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): **FAIL**
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (130 lines)

---

### reviewer
**File:** `universal/reviewer.md` | **Lines:** 156 | **Result:** 7/12 — 5 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: **FAIL**
  6. Handoff Protocol: **FAIL**
  7. Frontmatter (---): **FAIL**
  8. Forge Integration section: **FAIL**
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: **FAIL**
  12. 80+ lines: PASS (156 lines)

---

### root-cause-analyst
**File:** `universal/root-cause-analyst.md` | **Lines:** 124 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (124 lines)

---

### sdlc-enforcer
**File:** `universal/sdlc-enforcer.md` | **Lines:** 136 | **Result:** 11/12 — 1 FAILING

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): **FAIL**
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (136 lines)

---

### security-engineer
**File:** `universal/security-engineer.md` | **Lines:** 126 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (126 lines)

---

### self-review
**File:** `universal/self-review.md` | **Lines:** 107 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (107 lines)

---

### socratic-mentor
**File:** `universal/socratic-mentor.md` | **Lines:** 362 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (362 lines)

---

### system-architect
**File:** `universal/system-architect.md` | **Lines:** 120 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (120 lines)

---

### technical-writer
**File:** `universal/technical-writer.md` | **Lines:** 119 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (119 lines)

---

### tools-architect
**File:** `universal/tools-architect.md` | **Lines:** 120 | **Result:** ALL PASS (12/12)

  1. Confidence Routing: PASS
  2. Self-Correction Loop: PASS
  3. Tool Failure Handling: PASS
  4. Chaos Resilience: PASS
  5. Anti-Patterns: PASS
  6. Handoff Protocol: PASS
  7. Frontmatter (---): PASS
  8. Forge Integration section: PASS
  9. <system-reminder> tag: PASS
  10. /learn mentioned: PASS
  11. Failure Escalation: PASS
  12. 80+ lines: PASS (120 lines)

---


## Summary

- **Total agents scanned:** 49
- **Fully passing (12/12):** 28
- **With failures:** 21
- **Overall pass rate:** 57%

### Check Failure Breakdown

| # | Check | Agents Failing |
|---|---|---|
| 1 | Confidence Routing | 0 |
| 2 | Self-Correction Loop | 0 |
| 3 | Tool Failure Handling | 0 |
| 4 | Chaos Resilience | 0 |
| 5 | Anti-Patterns | 3 |
| 6 | Handoff Protocol | 14 |
| 7 | Frontmatter (---) | 8 |
| 8 | Forge Integration section | 4 |
| 9 | <system-reminder> tag | 0 |
| 10 | /learn mentioned | 9 |
| 11 | Failure Escalation | 11 |
| 12 | 80+ lines | 0 |

### Agents With Failures

| Agent File | Score | Failures |
|---|---|---|
| stacks/azure/azure-openai-agent.md | 9/12 | 3 |
| stacks/azure/azure-setup-agent.md | 10/12 | 2 |
| stacks/django/django-tenants-agent.md | 11/12 | 1 |
| stacks/django/s3-lambda-agent.md | 11/12 | 1 |
| stacks/gcp/gcp-setup-agent.md | 9/12 | 3 |
| stacks/gcp/vertex-ai-agent.md | 9/12 | 3 |
| stacks/langchain/langchain-agent.md | 9/12 | 3 |
| stacks/langchain/langgraph-agent.md | 9/12 | 3 |
| stacks/langchain/langsmith-agent.md | 9/12 | 3 |
| universal/agent-factory.md | 11/12 | 1 |
| universal/api-architect.md | 11/12 | 1 |
| universal/code-archaeologist.md | 11/12 | 1 |
| universal/context-loader-agent.md | 8/12 | 4 |
| universal/mcp-architect.md | 9/12 | 3 |
| universal/pattern-auditor-agent.md | 7/12 | 5 |
| universal/playbook-curator.md | 11/12 | 1 |
| universal/playwright-critic.md | 11/12 | 1 |
| universal/pm-orchestrator.md | 9/12 | 3 |
| universal/retrospective-miner.md | 11/12 | 1 |
| universal/reviewer.md | 7/12 | 5 |
| universal/sdlc-enforcer.md | 11/12 | 1 |

