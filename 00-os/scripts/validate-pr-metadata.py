#!/usr/bin/env python3

import argparse
import re
import sys
from typing import Dict, List


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
    return parser.parse_args()


def extract_field_value(body: str, field_name: str) -> str:
    pattern = rf"^\s*(?:-\s*)?{re.escape(field_name)}\s*:\s*(.*?)\s*$"
    match = re.search(pattern, body, flags=re.MULTILINE)
    if not match:
        return ""
    return match.group(1).strip()


def validate_primary_issue_ref(body: str) -> List[str]:
    errors: List[str] = []
    field_value = extract_field_value(body, "Primary-Issue-Ref")

    if not field_value:
        errors.append(
            "Missing required field 'Primary-Issue-Ref'. Add exactly one primary issue reference using 'Primary-Issue-Ref: Closes #<ISSUE_NUMBER>' or 'Primary-Issue-Ref: Refs #<ISSUE_NUMBER>'."
        )
        return errors

    if not re.fullmatch(r"(Closes|Refs)\s+#\d+", field_value):
        errors.append(
            "Invalid 'Primary-Issue-Ref' format. Use exactly one value in the form 'Closes #<ISSUE_NUMBER>' or 'Refs #<ISSUE_NUMBER>'."
        )

    return errors


def validate_development_linkage(body: str) -> List[str]:
    errors: List[str] = []
    linkage_status = extract_field_value(body, "Development-Linkage")
    linkage_evidence = extract_field_value(body, "Development-Linkage-Evidence")

    if not linkage_status:
        errors.append(
            "Missing required field 'Development-Linkage'. Set it to 'Verified' or 'Exception'."
        )
        return errors

    if linkage_status not in {"Verified", "Exception"}:
        errors.append(
            "Invalid 'Development-Linkage' value. Allowed: Verified | Exception."
        )
        return errors

    if not linkage_evidence:
        errors.append(
            "Missing required field 'Development-Linkage-Evidence'. Provide evidence of Issue Development linkage or, when using Exception, document why linkage is blocked and the compensating evidence."
        )

    return errors


def validate(body: str) -> List[str]:
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
    errors.extend(validate_development_linkage(body))

    return errors


def main() -> int:
    args = parse_args()

    try:
        with open(args.input_file, "r", encoding="utf-8") as handle:
            body = handle.read()
    except OSError as exc:
        print(f"Failed to read input file '{args.input_file}': {exc}", file=sys.stderr)
        return 2

    errors = validate(body)
    if errors:
        print("PR metadata validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("PR metadata validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
