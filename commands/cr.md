# /cr — CodeRabbit Integration Command

Unified interface to CodeRabbit AI reviewer. Use this to interact with CR from the forge workflow.

## Input
$ARGUMENTS — subcommand + optional args

## Subcommands

| Subcommand | What it does | When to use |
|---|---|---|
| `review` | Trigger incremental review on current PR | After pushing fixes |
| `full-review` | Full review from scratch | When CR missed something or stale |
| `plan` | Ask CR for implementation plan | Before starting work |
| `tests` | Ask CR to generate unit tests | After implementation, before gate |
| `diagram` | Generate sequence diagram of changes | Before design review |
| `autofix` | Auto-fix issues from review comments | After CR review with actionable items |
| `resolve` | Resolve all CR review comments | After fixing all CR findings |
| `check` | Run custom pre-merge checks | Before merging |
| `status` | Show CR review status on current PR | Anytime |
| `approve` | Check if CR has approved | Before merge at gate |

## Execution

<system-reminder>
CodeRabbit is a MANDATORY reviewer for ALL forge PRs. Gates block without CR approval.
NEVER merge without CR approval. NEVER ignore CR findings without addressing them.
</system-reminder>

### Step 1: Identify current PR

```bash
# Get current branch and PR number
BRANCH=$(git branch --show-current)
PR_NUM=$(gh pr view --json number -q '.number' 2>/dev/null)
if [ -z "$PR_NUM" ]; then
    echo "No PR found for branch $BRANCH"
    echo "Create one first: gh pr create"
    exit 1
fi
echo "PR #$PR_NUM on branch $BRANCH"
```

### Step 2: Route to subcommand

**If `$ARGUMENTS` = `review`:**
```bash
gh pr comment $PR_NUM --body "@coderabbitai review"
```
Wait 60s, then fetch CR response:
```bash
gh api repos/{owner}/{repo}/issues/$PR_NUM/comments --jq '.[] | select(.user.login=="coderabbitai[bot]") | .body' | tail -1
```

**If `$ARGUMENTS` = `full-review`:**
```bash
gh pr comment $PR_NUM --body "@coderabbitai full review"
```

**If `$ARGUMENTS` = `plan`:**
```bash
gh pr comment $PR_NUM --body "@coderabbitai plan"
```

**If `$ARGUMENTS` = `tests`:**
```bash
gh pr comment $PR_NUM --body "@coderabbitai generate unit tests"
```
CR will create a stacked PR or commit with generated tests.

**If `$ARGUMENTS` = `diagram`:**
```bash
gh pr comment $PR_NUM --body "@coderabbitai generate sequence diagram"
```

**If `$ARGUMENTS` = `autofix`:**
```bash
gh pr comment $PR_NUM --body "@coderabbitai autofix"
```

**If `$ARGUMENTS` = `resolve`:**
```bash
gh pr comment $PR_NUM --body "@coderabbitai resolve"
```

**If `$ARGUMENTS` = `check`:**
Post custom pre-merge checks based on forge rules:
```bash
gh pr comment $PR_NUM --body '@coderabbitai evaluate custom pre-merge check --name "Forge Compliance" --mode error --instructions "Check: 1) Every phase file must have HANDOFF METRIC sections. 2) hooks.json must be valid JSON. 3) No raw {{PLACEHOLDERS}} in rules/*.md. 4) All test files must have setup() and teardown(). 5) No TODO/FIXME comments in changed files. 6) Scripts must be executable. 7) Files must be under 300 lines."'
```

**If `$ARGUMENTS` = `status`:**
```bash
# Check CR review state
REVIEWS=$(gh api repos/{owner}/{repo}/pulls/$PR_NUM/reviews --jq '.[] | select(.user.login=="coderabbitai[bot]") | .state' 2>/dev/null)
echo "CR review states: $REVIEWS"
LATEST=$(echo "$REVIEWS" | tail -1)
if [ "$LATEST" = "APPROVED" ]; then
    echo "CR STATUS: APPROVED — ready for merge"
elif [ "$LATEST" = "CHANGES_REQUESTED" ]; then
    echo "CR STATUS: CHANGES_REQUESTED — fix findings first"
    # Fetch latest comments
    gh api repos/{owner}/{repo}/pulls/$PR_NUM/comments --jq '.[] | select(.user.login=="coderabbitai[bot]") | "\(.path):\(.line // "general") — \(.body | split("\n")[0])"' | head -10
else
    echo "CR STATUS: PENDING — review not complete yet"
fi
```

**If `$ARGUMENTS` = `approve`:**
Same as `status` but returns exit code:
- Exit 0 if APPROVED
- Exit 1 if CHANGES_REQUESTED or PENDING
Used by `/gate` to block merge.

### Step 3: Wait and report

After any CR command, wait for response:
1. Wait 30-60 seconds (CR processing time)
2. Fetch latest CR comment
3. Summarize findings to user
4. If CHANGES_REQUESTED: list action items

## Integration Points

This command is called by:
- `/gate` — calls `/cr approve` before allowing merge
- `/review` — calls `/cr review` after pushing review fixes
- Phase A S9 — calls `/cr check` for pre-merge validation
- PM workflow — calls `/cr plan` before starting implementation

## Forge Flow Integration

```
Code change → push → /cr review → fix findings → /cr resolve → /cr approve → /gate → merge
```

At every phase gate:
```
/checkpoint → /cr check → /cr status → /gate (blocks if CR not APPROVED)
```
