# Autoresearch: @rag-architect

## Research Sources
- RAG best practices 2026: https://www.blockchain-council.org/ai/production-ready-rag-pipeline-vector-databases-chunking-embeddings-retrieval-tuning/
- Hybrid search with reranking: https://www.dbi-services.com/blog/rag-series-hybrid-search-with-re-ranking/
- pgvector production: https://www.kalviumlabs.ai/blog/rag-in-production-what-works/
- RAG in 2026: https://aishwaryasrinivasan.substack.com/p/all-you-need-to-know-about-rag-in

## Run Results (5 Mental Simulations)

### Run 1: "Design RAG for 50K legal contracts with hybrid search"
**Result: PASS with gaps**
- Prompt correctly mandates hybrid search (BM25 + vector) with reranking
- Correctly insists on RAGAS evaluation before shipping
- GAP: No mention of context-aware/semantic chunking (using embedding cosine distance to detect thematic shifts) — prompt only lists fixed-size, semantic (sentence boundaries), hierarchical, document-specific
- GAP: No mention of late chunking or contextual embeddings (Anthropic's contextual retrieval pattern)
- GAP: No mention of parent-document retrieval pattern (chunk for retrieval, return full parent for context)

### Run 2: "Choose embedding model for multilingual medical documents"
**Result: PASS**
- Prompt lists relevant models: Cohere embed-v3 (multilingual), BGE-M3 (open source)
- Adequate guidance for model selection

### Run 3: "Implement chunking strategy for mixed PDF/HTML/Markdown content"
**Result: PASS with gaps**
- Prompt covers document-specific chunking (markdown headers, code blocks)
- Correctly warns about preprocessing (clean HTML, normalize whitespace)
- GAP: No mention of 20-25% overlap recommendation for chunk boundaries
- GAP: No mention of metadata enrichment during chunking (add section headers, document title as prefix to each chunk for better retrieval)
- GAP: No mention of chunk size validation — testing 256/512/1024 is mentioned in anti-patterns but not guidance on overlap

### Run 4: "Set up pgvector with hybrid search (BM25 + vector + reranking)"
**Result: PASS with minor gap**
- Prompt correctly covers pgvector, HNSW indexing, BM25 + vector with RRF fusion
- GAP: No mention of pgvector's practical limit (~2M vectors without performance degradation)
- GAP: No mention of PostgreSQL `tsvector` for BM25 implementation within Postgres (avoiding external search engine)

### Run 5: "Build evaluation pipeline for RAG quality (RAGAS metrics)"
**Result: PASS with gaps**
- Prompt covers RAGAS metrics (faithfulness, answer relevancy, context precision, context recall)
- GAP: No warning about RAGAS NaN scores when LLM judge returns invalid JSON — need try/except and pin version
- GAP: No mention of minimum golden dataset size (50 well-curated questions is sufficient for stable metrics)

## Gaps Found (to fix in prompt)

1. **HIGH**: Missing context-aware chunking (cosine distance thematic shift detection) — this is the 2026 state-of-the-art approach
2. **HIGH**: Missing contextual retrieval / late chunking pattern (prepend document context to chunks)
3. **HIGH**: Missing RAGAS NaN score warning and version pinning guidance
4. **MEDIUM**: Missing chunk overlap recommendation (20-25%)
5. **MEDIUM**: Missing pgvector practical limits (~2M vectors) and tsvector for native BM25
6. **MEDIUM**: Missing parent-document retrieval pattern
7. **LOW**: Missing minimum golden dataset size guidance (50 questions)
