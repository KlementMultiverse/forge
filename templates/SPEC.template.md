# [PROJECT NAME] — Complete Build Spec

## Overview

[1-2 paragraph description of what this project does, who it's for, and what problem it solves.]

## Tech Stack

| Technology | Purpose | Version |
|---|---|---|
| [Runtime] | [Purpose] | [Version] |
| [Framework] | [Purpose] | [Version] |
| [Database] | [Purpose] | [Version] |
| [Cache] | [Purpose] | [Version] |
| [Storage] | [Purpose] | [Version] |
| [AI/LLM] | [Purpose] | [Version] |

## Architecture

### Project Structure

```
project-name/
├── config/
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   ├── [app1]/
│   ├── [app2]/
│   └── [app3]/
├── templates/
├── static/
├── tests/
├── docker-compose.yml
├── Dockerfile
└── pyproject.toml
```

### Shared vs Tenant Apps (if multi-tenant)

**Shared (public schema):**
- [List apps that live in shared/public schema]

**Tenant (per-tenant schema):**
- [List apps that live in each tenant's schema]

## Models

### [REQ-001] [Model Name]

| Field | Type | Constraints | Notes |
|---|---|---|---|
| id | BigAutoField | PK | Auto-generated |
| [field] | [type] | [constraints] | [notes] |

**Business Rules:**
- [Rule 1]
- [Rule 2]

### [REQ-002] [Model Name]

[Same format as above]

## API Endpoints

### [REQ-xxx] [Endpoint Group]

```
[METHOD] /api/[path]/
  Request: { [field]: [type], ... }
  Response: { [field]: [type], ... }
  Errors: [status] ([reason]), ...
  Auth: [required/optional/none]
  Permissions: [admin/staff/any authenticated]
```

## Frontend Pages

### [REQ-xxx] [Page Name]

- **URL:** /[path]/
- **Purpose:** [What the user does here]
- **Components:**
  - [Component 1: description]
  - [Component 2: description]
- **API calls:** [Which endpoints this page uses]

## Security

- **Authentication:** [Method — session, JWT, OAuth]
- **Authorization:** [Role-based — admin/staff/user]
- **Data isolation:** [How data is separated between users/tenants]
- **Audit logging:** [What is tracked, immutability rules]
- **Input validation:** [Sanitization rules, XSS prevention]
- **Secrets:** [All from env vars, never hardcoded]

## Business Rules

- [REQ-xxx] [Rule description — e.g., "Tasks follow state machine: created → assigned → in_progress → completed"]
- [REQ-xxx] [Rule description]
- [REQ-xxx] [Rule description]

## Seed/Demo Data

- [What demo data should exist for testing/demos]
- [Users, sample objects, realistic scenarios]
