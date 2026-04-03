# Run 03: Best embedding models for legal document RAG in 2025

## Research Topic
"Best embedding models for legal document RAG in 2025"

## Research Performed
- WebSearch: "best embedding models legal document RAG 2025 2026 comparison benchmark"
- WebFetch: PremAI blog on best embedding models ranked by MTEB (successful)

## Prompt Evaluation

### What the prompt guided well
1. **Conceptual Deepening** -- Overview (MTEB leaderboard) -> Details (per-model scores) -> Examples (legal-specific benchmarks) -> Edge cases (MLEB showing different results than general benchmarks)
2. **Source credibility check** -- Cross-referenced MTEB scores from multiple sources, noted discrepancy with MLEB legal-specific benchmark
3. **Open-source examples** -- Found both proprietary (Gemini, Voyage) and self-hostable (Qwen3, BGE-M3) options
4. **Gotchas** -- Captured critical insight: "leaderboard performance doesn't correlate with legal-specific performance" due to data leakage

### What the prompt missed or was weak on
1. **No cost analysis instruction** -- Found pricing ($0.06-$0.10/1M tokens) but only because sources included it
2. **No deployment architecture guidance** -- Self-hosted vs API has major implications for legal data sovereignty, but prompt doesn't push for infrastructure comparison
3. **No instruction to check for domain-specific variants** -- Discovered voyage-law-2 exists, but prompt doesn't say "check for domain-specific model variants"
4. **No chunking strategy research** -- Embedding model choice is tightly coupled with chunking strategy, but prompt treats them independently
5. **No instruction to verify recency of benchmarks** -- MTEB scores change monthly; prompt doesn't push for "benchmark date" verification

### Research Quality Score: 8/10
- Sources found: 7 relevant including HuggingFace legal-specific benchmark
- Alternatives compared: 6 models (Gemini, Qwen3, NV-Embed, Voyage, Cohere, BGE-M3)
- Actionable recommendation: Yes -- Cohere embed-v4 for legal (128K context, handles full contracts)
- Key insight: Legal RAG Bench (MLEB) showed performance doesn't correlate with general MTEB scores

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: For legal document RAG, general MTEB leaderboard scores don't predict legal-specific performance. Cohere embed-v4 (128K context) handles full contracts without chunking. Voyage-law-2 is the purpose-built legal variant. For data sovereignty, Qwen3-Embedding-8B (Apache 2.0) is the strongest self-hostable option.
### Approach Recommended: Cohere embed-v4 for enterprise legal RAG (128K context, VPC deployment). Voyage-law-2 for cost-optimized legal search. Always run evaluation on your own corpus before committing.
### Alternatives Considered:
- Cohere embed-v4: 128K context, best for full legal documents, VPC option. $0.10/1M tokens.
- Voyage-law-2: Domain-specific legal model, 32K context. $0.06/1M tokens.
- Qwen3-Embedding-8B: Best self-hostable, Apache 2.0, multilingual. Requires GPU.
- Gemini embedding-001: Highest general MTEB score (68.32). Multi-modal.
- BGE-M3: Lightweight self-hostable, hybrid retrieval (dense+sparse).
### Sources:
- https://blog.premai.io/best-embedding-models-for-rag-2026-ranked-by-mteb-score-cost-and-self-hosting/
- https://huggingface.co/blog/isaacus/legal-rag-bench
- https://milvus.io/blog/choose-embedding-model-rag-2026.md
- https://zc277584121.github.io/rag/2026/03/20/embedding-models-benchmark-2026.html
### Delegation Hints: Next: @data-engineer should set up evaluation pipeline with domain-specific legal corpus before selecting final model.
### Risks/Unknowns: MTEB scores change monthly. Legal-specific benchmarks (MLEB) are still young. No benchmark covers all legal sub-domains equally.
### Insights for Playbook:
INSIGHT: General embedding benchmarks (MTEB) do NOT predict legal-domain performance -- always evaluate on your own corpus.
INSIGHT: Cohere embed-v4 has 128K token context -- eliminates chunking for most legal documents.
INSIGHT: Voyage has a domain-specific legal variant (voyage-law-2) that outperforms general-purpose models on legal text.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No cost/pricing comparison instruction | Medium | Add: "Compare pricing and infrastructure costs across alternatives" |
| No deployment architecture guidance | High | Add: "Assess deployment options: API vs self-hosted, data sovereignty implications" |
| No domain-specific variant check | Medium | Add: "Check for domain-specific model variants or fine-tuned versions" |
| No chunking strategy coupling | Medium | Add: "When researching embedding models, include chunking strategy implications" |
| No benchmark recency verification | Low | Add: "Note the date of any benchmarks cited -- scores change frequently" |
