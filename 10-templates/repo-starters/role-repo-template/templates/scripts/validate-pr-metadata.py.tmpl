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
    pattern = rf"^\s*{re.escape(field_name)}\s*:\s*(.*?)\s*$"
    match = re.search(pattern, body, flags=re.MULTILINE)
    if not match:
        return ""
    return match.group(1).strip()


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
