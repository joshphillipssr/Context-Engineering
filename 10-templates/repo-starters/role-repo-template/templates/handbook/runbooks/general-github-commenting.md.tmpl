# Runbook: Safe GitHub Commenting

## Scenario

You need to post deterministic Markdown comments to issues/PRs without introducing formatting defects or closed-artifact noise.

## Immediate Actions

1. Write multi-line content to a file.
2. Use `scripts/gh-safe-comment.sh` with `--body-file`.

PR comment:

```bash
scripts/gh-safe-comment.sh \
  --repo <owner/repo> \
  --pr <pr-number> \
  --body-file <path-to-comment.md>
```

Issue comment:

```bash
scripts/gh-safe-comment.sh \
  --repo <owner/repo> \
  --issue <issue-number> \
  --body-file <path-to-comment.md>
```

## Decision Points

- Default behavior blocks comments on closed PRs/issues.
- Use `--allow-closed` only when explicitly instructed to comment on a closed artifact.

## Verification Steps

After posting, verify both raw and rendered body:

```bash
gh api repos/<owner>/<repo>/issues/comments/<comment-id> --jq '.body'
gh api repos/<owner>/<repo>/issues/comments/<comment-id> -H 'Accept: application/vnd.github.full+json' --jq '.body_html'
```

## Post-Incident Follow-up

- If comment posting fails due to state or formatting workflow drift, append evidence to an existing `efficiency-opportunity` issue before handoff.
