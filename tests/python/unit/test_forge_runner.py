"""Tests for scripts/forge-runner.py"""
import subprocess
import sys
from pathlib import Path

FORGE_DIR = Path(__file__).parent.parent.parent.parent
SCRIPT = FORGE_DIR / "scripts" / "forge-runner.py"


def test_script_exists():
    assert SCRIPT.exists()


def test_script_is_valid_python():
    result = subprocess.run(
        [sys.executable, "-c", f"import py_compile; py_compile.compile('{SCRIPT}', doraise=True)"],
        capture_output=True, text=True, timeout=10
    )
    assert result.returncode == 0


def test_script_has_forge_runner_class():
    content = SCRIPT.read_text()
    assert "class ForgeRunner" in content


def test_script_has_build_and_watch_commands():
    content = SCRIPT.read_text()
    assert "build" in content
    assert "watch" in content


def test_script_has_logging_functions():
    content = SCRIPT.read_text()
    assert "def log_builder" in content
    assert "def log_observer" in content
    assert "def log_needs_you" in content
