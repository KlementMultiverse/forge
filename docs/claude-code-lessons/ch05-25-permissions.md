# Claude Code Permission System: Technical Deep Dive

## 7-Step Decision Pipeline

1. Deny rule checks (tool-wide, content-specific, validation, user-interaction, safety, bypass-immune)
2. Allow rule resolution (bypass mode, tool-wide allows)
3. Mode transformations (classifiers, hooks, user prompts)

Deny rules always checked first — unconditional, not overrideable even in bypass mode.

## 5 Permission Modes

default (prompt), plan (read-only), acceptEdits (auto-approve edits in CWD), bypassPermissions (skip prompts), dontAsk (asks become denies), auto (AI classifier, ANT-only).

## Rule Matching

Exact, Prefix (`npm run:*`), Wildcard (`git * --force`). Auto-migration for legacy tool names.

## Bypass-Immune Paths

Writing to `.git/`, `.claude/`, `.vscode/`, shell configs. `requiresUserInteraction` tools. Content-specific ask rules.

## Auto Mode & AI Classifier

Fast-path optimizations prevent unnecessary API calls. Denial tracking: 3 consecutive → user prompt, 20 total → user prompt. Dangerous patterns stripped on entry.

## Rule Sources (7 Levels)

Enterprise policy → Project → User → Local → CLI flags → Runtime → Session state → Slash command frontmatter. `allowManagedPermissionRulesOnly` discards non-policy sources.

## Shadow Rule Detection

Identifies unreachable rules: deny-shadowed (tool-wide deny masks specific allows) and ask-shadowed.

## Permission Explainer

Side API call generates structured explanation with risk level (LOW/MEDIUM/HIGH).
