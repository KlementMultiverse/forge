# Run 05: Voice agent architecture -- LiveKit vs Vapi vs Pipecat vs custom

## Research Topic
"Voice agent architecture -- LiveKit vs Vapi vs Pipecat vs custom"

## Research Performed
- WebSearch: "voice agent architecture LiveKit vs Vapi vs Pipecat comparison 2025 2026"
- WebFetch: Hamming AI voice agent stack selection framework (successful)

## Prompt Evaluation

### What the prompt guided well
1. **Multi-hop reasoning** -- Entity Expansion worked: Platform -> Architecture -> Components -> Use Cases
2. **Alternative comparison** -- Four platforms compared with clear differentiation
3. **Open-source examples** -- LiveKit and Pipecat both open-source, well documented
4. **Trend check** -- Captured the build-vs-buy migration pattern (50% of teams migrate off managed within 12 months)
5. **Self-reflection** -- Initial search gave overview; recognized need for deeper framework, leading to Hamming AI fetch

### What the prompt missed or was weak on
1. **No architecture diagram instruction** -- Voice agents have a clear pipeline (STT->LLM->TTS) that benefits from visual representation, but prompt doesn't push for it
2. **No latency budget breakdown** -- Voice AI has strict latency requirements (<500ms), but prompt doesn't instruct agent to break down latency per component
3. **No component-level comparison** -- Prompt focuses on platforms but real decision includes STT vendor (Deepgram vs AssemblyAI), TTS vendor (ElevenLabs vs Cartesia), etc.
4. **No cost-at-scale modeling** -- Found "80% cost savings" by building custom, but prompt doesn't push for actual cost calculations
5. **No quality evaluation framework** -- Voice quality metrics (WER, MOS, latency) should be part of comparison but prompt doesn't ask

### Research Quality Score: 9/10
- Sources found: 7 relevant, including comprehensive selection framework
- Alternatives compared: 4 platforms + component-level analysis
- Actionable recommendation: Yes -- clear build-vs-buy decision matrix with thresholds
- Key insight: "Half the teams migrate off managed platforms within 12 months" -- start managed, plan for custom

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: Voice AI stacks split into managed (Vapi/Retell: fast launch, higher cost) vs custom (LiveKit/Pipecat: full control, 80% cost savings at scale). Architecture decision between cascading (STT->LLM->TTS, 2-4s latency, auditable) and speech-to-speech (~500ms, opaque). 50% of teams migrate off managed within 12 months.
### Approach Recommended: Start with managed (Vapi) for validation (<10K min/mo), plan migration to LiveKit/Pipecat when exceeding 10-50K min/mo or needing compliance control.
### Alternatives Considered:
- LiveKit Agents: Open-source, video+voice, SFU-based WebRTC. Best for scale and compliance. Requires engineering investment.
- Vapi: Turnkey, telephony-focused, WebSocket transport. Fast launch (2hr), expensive at scale ($500-1300/10K min).
- Pipecat: Fully modular orchestration, Daily-backed, maximum component flexibility. More setup time for turn-taking.
- Retell: Most non-technical friendly (3hr setup). Adds latency overhead.
### Sources:
- https://hamming.ai/resources/best-voice-agent-stack
- https://modal.com/blog/livekit-vs-vapi-article
- https://softcery.com/lab/choosing-the-right-voice-agent-platform-in-2025
- https://www.assemblyai.com/blog/orchestration-tools-ai-voice-agents
### Delegation Hints: Next: @system-architect should define latency budget and compliance requirements before selecting platform.
### Risks/Unknowns: Voice quality is subjective and hard to benchmark. Managed platform pricing may change. WebRTC vs WebSocket trade-offs depend on network conditions.
### Insights for Playbook:
INSIGHT: 50% of teams migrate off managed voice platforms within 12 months once they hit scale or customization limits.
INSIGHT: Cascading architecture (STT->LLM->TTS) provides audit trails critical for regulated industries; speech-to-speech sacrifices auditability for latency.
INSIGHT: Deepgram Nova-3 leads STT at 6.84% WER with <300ms latency. ElevenLabs Flash leads TTS at 75ms.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No architecture diagram instruction | Medium | Add: "For system architecture topics, describe or diagram the component pipeline" |
| No latency budget breakdown | High | Add: "For real-time systems, break down latency budget per component" |
| No component-level comparison | Medium | Add: "Compare at component level, not just platform level" |
| No cost-at-scale modeling | Medium | Add: "Model costs at 3 scale levels (startup, growth, enterprise)" |
| No quality metrics framework | Medium | Add: "Define evaluation metrics relevant to the domain (WER for speech, MOS for quality, etc.)" |
