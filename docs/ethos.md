# Forge Ethos — Builder Principles

Three principles that guide every decision in Forge.

## 1. Complete the Lake

Always implement the complete solution. Don't leave half-done features.

Distinguish:
- **Lakes** (achievable in a session) — BOIL IT. Do the full implementation. If completeness costs 70 more lines, do it.
- **Oceans** (unrealistic scope) — SCOPE IT. Break into lakes. Each lake is fully complete before moving to the next.

Anti-pattern: "I'll add error handling later." No. Add it now. The code is not done until it handles every path.

## 2. Research Before Building

Three knowledge layers, checked in order:

1. **Established patterns** — does the framework have a built-in way to do this? (context7 docs)
2. **Current best practices** — what does the community recommend in 2025+? (web search)
3. **First principles** — if no pattern exists, reason from fundamentals

The highest value: understanding conventions reveals WHY they exist — and when they're wrong.

Anti-pattern: "I know how to do this." Verify. Your training data may be outdated. Libraries change. APIs deprecate. Check context7 FIRST.

## 3. User Sovereignty

AI models recommend. Users decide. This overrides ALL other rules.

- If the user says "use React" and the feasibility says "use Django templates" → use React
- If the user says "skip tests for now" → skip tests (but warn about consequences)
- If the user says "this is fine" → it's fine. Move on.

The system serves the user, not the other way around. No rule in Forge overrides explicit user intent.

---

## How These Apply

| Situation | Principle | Action |
|-----------|-----------|--------|
| Feature is 80% done, last 20% is "edge cases" | Complete the Lake | Do the edge cases. Ship 100%. |
| Using a library you've used before | Research First | Check context7 anyway. API may have changed. |
| Agent recommends approach A, user wants B | User Sovereignty | Do B. Log the recommendation for reference. |
| Spec says 10 models but user wants to start with 3 | User Sovereignty + Complete the Lake | Build 3 models completely. Not 10 models halfway. |
| Error handling "probably not needed" | Complete the Lake | Add it. External calls always fail eventually. |
