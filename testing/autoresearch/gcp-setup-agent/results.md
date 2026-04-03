# Autoresearch: @gcp-setup-agent

## Research Sources
- Secret Manager best practices: https://docs.google.com/secret-manager/docs/best-practices
- Secret Manager + Cloud Functions: https://oneuptime.com/blog/post/2026-02-17-how-to-use-secret-manager-with-cloud-functions-to-securely-access-api-keys-and-database-credentials/view
- IAM least privilege for Cloud Functions: https://www.conductorone.com/guides/implementing-cloud-iam-for-cloud-functions-with-a-least-privilege-approach/
- GCP Cloud Functions gen2 migration: https://www.binadox.com/blog/binadox-article-gcp-function-execution-environment-version/

## Run Results (5 Mental Simulations)

### Run 1: "Set up Cloud Storage + Cloud Functions for document processing"
**Result: PASS**
- Prompt provides exact gcloud commands for bucket creation with uniform access
- Covers Cloud Functions gen2 deployment with Python 3.12
- Includes verification steps
- Adequate guidance

### Run 2: "Create IAM service account with least-privilege for API backend"
**Result: PASS with gaps**
- Prompt correctly mandates scoped predefined roles (not Editor/Owner)
- Provides service account creation commands
- GAP: No mention of using dedicated service accounts per function (not one shared SA for all functions)
- GAP: No mention of IAM Conditions for secret-level access scoping (prompt does bucket-level condition but not secret-level)
- GAP: No mention of avoiding default service accounts in production (Google recommends against this)

### Run 3: "Configure Secret Manager for all application secrets"
**Result: PASS with gaps**
- Prompt covers secret creation and accessor role grants
- GAP: No mention of mounting secrets as environment variables in Cloud Functions gen2 (the simplest and recommended approach)
- GAP: No mention of regional secrets for data residency requirements
- GAP: No mention of Cloud Audit Logs for secret access monitoring
- GAP: No mention of secret rotation patterns or versioning strategy

### Run 4: "Set up in us-central1 with existing project"
**Result: PASS**
- Prompt covers region specification in all commands
- Includes project verification and billing check
- Adequate guidance

### Run 5: "Handle error: quota exceeded on Cloud Functions"
**Result: PASS**
- Prompt error handling table covers QUOTA_EXCEEDED with suggestions for quota increase or alternative region
- Adequate guidance

## Gaps Found (to fix in prompt)

1. **HIGH**: Missing dedicated service account per function guidance (not shared SA)
2. **HIGH**: Missing secret mounting as environment variables in Cloud Functions gen2
3. **MEDIUM**: Missing Cloud Audit Logs for secret access monitoring
4. **MEDIUM**: Missing regional secrets guidance for data residency
5. **MEDIUM**: Missing secret rotation and versioning strategy
6. **LOW**: Missing warning against default service accounts in production
