# Domain Inference Rules

PM consults this file during Phase A Step S2 after Q1 ("What are you building?").
Maps project domains to compliance, integrations, scale, deployment, and other non-functional requirements.

## How to Use

1. After Q1, identify the domain from user's answer
2. Look up the domain in the taxonomy below
3. Capture inferred requirements in discovery-notes.md with confidence levels
4. Present inferred items to user in Q5 Part A for confirmation
5. HIGH_RISK domains trigger mandatory deep-dive questions

---

## Domain Taxonomy

| Domain Keywords | Compliance | Auth Pattern | Common Integrations | Scale Tier | Deployment | A11Y | i18n | Mobile | HIGH_RISK |
|----------------|-----------|-------------|-------------------|-----------|-----------|------|------|--------|-----------|
| healthcare, clinic, medical, patient, ehr, hospital | HIPAA, HITECH | RBAC with role hierarchy | EHR/EMR (HL7/FHIR), lab systems, pharmacy | Medium | Private cloud / on-prem | Recommended | Regional | PWA for appointments | YES |
| fintech, banking, payments, trading, wallet | PCI-DSS, SOX, KYC/AML | MFA mandatory | Payment processors, credit bureaus, regulatory APIs | High | Private cloud, data residency | Required | Multi-currency | Native app | YES |
| ecommerce, shop, store, cart, marketplace | PCI-DSS (if payments) | Customer accounts + guest | Payment gateway (Stripe/PayPal), shipping, inventory | High (spiky) | Cloud (CDN critical) | Recommended | Multi-region | PWA or native | NO |
| education, learning, lms, course, school | FERPA, COPPA (if minors) | Institutional SSO (SAML) | LTI for LMS, SCORM for content, video streaming | Medium | Cloud | WCAG 2.1 AA required | Multi-language | Responsive web | YES (if minors) |
| saas, platform, b2b, multi-tenant | SOC2 | SSO/SAML + API keys | Billing (Stripe), SSO providers, webhooks | Medium-High | Cloud with SLA | Recommended | Multi-region | Responsive web | NO |
| government, civic, public-sector | FedRAMP, Section 508 | PIV/CAC or SSO | Government APIs, identity verification | Medium | Gov cloud (FedRAMP) | WCAG 2.1 AA required | Multi-language required | Responsive web | YES |
| social, community, forum, messaging | GDPR, COPPA (if minors) | Social login + email | Push notifications, media CDN, search | High | Cloud (global CDN) | Recommended | Multi-language | Native app | NO |
| iot, hardware, embedded, devices | Varies by industry | Device certificates + API keys | MQTT, device management, telemetry | High (event-driven) | Edge + cloud hybrid | N/A | Regional | Native app | NO |
| ai, ml, llm, chatbot, agents | Varies + AI safety | API keys + user auth | LLM providers (OpenAI/Anthropic), vector DB | Medium | Cloud (GPU if needed) | Recommended | Multi-language | Web | NO |
| internal, admin, backoffice, dashboard | Company security policy | LDAP/AD integration | Internal APIs, databases | Low (<100 users) | On-prem or VPN | Optional | Usually single | Web only | NO |
| crm, sales, leads, customers | GDPR, CCPA | SSO + role-based | Email (SendGrid), calendar, phone (Twilio) | Medium | Cloud | Optional | Multi-region | Responsive web | NO |
| legal, contracts, compliance, law | Attorney-client privilege | RBAC + MFA | Document management, e-signature (DocuSign) | Low-Medium | Private cloud | Optional | Regional | Web | YES |
| media, content, publishing, blog | DMCA, copyright | Social login + author roles | CDN, media processing, search, RSS | Medium-High | Cloud (CDN critical) | Recommended | Multi-language | Responsive web | NO |
| logistics, supply-chain, warehouse, shipping | Industry-specific | Multi-org RBAC | ERP systems, mapping APIs, barcode/RFID | Medium | Cloud or hybrid | Optional | Multi-region | Mobile (field workers) | NO |

---

## Security Signals by Compliance Type

| Compliance | Security Requirements | CLAUDE.md Rules to Generate |
|-----------|----------------------|---------------------------|
| HIPAA | PHI encrypted at rest (AES-256) + transit (TLS 1.3), audit log immutable, auto-logout 15min, BAA required | "MUST encrypt all patient data at rest and in transit", "MUST have immutable audit log for all PHI access", "MUST auto-logout after 15 minutes inactivity" |
| PCI-DSS | Tokenize card data (never store raw), PCI-compliant payment processor, quarterly vulnerability scans | "NEVER store raw card numbers — use payment processor tokenization", "MUST use PCI-compliant processor (Stripe/Braintree)" |
| GDPR | Consent management, right to erasure, data portability, DPO designation, 72hr breach notification | "MUST implement consent management for all personal data", "MUST support data erasure requests within 30 days" |
| SOC2 | Access controls, encryption, monitoring, incident response, change management | "MUST have role-based access control on all endpoints", "MUST log all authentication events" |
| FERPA | Student record protection, parent access rights, directory information opt-out | "MUST restrict student record access to authorized school officials", "NEVER expose student data to unauthorized users" |
| FedRAMP | NIST 800-53 controls, continuous monitoring, authorized cloud provider | "MUST deploy to FedRAMP-authorized cloud provider", "MUST implement NIST 800-53 security controls" |
| WCAG 2.1 AA | Color contrast 4.5:1, keyboard navigation, screen reader support, alt text, focus indicators | "MUST meet WCAG 2.1 AA contrast ratio (4.5:1)", "MUST support full keyboard navigation" |

---

## Deep-Dive Triggers

These conditions trigger mandatory follow-up questions after Q5:

| Trigger | Condition | Questions to Ask |
|---------|-----------|-----------------|
| Regulated industry | HIGH_RISK = YES in domain table | "Which specific regulations? Data residency requirements? Audit requirements?" |
| Multi-tenant confirmed | User selected multi-tenant in Q5 | "Tenant isolation model? (schema/row/database) Tenant-level customization? Per-tenant billing?" |
| AI/LLM features | User selected AI/LLM in Q5 | "Which model provider? What AI task type? Acceptable cost per interaction? AI failure handling?" |
| High scale | Success criteria implies >10K users or SCALE_TIER = High | "Expected concurrent users at launch? Peak patterns? Data volume growth?" |
| Multiple user types (>3) | Q2 identified >3 distinct roles | "List each role's permissions. Any approval workflows? Role hierarchy?" |

---

## Confidence Levels

| Level | Meaning | Action |
|-------|---------|--------|
| 95% | Domain keyword exact match + compliance is legally required | Present as "required" in Q5 |
| 80-94% | Strong domain signal but may not apply to all projects in domain | Present as "recommended" in Q5 |
| 60-79% | Possible based on domain but needs user confirmation | Present as "optional" in Q5 |
| <60% | Weak signal — may or may not apply | Do NOT present — only add if user explicitly mentions |
