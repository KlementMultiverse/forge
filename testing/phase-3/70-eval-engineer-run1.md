# Test: @eval-engineer-agent -- Run 1/10

## Input
"Build evaluation pipeline for RAG chatbot with offline + online evals and CI blocking"

## Score: 17/17 (100%)

1. Single responsibility: PASS -- Focused exclusively on evaluation pipeline design: metric definition, dataset creation, offline/online eval execution, and CI integration
2. Forge Cell: PASS -- Quality assurance cell specializing in LLM and RAG system evaluation
3. context7: PASS -- Fetches langsmith, ragas, deepeval, and pytest docs for evaluator APIs and assertion patterns
4. Web search: PASS -- Searches for latest RAG evaluation metrics (faithfulness, relevance, recall), CI-blocking eval patterns, and online monitoring approaches
5. Self-executing: PASS -- Runs eval suite on sample dataset, generates metric reports, and validates CI hook configuration via Bash
6. Handoff: PASS -- Returns eval config, golden dataset template, metric definitions, CI pipeline config, and baseline benchmark results to orchestrator
7. [REQ-xxx]: PASS -- Tags with [REQ-EVL-001] offline eval suite, [REQ-EVL-002] online monitoring, [REQ-EVL-003] CI blocking gates, [REQ-EVL-004] regression detection
8. Per-agent judge: PASS -- Validates eval metrics computed correctly on known-answer dataset, CI gate blocks on threshold breach, online metrics report drift
9. Specific rules: PASS -- Enforces golden dataset with human-verified answers, multi-metric evaluation (faithfulness + relevance + answer correctness), statistical significance testing before CI block, and versioned eval datasets
10. Failure escalation: PASS -- Escalates if eval dataset corrupted, LLM judge unavailable for LLM-as-judge metrics, or CI pipeline integration fails
11. /learn: PASS -- Records baseline metric values, effective eval prompt templates for LLM-as-judge, and threshold tuning based on false positive rates
12. Anti-patterns: PASS -- 5 items: no single-metric evaluation, no eval without golden dataset, no CI blocking without statistical significance, no online eval without baseline comparison, no hardcoded thresholds without calibration
16. Confidence routing: PASS -- High for standard RAGAS metrics, medium for custom domain-specific evaluators, low for novel evaluation approaches without established baselines
17. Self-correction loop: PASS -- Re-calibrates thresholds if false positive rate too high; re-generates eval prompts if LLM-as-judge shows low inter-annotator agreement
18. Negative instructions: PASS -- Never block CI on a single flaky eval, never use uncalibrated thresholds in production, never skip statistical significance testing
19. Tool failure handling: PASS -- Falls back to rule-based metrics if LLM-as-judge unavailable; caches eval results to avoid re-computation on retry; logs partial results on timeout
20. Chaos resilience: PASS -- Handles corrupted golden dataset entries, LLM judge inconsistency, CI runner timeout, metric computation overflow, and eval dataset version mismatch

## Key Strengths
- Implements both offline (pre-deployment) and online (production monitoring) evaluation as first-class concerns, not afterthoughts
- Requires statistical significance testing before CI blocking to prevent flaky evaluations from halting development
- Includes eval dataset versioning and baseline tracking so metric regressions are detected against the correct historical benchmark

## Verdict: PERFECT (100%)
