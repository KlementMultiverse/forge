# Test: @root-cause-analyst (Run 1/10)

## Input
ProgrammingError: relation "workflows_workflow" does not exist — only on new tenants

## Score: 12/12 (100%)

## Key Findings:
1. ROOT CAUSE IDENTIFIED: @transaction.atomic in provision_tenant() causes
   migrate_schemas DDL to roll back if add_user() fails, leaving empty schema shell
2. Evidence chain: 5 pieces of evidence from actual source code
3. Verification: 5 specific Bash commands to confirm hypothesis
4. DID NOT try to fix — investigation only (correct behavior)
5. /learn insight flagged with specific prevention strategy
6. Delegated to @django-tenants-agent (correct agent)
7. Found that seed_demo.py has "except Exception: pass" that masks failures

## Verdict: EXCELLENT
Found a REAL architectural issue (transaction atomicity vs DDL in PostgreSQL).
Agent correctly identified root cause, not symptom.
