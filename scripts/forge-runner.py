#!/usr/bin/env python3
"""
Forge Runner — One terminal. Builder runs automatically. You watch and intervene only when needed.

Usage:
  forge-runner.py build ~/projects/my-app     — build a project
  forge-runner.py build .                      — build current directory
  forge-runner.py watch ~/projects/my-app      — just watch an active build

What happens:
  1. Asks you about the project (Q1-Q7) if new
  2. Starts builder via Claude Agent SDK (headless)
  3. Streams ALL builder output to your screen
  4. Auto-answers routine questions (continue? yes. which agent? from routing.)
  5. Shows [NEEDS YOU] when it genuinely needs human input
  6. You type your answer, it goes to builder
  7. Build continues
"""

import asyncio
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

# Colors
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
DIM = "\033[2m"
BOLD = "\033[1m"
NC = "\033[0m"


def log_builder(msg: str) -> None:
    print(f"{DIM}[BUILDER]{NC} {msg}")


def log_observer(msg: str) -> None:
    print(f"{CYAN}[OBSERVER]{NC} {msg}")


def log_auto(msg: str) -> None:
    print(f"{GREEN}[AUTO-ANSWER]{NC} {msg}")


def log_needs_you(msg: str) -> None:
    print(f"\n{RED}{BOLD}[NEEDS YOU]{NC} {msg}")


def log_status(msg: str) -> None:
    print(f"{YELLOW}[STATUS]{NC} {msg}")


class ForgeRunner:
    def __init__(self, project_path: str):
        self.project_path = os.path.abspath(project_path)
        self.context: dict = {}
        self.context_file = os.path.expanduser("~/.forge-bridge/project-context.json")
        self.message_count = 0
        self.phase = 0
        self.step = 0
        self.auto_answers = 0
        self.human_answers = 0

    def detect_question(self, text: str) -> str | None:
        """Detect if builder output is a question that needs answering."""
        text_lower = text.lower().strip()

        # Phase continuation — always auto-answer
        if any(p in text_lower for p in [
            "should i continue",
            "shall i proceed",
            "continue to phase",
            "proceed to phase",
            "ready to proceed",
            "move to phase",
            "want me to continue",
        ]):
            return "auto:continue"

        # Agent routing — always auto-answer
        if any(p in text_lower for p in [
            "which agent",
            "what agent should",
            "should i use @",
        ]):
            return "auto:routing"

        # Confirmation prompts — auto-answer yes
        if text_lower.endswith("(yes/change)") or text_lower.endswith("correct?"):
            return "auto:confirm"
        if re.search(r"\(a\).*\(b\).*\(c\)", text_lower):
            return "needs_human"
        if text_lower.endswith("?") and len(text_lower) < 200:
            # Short question — might need human
            # But check if it's a routine one first
            if any(p in text_lower for p in [
                "sound right",
                "confirm",
                "look correct",
                "agree",
            ]):
                return "auto:confirm"
            return "needs_human"

        return None

    def get_auto_answer(self, question_type: str, text: str) -> str:
        """Generate automatic answer for routine questions."""
        if question_type == "auto:continue":
            return "Yes, continue. Do not stop between phases."
        elif question_type == "auto:routing":
            return "Use the agent from .claude/rules/agent-routing.md. Do not ask."
        elif question_type == "auto:confirm":
            return "Yes, confirmed. Continue."
        return ""

    def extract_progress(self, text: str) -> None:
        """Extract phase/step progress from builder output."""
        phase_match = re.search(r"Phase (\d+)", text)
        step_match = re.search(r"Step (\d+)", text)
        if phase_match:
            self.phase = int(phase_match.group(1))
        if step_match:
            self.step = int(step_match.group(1))

    async def gather_context(self) -> dict:
        """Ask user about the project (only for new projects)."""
        print(f"\n{BOLD}=== Forge Runner — Project Setup ==={NC}\n")

        # Check if context already exists
        if os.path.exists(self.context_file):
            with open(self.context_file) as f:
                existing = json.load(f)
            if existing.get("project_path") == self.project_path and existing.get("confirmed"):
                log_observer(f"Using saved context for {existing.get('project', '?')}")
                self.context = existing
                return existing

        # Check if project already has CLAUDE.md with real content
        claude_md = os.path.join(self.project_path, "CLAUDE.md")
        if os.path.exists(claude_md):
            content = open(claude_md).read()
            if "{{" not in content and len(content) > 100:
                log_observer("Project has CLAUDE.md — skipping discovery.")
                self.context = {"project_path": self.project_path, "confirmed": True, "existing": True}
                return self.context

        # New project — ask user
        questions = [
            ("project", "What are you building? (name + description)"),
            ("users", "Who uses it?"),
            ("problem", "What problem does it solve?"),
            ("stack", "Tech stack? (e.g., Django, FastAPI, Next.js)"),
            ("features", "Key features? (comma separated)"),
            ("excluded", "What should it NEVER include? (comma separated)"),
        ]

        context = {"project_path": self.project_path}
        for key, question in questions:
            answer = input(f"\n  {question}\n  > ")
            context[key] = answer.strip()

        print(f"\n{BOLD}Summary:{NC}")
        for k, v in context.items():
            if k != "project_path":
                print(f"  {k}: {v}")

        confirm = input(f"\n  Correct? (yes/change): ")
        if confirm.lower().startswith("y"):
            context["confirmed"] = True
            os.makedirs(os.path.dirname(self.context_file), exist_ok=True)
            with open(self.context_file, "w") as f:
                json.dump(context, f, indent=2)
            self.context = context
            return context
        else:
            return await self.gather_context()

    def build_forge_prompt(self) -> str:
        """Build the /forge prompt with pre-loaded context."""
        if self.context.get("existing"):
            return "/forge"

        ctx = self.context
        return f"""/forge

Pre-loaded project context (DO NOT ask these questions again):
PROJECT: {ctx.get('project', '')}
USERS: {ctx.get('users', '')}
PROBLEM: {ctx.get('problem', '')}
STACK: {ctx.get('stack', '')}
FEATURES: {ctx.get('features', '')}
EXCLUDED: {ctx.get('excluded', '')}
CONFIRMED: yes

Skip Q1-Q7. Go directly to STEP S3 (generate CLAUDE.md) with these answers.
After Phase A setup, continue immediately to Phase B.
Between ALL phases: continue automatically. Do NOT stop to ask.
"""

    async def run_build(self) -> None:
        """Run the forge build via SDK."""
        try:
            from claude_agent_sdk import query, ClaudeAgentOptions
        except ImportError:
            print(f"{RED}ERROR: claude-agent-sdk not installed. Run: pip install claude-agent-sdk{NC}")
            sys.exit(1)

        prompt = self.build_forge_prompt()

        log_status(f"Starting build in {self.project_path}")
        log_status("Builder output streams below. Auto-answering routine questions.")
        log_status("If [NEEDS YOU] appears, type your answer.\n")
        print("=" * 60)

        pending_question = None

        async for message in query(
            prompt=prompt,
            options=ClaudeAgentOptions(
                cwd=self.project_path,
                permission_mode="bypassPermissions",
                max_turns=500,
                max_budget_usd=50.0,
            ),
        ):
            self.message_count += 1

            # Extract text content
            content = ""
            if hasattr(message, "content"):
                if isinstance(message.content, str):
                    content = message.content
                elif isinstance(message.content, list):
                    for block in message.content:
                        if hasattr(block, "text"):
                            content += block.text

            if not content:
                continue

            # Track progress
            self.extract_progress(content)

            # Show builder output
            for line in content.split("\n"):
                if line.strip():
                    log_builder(line)

            # Check if it's a question
            q_type = self.detect_question(content)
            if q_type and q_type.startswith("auto:"):
                answer = self.get_auto_answer(q_type, content)
                log_auto(answer)
                self.auto_answers += 1
            elif q_type == "needs_human":
                log_needs_you(content[-300:])
                log_needs_you("Type your answer (or 'skip' to let builder decide):")
                try:
                    user_input = await asyncio.wait_for(
                        asyncio.get_event_loop().run_in_executor(None, input, f"  {GREEN}>{NC} "),
                        timeout=300,
                    )
                    if user_input.strip().lower() == "skip":
                        log_auto("Skipping — builder will decide.")
                    else:
                        self.human_answers += 1
                except asyncio.TimeoutError:
                    log_auto("No response in 5 min — builder will decide.")

        # Build complete
        print("\n" + "=" * 60)
        log_status("Build complete!")
        log_status(f"Messages: {self.message_count}")
        log_status(f"Auto-answered: {self.auto_answers}")
        log_status(f"Human answers: {self.human_answers}")
        log_status(f"Final phase: {self.phase}, step: {self.step}")

        # Check final state
        state_file = os.path.join(self.project_path, "docs/forge-state.json")
        if os.path.exists(state_file):
            with open(state_file) as f:
                state = json.load(f)
            log_status(f"Status: {state.get('status', '?')}")
            log_status(f"Gates: {sum(1 for p in state.get('phases', {}).values() if p.get('gate_passed'))}/{len(state.get('phases', {}))}")


async def main():
    if len(sys.argv) < 2:
        print(f"""
{BOLD}Forge Runner{NC} — automated builds with observer

Usage:
  forge-runner.py build <project-path>   Build a project
  forge-runner.py build .                Build in current directory

The runner:
  1. Asks you about the project (once)
  2. Runs the full forge build automatically
  3. Auto-answers routine questions
  4. Shows [NEEDS YOU] only when genuinely stuck
  5. You can walk away — it runs unattended
""")
        sys.exit(0)

    command = sys.argv[1]
    project_path = sys.argv[2] if len(sys.argv) > 2 else "."

    if command == "build":
        runner = ForgeRunner(project_path)
        await runner.gather_context()
        await runner.run_build()
    elif command == "watch":
        # Watch mode — just read state files and report
        project_path = os.path.abspath(project_path)
        state_file = os.path.join(project_path, "docs/forge-state.json")
        if os.path.exists(state_file):
            with open(state_file) as f:
                state = json.load(f)
            print(json.dumps(state, indent=2))
        else:
            print(f"No forge-state.json found at {project_path}")
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
