# New Project — Spec
<!-- {{FORGE_PLACEHOLDER}} — This file will be replaced by /forge Phase A Step S4. -->
<!-- Do not treat anything below as real requirements. Run /forge to configure. -->

<!--
TEMPLATE (agents: Read this file, replace all {{PLACEHOLDERS}}, remove comment blocks):

# {{PROJECT_NAME}} — Complete Build Spec

## Overview

{{OVERVIEW_PARAGRAPHS}}

## Tech Stack

| Technology | Purpose | Version |
|---|---|---|
| {{RUNTIME}} | {{PURPOSE}} | {{VERSION}} |
| {{FRAMEWORK}} | {{PURPOSE}} | {{VERSION}} |
| {{DATABASE}} | {{PURPOSE}} | {{VERSION}} |
| {{CACHE}} | {{PURPOSE}} | {{VERSION}} |
| {{STORAGE}} | {{PURPOSE}} | {{VERSION}} |

## Architecture

### Project Structure

```
{{PROJECT_TREE}}
```

### Shared vs Tenant Apps (if multi-tenant)

**Shared (public schema):**
- {{SHARED_APPS}}

**Tenant (per-tenant schema):**
- {{TENANT_APPS}}

## Models

### [REQ-001] {{MODEL_NAME}}

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | BigAutoField | PK | Auto-generated |
| {{FIELD}} | {{TYPE}} | {{CONSTRAINTS}} | {{NOTES}} |

**Business Rules:**
- {{RULE}}

## API Endpoints

### [REQ-xxx] {{ENDPOINT_GROUP}}

```
{{METHOD}} /api/{{PATH}}/
  Request: { {{FIELDS}} }
  Response: { {{FIELDS}} }
  Errors: {{STATUS}} ({{REASON}})
  Auth: {{AUTH_LEVEL}}
  Permissions: {{PERMISSIONS}}
```

## Frontend Pages

### [REQ-xxx] {{PAGE_NAME}}

- **URL:** /{{PATH}}/
- **Purpose:** {{PURPOSE}}
- **Components:** {{COMPONENTS}}
- **API calls:** {{ENDPOINTS_USED}}

## Security

- **Authentication:** {{AUTH_METHOD}}
- **Authorization:** {{AUTHZ_METHOD}}
- **Data isolation:** {{ISOLATION_METHOD}}
- **Audit logging:** {{AUDIT_RULES}}
- **Input validation:** {{VALIDATION_RULES}}
- **Secrets:** All from env vars, never hardcoded

## Business Rules

- [REQ-xxx] {{RULE_DESCRIPTION}}

## Seed/Demo Data

- {{SEED_DATA_DESCRIPTION}}

END TEMPLATE
-->
