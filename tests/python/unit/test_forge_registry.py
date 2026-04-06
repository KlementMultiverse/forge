"""Tests for scripts/forge-registry.py"""
import json
import subprocess
import sys
from pathlib import Path

FORGE_DIR = Path(__file__).parent.parent.parent.parent
SCRIPT = FORGE_DIR / "scripts" / "forge-registry.py"


def test_registry_script_exists():
    assert SCRIPT.exists()


def test_registry_generates_json():
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(FORGE_DIR)],
        capture_output=True, text=True, timeout=30
    )
    assert result.returncode == 0
    assert "Registry v2.0" in result.stdout


def test_registry_json_valid():
    registry_file = FORGE_DIR / "forge-registry.json"
    if registry_file.exists():
        data = json.loads(registry_file.read_text())
        assert data["version"] == "2.0"
        assert "components" in data
        assert "edges" in data
        assert "flows" in data
        assert "indexes" in data


def test_registry_has_all_component_types():
    registry_file = FORGE_DIR / "forge-registry.json"
    if registry_file.exists():
        data = json.loads(registry_file.read_text())
        components = data["components"]
        assert "agents" in components
        assert "commands" in components
        assert "scripts" in components
        assert "hooks" in components
        assert "templates" in components
        assert "rules" in components


def test_registry_impact_mode():
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(FORGE_DIR), "--impact", "install.sh", "--json"],
        capture_output=True, text=True, timeout=30
    )
    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["file"] == "install.sh"
    assert "is_global_short_circuit" in data
    assert "dependents" in data


def test_registry_changelog_mode():
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(FORGE_DIR), "--changelog"],
        capture_output=True, text=True, timeout=30
    )
    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert isinstance(data, dict)


def test_registry_mermaid_mode():
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(FORGE_DIR), "--mermaid"],
        capture_output=True, text=True, timeout=30
    )
    assert result.returncode == 0
    assert "graph TD" in result.stdout


def test_registry_has_9_flows():
    registry_file = FORGE_DIR / "forge-registry.json"
    if registry_file.exists():
        data = json.loads(registry_file.read_text())
        assert len(data["flows"]) == 9


def test_registry_has_phase_index():
    registry_file = FORGE_DIR / "forge-registry.json"
    if registry_file.exists():
        data = json.loads(registry_file.read_text())
        assert "phase_index" in data["indexes"]
        assert len(data["indexes"]["phase_index"]) > 0
