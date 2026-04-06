"""Tests for scripts/req-impact-check.py"""
import subprocess
import sys
from pathlib import Path

FORGE_DIR = Path(__file__).parent.parent.parent.parent
SCRIPT = FORGE_DIR / "scripts" / "req-impact-check.py"


def test_script_exists():
    assert SCRIPT.exists()


def test_help_shows_usage():
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        capture_output=True, text=True, timeout=10
    )
    # Should exit 1 with usage (invalid args)
    assert result.returncode == 1
    assert "Usage" in result.stdout


def test_check_nonexistent_file():
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "--check", "/nonexistent/file.py"],
        capture_output=True, text=True, timeout=10
    )
    assert result.returncode == 1
    assert "not found" in result.stdout


def test_check_file_with_req_tags(tmp_path):
    test_file = tmp_path / "test.py"
    test_file.write_text("# REQ-AUTH-001 User model\nclass User: pass\n")
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "--check", str(test_file)],
        capture_output=True, text=True, timeout=10
    )
    assert result.returncode == 0
    assert "REQ-AUTH-001" in result.stdout


def test_check_file_without_req_tags(tmp_path):
    test_file = tmp_path / "test.py"
    test_file.write_text("# No REQ tags\nclass User: pass\n")
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "--check", str(test_file)],
        capture_output=True, text=True, timeout=10
    )
    assert result.returncode == 0
    assert "No REQ tags" in result.stdout
