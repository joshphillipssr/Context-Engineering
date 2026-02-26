#!/usr/bin/env python3

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
from typing import Dict, List, Optional, Tuple


ALLOWED_VALUES: Dict[str, List[str]] = {
    "Primary-Role": [
        "Executive Sponsor",
        "AI Governance Manager",
        "Compliance Officer",
        "Business Analyst",
        "Implementation Specialist",
        "Systems Architect",
    ],
    "Reviewed-By-Role": [
        "Compliance Officer",
        "Executive Sponsor",
        "N/A",
    ],
    "Executive-Sponsor-Approval": [
        "Required",
        "Not-Required",
        "Provided",
    ],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate required machine-readable PR metadata fields and canonical values."
    )
    parser.add_argument(
        "--input-file",
        required=True,
        help="Path to a file containing PR description/body markdown.",
    )
    parser.add_argument(
        "--repo",
        help="Repository in OWNER/REPO format for optional API-backed linkage verification.",
    )
    parser.add_argument(
        "--pr-number",
        type=int,
        help="Pull request number for optional API-backed linkage verification.",
    )
    parser.add_argument(
        "--github-token",
        help="GitHub token for optional API-backed linkage verification.",
    )
    return parser.parse_args()


def extract_field_values(body: str, field_name: str) -> List[str]:
    pattern = rf"^\s*(?:-\s*)?{re.escape(field_name)}\s*:\s*(.*?)\s*$"
    matches = re.findall(pattern, body, flags=re.MULTILINE)
    return [match.strip() for match in matches]


def extract_field_value(body: str, field_name: str) -> str:
    values = extract_field_values(body, field_name)
    return values[0] if values else ""


def parse_primary_issue_ref(value: str) -> Optional[Tuple[str, int]]:
    match = re.fullmatch(r"(Closes|Refs)\s+#(\d+)", value)
    if not match:
        return None
    return match.group(1), int(match.group(2))


def validate_primary_issue_ref(body: str) -> List[str]:
    errors: List[str] = []
    field_values = extract_field_values(body, "Primary-Issue-Ref")

    if not field_values:
        errors.append(
            "Missing required field 'Primary-Issue-Ref'. Add exactly one primary issue reference using 'Primary-Issue-Ref: Closes #<ISSUE_NUMBER>' or 'Primary-Issue-Ref: Refs #<ISSUE_NUMBER>'."
        )
        return errors

    if len(field_values) != 1:
        errors.append(
            f"Expected exactly one 'Primary-Issue-Ref' field; found {len(field_values)}."
        )
        return errors

    if parse_primary_issue_ref(field_values[0]) is None:
        errors.append(
            "Invalid 'Primary-Issue-Ref' format. Use exactly one value in the form 'Closes #<ISSUE_NUMBER>' or 'Refs #<ISSUE_NUMBER>'."
        )

    return errors


def query_issue_pr_linkage(
    repo: str, pr_number: int, issue_number: int, github_token: str
) -> Tuple[bool, bool]:
    owner, repo_name = repo.split("/", 1)
    query = """
query($owner: String!, $name: String!, $prNumber: Int!, $issueNumber: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $prNumber) {
      closingIssuesReferences(first: 100) {
        nodes {
          number
        }
      }
    }
    issue(number: $issueNumber) {
      timelineItems(last: 100, itemTypes: [CROSS_REFERENCED_EVENT, CONNECTED_EVENT]) {
        nodes {
          __typename
          ... on CrossReferencedEvent {
            source {
              __typename
              ... on PullRequest {
                number
              }
            }
          }
          ... on ConnectedEvent {
            subject {
              __typename
              ... on PullRequest {
                number
              }
            }
          }
        }
      }
    }
  }
}
"""
    payload = {
        "query": query,
        "variables": {
            "owner": owner,
            "name": repo_name,
            "prNumber": pr_number,
            "issueNumber": issue_number,
        },
    }
    request = urllib.request.Request(
        "https://api.github.com/graphql",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {github_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        document = json.load(response)

    if "errors" in document:
        raise RuntimeError(f"GraphQL errors: {document['errors']}")

    repository = document.get("data", {}).get("repository", {})
    pull_request = repository.get("pullRequest", {}) or {}
    issue = repository.get("issue", {}) or {}

    closing_numbers = {
        node.get("number")
        for node in pull_request.get("closingIssuesReferences", {}).get("nodes", [])
    }
    closes_primary_issue = issue_number in closing_numbers

    development_linked = False
    for node in issue.get("timelineItems", {}).get("nodes", []):
        typename = node.get("__typename")
        if typename == "CrossReferencedEvent":
            source = node.get("source") or {}
            if source.get("__typename") == "PullRequest" and source.get("number") == pr_number:
                development_linked = True
                break
        if typename == "ConnectedEvent":
            subject = node.get("subject") or {}
            if (
                subject.get("__typename") == "PullRequest"
                and subject.get("number") == pr_number
            ):
                development_linked = True
                break

    return closes_primary_issue, development_linked


def validate_development_linkage(
    body: str,
    repo: Optional[str],
    pr_number: Optional[int],
    github_token: Optional[str],
) -> List[str]:
    errors: List[str] = []
    linkage_status_values = extract_field_values(body, "Development-Linkage")
    linkage_evidence_values = extract_field_values(body, "Development-Linkage-Evidence")
    primary_issue_value = extract_field_value(body, "Primary-Issue-Ref")
    primary_issue_ref = parse_primary_issue_ref(primary_issue_value)

    if not linkage_status_values:
        errors.append(
            "Missing required field 'Development-Linkage'. Set it to 'Verified' or 'Exception'."
        )
        return errors

    if len(linkage_status_values) != 1:
        errors.append(
            f"Expected exactly one 'Development-Linkage' field; found {len(linkage_status_values)}."
        )
        return errors

    if len(linkage_evidence_values) != 1:
        errors.append(
            f"Expected exactly one 'Development-Linkage-Evidence' field; found {len(linkage_evidence_values)}."
        )
        return errors

    linkage_status = linkage_status_values[0]
    linkage_evidence = linkage_evidence_values[0]

    if linkage_status not in {"Verified", "Exception"}:
        errors.append(
            "Invalid 'Development-Linkage' value. Allowed: Verified | Exception."
        )
        return errors

    if not linkage_evidence:
        errors.append(
            "Missing required field 'Development-Linkage-Evidence'. Provide evidence of Issue Development linkage or, when using Exception, document why linkage is blocked and the compensating evidence."
        )

    api_context_provided = any((repo, pr_number, github_token))
    api_context_complete = all((repo, pr_number, github_token))

    if linkage_status == "Verified":
        if api_context_provided and not api_context_complete:
            errors.append(
                "Incomplete API verification context for 'Development-Linkage: Verified'. Provide --repo, --pr-number, and --github-token together."
            )
            return errors

        if api_context_complete and primary_issue_ref is not None:
            primary_mode, issue_number = primary_issue_ref
            try:
                closes_primary_issue, development_linked = query_issue_pr_linkage(
                    repo=repo or "",
                    pr_number=pr_number or 0,
                    issue_number=issue_number,
                    github_token=github_token or "",
                )
            except (RuntimeError, urllib.error.URLError, TimeoutError) as exc:
                errors.append(
                    f"Failed API-backed Development linkage verification: {exc}"
                )
                return errors

            if not development_linked:
                errors.append(
                    "API verification failed: primary Issue does not show this PR in Development linkage events."
                )

            if primary_mode == "Closes" and not closes_primary_issue:
                errors.append(
                    "API verification failed: 'Primary-Issue-Ref: Closes #<ISSUE_NUMBER>' is not reflected in PR closing issue references."
                )

    return errors


def validate(
    body: str, repo: Optional[str], pr_number: Optional[int], github_token: Optional[str]
) -> List[str]:
    errors: List[str] = []

    for field_name, allowed_values in ALLOWED_VALUES.items():
        field_value = extract_field_value(body, field_name)

        if not field_value:
            errors.append(
                f"Missing required PR metadata field '{field_name}' or empty value."
            )
            continue

        if field_value not in allowed_values:
            allowed = " | ".join(allowed_values)
            errors.append(
                f"Invalid value for '{field_name}': '{field_value}'. Allowed: {allowed}."
            )

    errors.extend(validate_primary_issue_ref(body))
    errors.extend(
        validate_development_linkage(
            body=body, repo=repo, pr_number=pr_number, github_token=github_token
        )
    )

    return errors


def main() -> int:
    args = parse_args()

    try:
        with open(args.input_file, "r", encoding="utf-8") as handle:
            body = handle.read()
    except OSError as exc:
        print(f"Failed to read input file '{args.input_file}': {exc}", file=sys.stderr)
        return 2

    errors = validate(
        body=body,
        repo=args.repo,
        pr_number=args.pr_number,
        github_token=args.github_token,
    )
    if errors:
        print("PR metadata validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("PR metadata validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
