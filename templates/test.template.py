"""
Test template with [REQ-xxx] traceability.

Every test function MUST reference the requirement it verifies
using a comment: # [REQ-xxx]

This enables the traceability script to verify:
- 100% REQ coverage (every requirement has a test)
- 0 orphans (no tests without a requirement)
- 0 drift (no mismatches between spec and tests)
"""


class TestExample:
    """Tests for [Module Name]."""

    def test_create_resource(self):  # [REQ-001]
        """Verify that [resource] can be created with valid input."""
        # Arrange
        # Act
        # Assert
        pass

    def test_create_resource_validation(self):  # [REQ-001]
        """Verify that invalid input is rejected."""
        # Arrange (invalid data)
        # Act
        # Assert (validation error)
        pass

    def test_state_transition_valid(self):  # [REQ-002]
        """Verify valid state transitions are allowed."""
        # Arrange (resource in initial state)
        # Act (transition to valid next state)
        # Assert (state changed, audit logged)
        pass

    def test_state_transition_invalid(self):  # [REQ-002]
        """Verify invalid state transitions are rejected."""
        # Arrange (resource in terminal state)
        # Act (attempt invalid transition)
        # Assert (error raised, state unchanged)
        pass

    def test_audit_log_created(self):  # [REQ-003]
        """Verify every mutation creates an audit log entry."""
        # Arrange
        # Act (any state mutation)
        # Assert (AuditLog entry exists with correct data)
        pass

    def test_unauthorized_access_denied(self):  # [REQ-004]
        """Verify unauthorized users cannot access protected resources."""
        # Arrange (user without permission)
        # Act (attempt access)
        # Assert (403 or redirect)
        pass
