# The 7 Prompting Techniques

Every agent prompt in Forge uses these techniques from CS146S.

## 1. Zero-Shot
Give instructions. No examples. Use when task is common and well-understood.

## 2. K-Shot (Few-Shot)
Provide k examples before the task. Quality > quantity. Three diverse examples beat ten similar ones.

## 3. Chain-of-Thought (CoT)
Tell the model to reason step by step. Each reasoning step becomes context for the next.
Even "Please think step by step" reliably improves accuracy.

## 4. RAG (Retrieval-Augmented Generation)
Before calling the LLM, fetch relevant documents and inject as context.
Reduces hallucination. Keeps model current. Provides explainability.
In Forge: context7 MCP fetches library docs before every implementation.

## 5. Self-Consistency
Run the same prompt multiple times. Take the majority answer.
Run in parallel (same wall-clock time, N× reliability).
Use for high-stakes reasoning, math, logic.

## 6. Reflexion
Model evaluates its own answer and revises. Generate → Critique → Revise.
ALWAYS bound the loop (max 3 iterations). Never while(true).
In Forge: max 3 retries per agent, then escalate.

## 7. Tool Calling
Give the model functions to call for real data/actions.
Without tools: hallucination. With tools: real results.
In Forge: context7, GitHub CLI, Docker, test runners.

## The 6 Prompt Best Practices

1. **Clarity test** — would someone with zero context understand?
2. **Role prompting** — describe the persona in system prompt
3. **XML tags** — structure with tags (Claude trained on XML)
4. **Be explicit** — one extra sentence prevents wrong assumptions
5. **Prompts are code** — version control, iterate, test
6. **Decompose** — break complex into focused sub-tasks
