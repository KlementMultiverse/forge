# Autoresearch: @eval-engineer

## Research Sources
- DeepEval RAG evaluation: https://deepeval.com/guides/guides-rag-evaluation
- Best LLM eval tools 2026: https://medium.com/online-inference/the-best-llm-evaluation-tools-of-2026-40fd9b654dce
- RAG evaluation 2026: https://blog.premai.io/rag-evaluation-metrics-frameworks-testing-2026/
- Best RAG eval tools 2026: https://www.getmaxim.ai/articles/the-5-best-rag-evaluation-tools-you-should-know-in-2026/

## Run Results (5 Mental Simulations)

### Run 1: "Set up DeepEval test suite for RAG chatbot"
**Result: PASS**
- Prompt correctly references DeepEval with pytest integration
- Covers golden dataset creation and versioning
- Adequate guidance

### Run 2: "Create CI-blocking eval pipeline with golden test datasets"
**Result: PASS with gaps**
- Prompt covers CI gate blocking merges on quality regression
- GAP: No mention of dataset stratification by difficulty AND by feature area — prompt says "stratified by difficulty" but production needs both
- GAP: No mention of running reduced dataset in CI (stratified sample) with full eval nightly — wait, this IS in Chaos Resilience. OK.
- GAP: No mention of traceability — linking eval scores to exact prompt version + model version + dataset version (the 2026 best practice)

### Run 3: "Implement LLM-as-judge for subjective quality scoring"
**Result: PASS with gaps**
- Prompt covers judge prompts with scoring rubrics, calibration against 50+ human labels
- Correctly warns about uncalibrated judges (20-40% disagreement)
- GAP: No mention of chain-of-thought in judge prompts for better calibration — wait, this IS mentioned in Chaos Resilience ("add chain-of-thought to rubric"). OK.
- GAP: No mention of position bias in LLM judges (tendency to prefer first/last option) — need randomized option ordering
- GAP: No mention of using multiple judge models and taking consensus for high-stakes evaluations

### Run 4: "Build online production monitoring for quality drift"
**Result: PASS with minor gap**
- Prompt covers production sampling (5-10%), drift detection, alert thresholds
- GAP: No mention of specific monitoring tools (LangSmith, LangFuse, TruLens) — prompt says "Quality dashboards" but no concrete tool recommendations
- GAP: No mention of the three-layer eval architecture (unit/development, batch/staging, production/monitoring)

### Run 5: "Create A/B testing framework for prompt versions"
**Result: PASS with minor gap**
- Prompt covers p<0.05 statistical significance requirement
- Mentions A/B prompt comparison
- GAP: No mention of required sample size estimation before running A/B tests
- GAP: No mention of sequential testing / early stopping for prompt A/B tests

## Gaps Found (to fix in prompt)

1. **HIGH**: Missing traceability guidance — linking eval scores to exact prompt + model + dataset versions
2. **HIGH**: Missing RAGAS NaN score warning (invalid JSON from LLM judge) — need try/except + version pinning
3. **MEDIUM**: Missing position bias warning for LLM-as-judge (randomize option order)
4. **MEDIUM**: Missing multi-judge consensus pattern for high-stakes evaluations
5. **MEDIUM**: Missing three-layer eval architecture (unit → batch → production)
6. **MEDIUM**: Missing specific monitoring tool recommendations (LangFuse, LangSmith, TruLens)
7. **LOW**: Missing sample size estimation for A/B tests
