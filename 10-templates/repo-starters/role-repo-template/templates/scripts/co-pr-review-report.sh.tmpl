#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/co-pr-review-report.sh --repo <owner/repo> --pr <number> [--output <path>]

Example:
  scripts/co-pr-review-report.sh \
    --repo Josh-Phillips-LLC/Context-Engineering \
    --pr 176 \
    --output WIP/pr176-review-report.md
USAGE
}

repo=""
pr_number=""
output_file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --pr)
      pr_number="${2:-}"
      shift 2
      ;;
    --output)
      output_file="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$repo" ] || [ -z "$pr_number" ]; then
  echo "Missing required --repo or --pr" >&2
  usage
  exit 1
fi

if [ -z "$output_file" ]; then
  output_file="WIP/pr${pr_number}-review-report.md"
fi

pr_json="$(gh pr view "$pr_number" -R "$repo" --json number,title,url,headRefName,baseRefName,body,files)"

pr_title="$(printf '%s' "$pr_json" | jq -r '.title')"
pr_url="$(printf '%s' "$pr_json" | jq -r '.url')"
head_ref="$(printf '%s' "$pr_json" | jq -r '.headRefName')"
base_ref="$(printf '%s' "$pr_json" | jq -r '.baseRefName')"
files_csv="$(printf '%s' "$pr_json" | jq -r '[.files[].path] | join(", ")')"

pr_body="$(printf '%s' "$pr_json" | jq -r '.body // ""')"

metadata_keys=(
  "Primary-Role"
  "Reviewed-By-Role"
  "Executive-Sponsor-Approval"
)

metadata_summary=""
for key in "${metadata_keys[@]}"; do
  if printf '%s\n' "$pr_body" | grep -Eq "^${key}:[[:space:]]+"; then
    metadata_summary="${metadata_summary}- ${key}: detected\n"
  else
    metadata_summary="${metadata_summary}- ${key}: missing\n"
  fi
done

mkdir -p "$(dirname "$output_file")"

cat > "$output_file" <<EOF
# PR Review Report

PR: [#${pr_number}](${pr_url})
Title: ${pr_title}
Base/Head: \`${base_ref}\` <- \`${head_ref}\`
Changed files: ${files_csv}

## 1. Verdict

- [ ] APPROVE
- [ ] REQUEST CHANGES

Justification bullets:
- 
- 
- 

## 2. Gap & Alignment Table

| Canvas Requirement | File(s) | Status | Notes / Required Action |
|--------------------|---------|--------|-------------------------|
| PR metadata keys present (\`Primary-Role\`, \`Reviewed-By-Role\`, \`Executive-Sponsor-Approval\`) | PR body | ⚠️ | $(printf '%b' "$metadata_summary" | tr '\n' ';' | sed 's/;$/./') |
| Issue linkage/closure statement present | PR body | ⚠️ | Confirm \`Closes #<ISSUE_NUMBER>\` is present. |
| Branch creation follows issue-first workflow | PR metadata/history | ⚠️ | Confirm branch provenance from issue develop flow. |
| Role/status labels follow canonical governance labels | PR labels | ⚠️ | Ensure exactly one \`status:*\` label + correct \`role:*\` label. |
| Scope aligned to issue objective | ${files_csv} | ⚠️ | Validate no unrelated refactors/scope drift. |
| Sensitive content controls (no secrets/internal data) | ${files_csv} | ⚠️ | Verify redaction/safety expectations hold. |
| Regression evidence provided | PR body / CI | ⚠️ | Confirm tests/checks and risk-tier evidence. |
| Protected-path handling and approval requirements | Changed protected files (if any) | ⚠️ | Confirm Executive Sponsor signal where required. |

## 3. Risk Flags

- If none, state: **No material risks identified.**
- 

## 4. Suggested Follow-up PRs (optional)

- 
EOF

echo "Generated compliance review draft: ${output_file}"
