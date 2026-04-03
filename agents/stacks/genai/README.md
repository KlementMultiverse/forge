# GenAI Stack Agents

Agents for building AI-powered features in any application.

## Agents

| Agent | ONE Task | Key Technologies |
|---|---|---|
| @llm-integration-agent | LLM gateway + prompt management + cost control | LiteLLM, Jinja2, Redis caching, SSE streaming |
| @rag-architect | RAG pipeline design + implementation | Embeddings, pgvector/Qdrant, hybrid search, Cohere Rerank, RAGAS |
| @chatbot-builder | Conversational AI with memory + tools | LangGraph, Mem0, Redis, SSE, guardrails |
| @voice-agent-builder | Voice agent pipeline (STT→LLM→TTS) | Deepgram, ElevenLabs, LiveKit, WebSocket |
| @agent-orchestrator | Multi-agent system design | LangGraph, CrewAI, supervisor/swarm/pipeline topologies |
| @eval-engineer | LLM evaluation pipelines | DeepEval, RAGAS, promptfoo, LLM-as-judge, CI blocking |
| @ai-safety-agent | AI guardrails + safety | NeMo Guardrails, Guardrails AI, Presidio, injection defense |

## When to Use

PM orchestrator loads these agents when `/feasibility` detects AI/LLM requirements in the project spec.

## Created: 2026-04-02
