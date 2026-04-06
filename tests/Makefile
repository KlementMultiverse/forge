BATS := ../tests/bats/bin/bats
BATS_FLAGS := --timing --print-output-on-failure

.PHONY: test-fast test-slow test-python test-all help

# Fast unit tests only (mocked, no I/O — run on every commit)
test-fast:
	$(BATS) $(BATS_FLAGS) bash/unit/

# Integration tests (real git repos — run before gate)
test-slow:
	$(BATS) $(BATS_FLAGS) bash/integration/

# Python tests
test-python:
	cd python && python3 -m pytest -v --tb=short unit/

# All tests
test-all: test-fast test-slow test-python

# Single test file
test-file:
	$(BATS) $(BATS_FLAGS) $(FILE)

help:
	@echo "Forge Test Suite"
	@echo ""
	@echo "Targets:"
	@echo "  test-fast    Run unit tests (fast, mocked)"
	@echo "  test-slow    Run integration tests (real repos)"
	@echo "  test-python  Run Python tests"
	@echo "  test-all     Run everything"
	@echo "  test-file    Run single file: make test-file FILE=bash/unit/forge-enforce.bats"
