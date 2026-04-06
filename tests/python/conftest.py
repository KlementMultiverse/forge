"""Shared fixtures for forge Python tests."""
import json
import os
import tempfile
import shutil
import pytest
from pathlib import Path


FORGE_DIR = Path(__file__).parent.parent.parent


@pytest.fixture
def forge_dir():
    """Return the forge project root."""
    return FORGE_DIR


@pytest.fixture
def temp_project(tmp_path):
    """Create a temporary project directory with forge structure."""
    project = tmp_path / "test-project"
    project.mkdir()
    (project / "docs").mkdir()
    (project / "apps").mkdir()
    (project / "scripts").mkdir()
    return project


@pytest.fixture
def mock_spec(temp_project):
    """Create a mock SPEC.md with REQ tags."""
    spec = temp_project / "SPEC.md"
    spec.write_text(
        "# Test Spec\n\n"
        "REQ-AUTH-001 User must login\n"
        "REQ-AUTH-002 Failed login locks account\n"
        "REQ-UI-001 Dashboard shows stats\n"
    )
    return spec


@pytest.fixture
def mock_state(temp_project):
    """Create a mock forge-state.json."""
    state_file = temp_project / "docs" / "forge-state.json"
    state = {
        "version": "1.1.0",
        "project": "test",
        "current_step": 5,
        "current_phase": 0,
        "status": "IN_PROGRESS",
    }
    state_file.write_text(json.dumps(state, indent=2))
    return state_file
