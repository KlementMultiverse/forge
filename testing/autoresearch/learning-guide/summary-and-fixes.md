# Learning Guide Agent: Autoresearch Summary (10 Runs)

## Aggregate Evaluation

| Criterion | Pass Rate | Notes |
|---|---|---|
| Anchor to existing knowledge | 8/10 | Failed when audience context was vague (runs 5, 10) |
| Progressive disclosure | 10/10 | Naturally layered in every run |
| Practical examples (real code) | 10/10 | Used actual repo code every time |
| Multiple explanation approaches | 8/10 | Runs 1-2 lacked visual/diagram approaches |
| Verify understanding (exercises) | 0/10 | NEVER produced exercises unless manually prompted |
| Named patterns/sources | 3/10 | Rarely cited pattern origins (Fowler, etc.) |
| Failure mode demonstration | 3/10 | Only runs 4, 8, 9 showed "what goes wrong" |
| Transferable principle | 3/10 | Only runs 8, 10 ended with generalizable rules |

## Prompt Gaps Identified (Consolidated, Deduplicated)

### GAP 1: No "Bridge From Known Framework" Instruction (Critical)
- **Seen in**: Runs 1, 2, 3, 5, 6, 7
- **Problem**: The prompt says "assess knowledge level" but doesn't instruct: "start every explanation by connecting to something the learner already knows"
- **Fix**: Add to Key Actions: "Always begin by identifying what the learner already knows (their framework, language, or mental model) and explicitly bridge from that to the new concept"

### GAP 2: No Mandatory Exercises/Self-Check (Critical)
- **Seen in**: ALL 10 runs
- **Problem**: Focus Areas mention "Understanding Verification" but Key Actions don't require it in output
- **Fix**: Add to Key Actions: "Every teaching output MUST end with 2-3 self-check questions or a hands-on exercise the learner can try"

### GAP 3: No "Show the Failure Mode" Instruction (High)
- **Seen in**: Runs 1, 2, 3, 5, 6, 7, 10
- **Problem**: Showing what goes wrong without the pattern is one of the most effective teaching techniques, but it's not in the prompt
- **Fix**: Add to Key Actions: "Before explaining a pattern or design choice, show what goes wrong without it (the naive approach, the error case, the performance problem)"

### GAP 4: No "Compare With Learner's Tool" Instruction (High)
- **Seen in**: Runs 2, 5, 7, 9
- **Problem**: When teaching a new tool, a comparison table with the learner's existing tool for the same problem is invaluable but not mandated
- **Fix**: Add to Key Actions: "When teaching a pattern that exists in the learner's current stack, include a comparison table showing the equivalent in their framework"

### GAP 5: No "Transferable Principle" Instruction (Medium)
- **Seen in**: Runs 1-7, 9
- **Problem**: Most explanations ended with the specific example but didn't extract a generalizable rule
- **Fix**: Add to Outputs: "Every explanation must end with a 'Takeaway Principle' — a 1-2 sentence transferable insight the learner can apply beyond this specific example"

### GAP 6: No "Cite Pattern Origins" Instruction (Medium)
- **Seen in**: Run 7 (Unit of Work), Run 9 (DataLoader)
- **Problem**: Named patterns have canonical sources (Fowler, Gang of Four, etc.) that help learners find more depth
- **Fix**: Add to Key Actions: "When teaching a named design pattern, cite the origin (e.g., 'Unit of Work — Martin Fowler, Patterns of Enterprise Application Architecture') and link to further reading"

### GAP 7: No "Version Migration Context" Instruction (Low)
- **Seen in**: Run 6 (Pydantic v2)
- **Problem**: When explaining a versioned technology, learners coming from the previous version need a translation table
- **Fix**: Add to Chaos Resilience: "If the learner mentions a specific version or the technology has had a major version change, include a v1→v2 migration cheat sheet"

### GAP 8: No "Include Runnable Commands" Instruction (Low)
- **Seen in**: Run 10
- **Problem**: Learners retain better when they can observe patterns firsthand
- **Fix**: Add to Key Actions: "When possible, include a command the learner can run to observe the pattern in their own terminal"

## Recommended Prompt Patch

Add to **Key Actions** section (after existing item 5):

```
6. **Bridge From Known**: Start every explanation by connecting to the learner's existing knowledge (framework, language, mental model). Use comparison tables for equivalent patterns.
7. **Show the Broken Version**: Before explaining a pattern, demonstrate what goes wrong without it — the naive approach, the error, the performance problem.
8. **Verify With Exercises**: End every teaching output with 2-3 self-check questions or a hands-on exercise.
9. **Extract Transferable Principles**: End with a 1-2 sentence "Takeaway" the learner can apply beyond this specific example.
10. **Cite and Link**: For named patterns, cite the origin and provide further reading links.
```

Add to **Outputs** section:
```
- **Self-Check Questions**: 2-3 questions or exercises per teaching output to verify comprehension
- **Comparison Tables**: Framework-to-framework comparison when teaching cross-stack concepts
```
