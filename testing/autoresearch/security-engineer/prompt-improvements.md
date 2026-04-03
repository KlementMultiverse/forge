# Security Engineer Agent — Prompt Improvements Summary

## Autoresearch Date: 2026-04-02
## Runs: 10 across 4 repos (fastapi-template, saleor, medusa, clinic-portal)

## Gap Analysis (aggregated from all 10 runs)

### GAPs Found and Fixed

| # | Gap | Found In | Severity | Fix Applied |
|---|---|---|---|---|
| G1 | No CORS audit checklist | Run 01 | HIGH | Added to Technology-Specific Checklists |
| G2 | No token lifetime audit | Run 01, 05 | HIGH | Added to JWT Security Checklist |
| G3 | No secret key lifecycle audit | Run 01 | MEDIUM | Added to JWT Security Checklist |
| G4 | No GraphQL security checklist | Run 02 | HIGH | Added new GraphQL section |
| G5 | No API-type-specific attack surface | Run 02 | MEDIUM | Added GraphQL/REST distinction |
| G6 | No Node.js/JS security patterns | Run 03, 10 | HIGH | Added new Node.js/TS section |
| G7 | No supply chain security guidance | Run 03, 07 | HIGH | Added new Supply Chain section |
| G8 | No DoS-via-input-parsing guidance | Run 03, 10 | HIGH | Added to input validation |
| G9 | No multi-tenant security checklist | Run 04 | HIGH | Added new Multi-Tenant section |
| G10 | No DB vs app-level enforcement distinction | Run 04 | MEDIUM | Added to Multi-Tenant section |
| G11 | No JWT-specific security checklist | Run 05 | HIGH | Added new JWT section |
| G12 | No password reset security guidance | Run 05 | MEDIUM | Added to Auth section |
| G13 | No Django security headers checklist | Run 06, 08 | HIGH | Added to Technology-Specific Checklists |
| G14 | No DEBUG mode audit | Run 06 | HIGH | Added to framework-specific checks |
| G15 | No middleware ordering audit | Run 06 | MEDIUM | Added to Django checklist |
| G16 | No rate limiting / brute force checklist | Run 08 | HIGH | Added new section |
| G17 | No password policy audit | Run 08 | HIGH | Added to Auth section |
| G18 | No SSRF checklist | Run 09 | HIGH | Added new section |
| G19 | No file upload security checklist | Run 09 | MEDIUM | Added to input validation |
| G20 | No outbound HTTP security guidance | Run 09 | MEDIUM | Added to SSRF section |
| G21 | Grep patterns too narrow | Run 09 | HIGH | Expanded grep commands |
| G22 | No TypeScript/frontend security | Run 10 | MEDIUM | Added to Node.js/TS section |
| G23 | No IDOR-specific checklist | Run 10 | HIGH | Added new IDOR section |
| G24 | No CSP guidance | Run 10 | LOW | Added to security headers |

### Statistics
- **Total findings across 10 runs**: 52
- **Findings the current prompt would guide to**: 11 (21%)
- **Findings the current prompt would PARTIALLY guide to**: 10 (19%)
- **Findings the current prompt would MISS**: 31 (60%)
- **Unique gaps identified**: 24
- **Coverage after fixes**: estimated 85%+

### Changes Applied to Prompt
1. Added Technology-Specific Security Checklists (Django, FastAPI, Node.js/TS, GraphQL)
2. Added expanded grep patterns covering 40+ dangerous patterns
3. Added Multi-Tenant Security section
4. Added JWT/Auth Security Checklist
5. Added Supply Chain Security section
6. Added SSRF/Outbound HTTP section
7. Added Rate Limiting/Brute Force section
8. Added IDOR/Authorization section
9. Added Security Headers checklist
10. Added File Upload security
11. Added Input Parsing DoS section
