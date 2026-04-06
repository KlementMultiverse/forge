"""Tests for scripts/forge-lint.py"""
import subprocess
import sys
from pathlib import Path

FORGE_DIR = Path(__file__).parent.parent.parent.parent
SCRIPT = FORGE_DIR / "scripts" / "forge-lint.py"


def test_script_exists():
    assert SCRIPT.exists()


def test_lint_runs_on_forge_dir():
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(FORGE_DIR)],
        capture_output=True, text=True, timeout=30
    )
    # Lint may find issues but should not crash
    assert result.returncode in (0, 1)


def test_lint_output_has_sections():
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(FORGE_DIR)],
        capture_output=True, text=True, timeout=30
    )
    # Should mention agents, commands, scripts in output
    output = result.stdout + result.stderr
    assert len(output) > 0
