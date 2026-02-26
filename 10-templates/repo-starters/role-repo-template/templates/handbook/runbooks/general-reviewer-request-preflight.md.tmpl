# Runbook: Reviewer Request Preflight

## Scenario

You need to request PR review without triggering avoidable GitHub API `422` failures.

## Immediate Actions

1. Select a user login (never use organization handles).
2. Validate collaborator eligibility before requesting review.

```bash
scripts/request-pr-review.sh \
  --repo <owner/repo> \
  --pr <pr-number> \
  --reviewer <github-login>
```

## Decision Points

- If reviewer is not a collaborator, stop and choose a valid collaborator.
- If no valid reviewer is available, post a guidance note to the PR and escalate.

List collaborators:

```bash
gh api repos/<owner>/<repo>/collaborators --jq '.[].login'
```

## Verification Steps

```bash
gh pr view <pr-number> -R <owner/repo> --json reviewRequests --jq '.reviewRequests[].login'
```

## Post-Incident Follow-up

- If reviewer request failed due to unknown collaborator mapping, append the evidence to an `efficiency-opportunity` issue and include repo/pr context.
