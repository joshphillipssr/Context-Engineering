#!/usr/bin/env python3

import argparse
import fnmatch
import json
import re
import sys
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

CANONICAL_ADR_ROOT = Path("00-os/adr")
FILENAME_PATTERN = re.compile(r"^(?P<adr_id>\d{4})-[a-z0-9-]+\.md$")
ADR_ID_PATTERN = re.compile(r"^\d{4}$")
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")

REQUIRED_METADATA_KEYS: Sequence[str] = (
    "ADR-ID",
    "Title",
    "Status",
    "Date",
    "Decision-Owners",
    "Approvers",
    "Supersedes",
    "Superseded-By",
)

REQUIRED_HEADINGS: Sequence[str] = (
    "## Context",
    "## Decision",
    "## Consequences",
    "## Alternatives Considered",
    "## References",
)

ALLOWED_STATUSES = {
    "Draft",
    "Proposed",
    "Accepted",
    "Superseded",
    "Deprecated",
}

ALLOWED_TRANSITIONS = {
    ("Draft", "Proposed"),
    ("Proposed", "Accepted"),
    ("Proposed", "Deprecated"),
    ("Accepted", "Superseded"),
    ("Accepted", "Deprecated"),
}


@dataclass
class Violation:
    rule_id: str
    severity: str
    path: str
    line: int
    message: str
    remediation: str


@dataclass
class ADRDocument:
    path: Path
    display_path: str
    metadata_values: Dict[str, List[Tuple[str, int]]]
    headings: Dict[str, List[int]]
    filename_id: Optional[str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate ADR files for schema, linkage, and lifecycle conformance."
    )
    parser.add_argument(
        "--path",
        required=True,
        help="ADR file or directory to validate.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings as errors (reserved; current validator emits errors only).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable JSON report.",
    )
    parser.add_argument(
        "--check-transitions",
        action="store_true",
        help="Enable ADR status transition checks.",
    )
    parser.add_argument(
        "--before",
        help="Directory containing ADR files from the previous state (required with --check-transitions).",
    )
    parser.add_argument(
        "--after",
        help="Directory containing ADR files from the current state (required with --check-transitions).",
    )
    parser.add_argument(
        "--include-glob",
        action="append",
        default=[],
        help="Optional glob filter(s) to include specific files.",
    )
    parser.add_argument(
        "--exclude-glob",
        action="append",
        default=[],
        help="Optional glob filter(s) to exclude specific files.",
    )
    parser.add_argument(
        "--canonical-root",
        default=str(CANONICAL_ADR_ROOT),
        help="Canonical ADR root for ADR001 path checks (default: 00-os/adr).",
    )

    args = parser.parse_args()

    if args.check_transitions and (not args.before or not args.after):
        parser.error("--check-transitions requires both --before and --after.")
    if (args.before or args.after) and not args.check_transitions:
        parser.error("--before/--after require --check-transitions.")

    return args


def to_display_path(path: Path, cwd: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(cwd).as_posix()
    except ValueError:
        return resolved.as_posix()


def discover_markdown_files(path: Path) -> List[Path]:
    if path.is_file():
        return [path.resolve()]
    if not path.is_dir():
        raise FileNotFoundError(f"Path does not exist or is not readable: {path}")
    return sorted(item.resolve() for item in path.rglob("*.md") if item.is_file())


def matches_any_glob(path: Path, cwd: Path, patterns: Sequence[str]) -> bool:
    if not patterns:
        return False
    relative = to_display_path(path, cwd)
    basename = path.name
    for pattern in patterns:
        if fnmatch.fnmatch(relative, pattern) or fnmatch.fnmatch(basename, pattern):
            return True
    return False


def parse_adr_document(path: Path, cwd: Path) -> ADRDocument:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise RuntimeError(f"Unable to read file '{path}': {exc}") from exc

    metadata_values: Dict[str, List[Tuple[str, int]]] = {}
    headings: Dict[str, List[int]] = {}

    metadata_active = True
    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.rstrip("\n")
        if line.startswith("## "):
            metadata_active = False
            headings.setdefault(line.strip(), []).append(line_number)
            continue

        if metadata_active:
            match = re.match(r"^([A-Za-z][A-Za-z0-9-]*):\s*(.*?)\s*$", line)
            if match:
                key = match.group(1)
                value = match.group(2)
                metadata_values.setdefault(key, []).append((value, line_number))

    filename_match = FILENAME_PATTERN.match(path.name)
    filename_id = filename_match.group("adr_id") if filename_match else None

    return ADRDocument(
        path=path,
        display_path=to_display_path(path, cwd),
        metadata_values=metadata_values,
        headings=headings,
        filename_id=filename_id,
    )


def add_violation(
    violations: List[Violation],
    rule_id: str,
    path: str,
    line: int,
    message: str,
    remediation: str,
    severity: str = "error",
) -> None:
    violations.append(
        Violation(
            rule_id=rule_id,
            severity=severity,
            path=path,
            line=line,
            message=message,
            remediation=remediation,
        )
    )


def get_single_metadata_value(
    document: ADRDocument, key: str
) -> Tuple[Optional[str], Optional[int]]:
    values = document.metadata_values.get(key, [])
    if len(values) != 1:
        return None, None
    return values[0][0], values[0][1]


def validate_filename_and_path(
    document: ADRDocument,
    canonical_root: Path,
    violations: List[Violation],
) -> None:
    resolved_path = document.path.resolve()
    try:
        resolved_path.relative_to(canonical_root)
    except ValueError:
        add_violation(
            violations,
            rule_id="ADR001",
            path=document.display_path,
            line=1,
            message="ADR file is outside canonical ADR root.",
            remediation=f"Move file under '{canonical_root.as_posix()}/'.",
        )

    if not FILENAME_PATTERN.match(document.path.name):
        add_violation(
            violations,
            rule_id="ADR002",
            path=document.display_path,
            line=1,
            message="Filename does not match required pattern '^\\d{4}-[a-z0-9-]+\\.md$'.",
            remediation="Rename file to '<ADR-ID>-<kebab-case-title>.md'.",
        )


def validate_required_metadata(document: ADRDocument, violations: List[Violation]) -> None:
    for key in REQUIRED_METADATA_KEYS:
        values = document.metadata_values.get(key, [])
        if not values:
            add_violation(
                violations,
                rule_id="ADR003",
                path=document.display_path,
                line=1,
                message=f"Missing required metadata key '{key}'.",
                remediation=f"Add exactly one '{key}: <value>' line in the ADR metadata block.",
            )
            continue

        if len(values) > 1:
            line = values[1][1]
            add_violation(
                violations,
                rule_id="ADR003",
                path=document.display_path,
                line=line,
                message=f"Duplicate metadata key '{key}'.",
                remediation=f"Keep exactly one '{key}' metadata line.",
            )


def validate_required_headings(document: ADRDocument, violations: List[Violation]) -> None:
    for heading in REQUIRED_HEADINGS:
        lines = document.headings.get(heading, [])
        if not lines:
            add_violation(
                violations,
                rule_id="ADR005",
                path=document.display_path,
                line=1,
                message=f"Missing required heading '{heading}'.",
                remediation=f"Add heading '{heading}' exactly once.",
            )
            continue

        if len(lines) > 1:
            add_violation(
                violations,
                rule_id="ADR005",
                path=document.display_path,
                line=lines[1],
                message=f"Duplicate required heading '{heading}'.",
                remediation=f"Keep heading '{heading}' exactly once.",
            )


def validate_metadata_formats(document: ADRDocument, violations: List[Violation]) -> None:
    adr_id_value, adr_id_line = get_single_metadata_value(document, "ADR-ID")
    status_value, status_line = get_single_metadata_value(document, "Status")
    date_value, date_line = get_single_metadata_value(document, "Date")
    supersedes_value, supersedes_line = get_single_metadata_value(document, "Supersedes")
    superseded_by_value, superseded_by_line = get_single_metadata_value(
        document, "Superseded-By"
    )

    if adr_id_value is not None and adr_id_line is not None:
        if not ADR_ID_PATTERN.match(adr_id_value):
            add_violation(
                violations,
                rule_id="ADR004",
                path=document.display_path,
                line=adr_id_line,
                message="'ADR-ID' must be a zero-padded 4-digit value.",
                remediation="Set ADR-ID to a value like '0007'.",
            )
        if document.filename_id is not None and document.filename_id != adr_id_value:
            add_violation(
                violations,
                rule_id="ADR006",
                path=document.display_path,
                line=adr_id_line,
                message="'ADR-ID' does not match filename prefix.",
                remediation=f"Set ADR-ID to '{document.filename_id}' or rename the file.",
            )

    if status_value is not None and status_line is not None and status_value not in ALLOWED_STATUSES:
        allowed = " | ".join(sorted(ALLOWED_STATUSES))
        add_violation(
            violations,
            rule_id="ADR004",
            path=document.display_path,
            line=status_line,
            message=f"'Status' value '{status_value}' is not allowed.",
            remediation=f"Use one of: {allowed}.",
        )

    if date_value is not None and date_line is not None:
        if not DATE_PATTERN.match(date_value):
            add_violation(
                violations,
                rule_id="ADR004",
                path=document.display_path,
                line=date_line,
                message="'Date' must use format YYYY-MM-DD.",
                remediation="Set Date to a real calendar date in YYYY-MM-DD format.",
            )
        else:
            try:
                datetime.strptime(date_value, "%Y-%m-%d")
            except ValueError:
                add_violation(
                    violations,
                    rule_id="ADR004",
                    path=document.display_path,
                    line=date_line,
                    message="'Date' is not a valid calendar date.",
                    remediation="Set Date to a valid calendar date (YYYY-MM-DD).",
                )

    for key, value, line in (
        ("Supersedes", supersedes_value, supersedes_line),
        ("Superseded-By", superseded_by_value, superseded_by_line),
    ):
        if value is None or line is None:
            continue
        if value != "N/A" and not ADR_ID_PATTERN.match(value):
            add_violation(
                violations,
                rule_id="ADR004",
                path=document.display_path,
                line=line,
                message=f"'{key}' must be 'N/A' or a 4-digit ADR ID.",
                remediation=f"Set '{key}' to 'N/A' or a valid ADR ID like '0003'.",
            )


def build_id_index(documents: Sequence[ADRDocument], violations: List[Violation]) -> Dict[str, ADRDocument]:
    index: Dict[str, ADRDocument] = {}
    for document in documents:
        adr_id_value, adr_id_line = get_single_metadata_value(document, "ADR-ID")
        if adr_id_value is None or adr_id_line is None:
            continue
        if not ADR_ID_PATTERN.match(adr_id_value):
            continue
        if adr_id_value in index:
            add_violation(
                violations,
                rule_id="ADR006",
                path=document.display_path,
                line=adr_id_line,
                message=f"Duplicate ADR-ID '{adr_id_value}' across files.",
                remediation="Assign a unique ADR-ID and filename prefix.",
            )
            continue
        index[adr_id_value] = document
    return index


def validate_supersession_links(
    documents: Sequence[ADRDocument],
    id_index: Dict[str, ADRDocument],
    violations: List[Violation],
) -> None:
    for document in documents:
        adr_id_value, _ = get_single_metadata_value(document, "ADR-ID")
        supersedes_value, supersedes_line = get_single_metadata_value(document, "Supersedes")
        superseded_by_value, superseded_by_line = get_single_metadata_value(
            document, "Superseded-By"
        )

        if (
            adr_id_value is not None
            and supersedes_value is not None
            and supersedes_line is not None
            and supersedes_value != "N/A"
            and ADR_ID_PATTERN.match(supersedes_value)
        ):
            if supersedes_value == adr_id_value:
                add_violation(
                    violations,
                    rule_id="ADR007",
                    path=document.display_path,
                    line=supersedes_line,
                    message="ADR cannot supersede itself.",
                    remediation="Set 'Supersedes' to a different ADR ID or 'N/A'.",
                )
            elif supersedes_value not in id_index:
                add_violation(
                    violations,
                    rule_id="ADR007",
                    path=document.display_path,
                    line=supersedes_line,
                    message=f"Supersedes target '{supersedes_value}' does not exist in scanned ADR set.",
                    remediation="Reference an existing ADR ID in this validation scope.",
                )
            else:
                target_doc = id_index[supersedes_value]
                target_value, _ = get_single_metadata_value(target_doc, "Superseded-By")
                if target_value != adr_id_value:
                    add_violation(
                        violations,
                        rule_id="ADR008",
                        path=document.display_path,
                        line=supersedes_line,
                        message=(
                            f"Supersession reciprocity mismatch: target ADR '{supersedes_value}' "
                            f"does not declare 'Superseded-By: {adr_id_value}'."
                        ),
                        remediation=(
                            f"Update ADR '{supersedes_value}' with 'Superseded-By: {adr_id_value}', "
                            "or remove supersession claim."
                        ),
                    )

        if (
            adr_id_value is not None
            and superseded_by_value is not None
            and superseded_by_line is not None
            and superseded_by_value != "N/A"
            and ADR_ID_PATTERN.match(superseded_by_value)
        ):
            if superseded_by_value == adr_id_value:
                add_violation(
                    violations,
                    rule_id="ADR007",
                    path=document.display_path,
                    line=superseded_by_line,
                    message="ADR cannot be superseded by itself.",
                    remediation="Set 'Superseded-By' to a different ADR ID or 'N/A'.",
                )
            elif superseded_by_value not in id_index:
                add_violation(
                    violations,
                    rule_id="ADR007",
                    path=document.display_path,
                    line=superseded_by_line,
                    message=f"Superseded-By target '{superseded_by_value}' does not exist in scanned ADR set.",
                    remediation="Reference an existing ADR ID in this validation scope.",
                )
            else:
                source_doc = id_index[superseded_by_value]
                source_value, _ = get_single_metadata_value(source_doc, "Supersedes")
                if source_value != adr_id_value:
                    add_violation(
                        violations,
                        rule_id="ADR008",
                        path=document.display_path,
                        line=superseded_by_line,
                        message=(
                            f"Supersession reciprocity mismatch: ADR '{superseded_by_value}' "
                            f"does not declare 'Supersedes: {adr_id_value}'."
                        ),
                        remediation=(
                            f"Update ADR '{superseded_by_value}' with 'Supersedes: {adr_id_value}', "
                            "or set this ADR field to 'N/A'."
                        ),
                    )


def collect_documents(
    target_path: Path,
    cwd: Path,
    include_globs: Sequence[str],
    exclude_globs: Sequence[str],
) -> List[ADRDocument]:
    files = discover_markdown_files(target_path)
    documents: List[ADRDocument] = []

    for path in files:
        if include_globs and not matches_any_glob(path, cwd, include_globs):
            continue
        if exclude_globs and matches_any_glob(path, cwd, exclude_globs):
            continue
        documents.append(parse_adr_document(path, cwd))

    documents.sort(key=lambda doc: doc.display_path)
    return documents


def validate_documents(
    documents: Sequence[ADRDocument],
    canonical_root: Path,
) -> List[Violation]:
    violations: List[Violation] = []

    for document in documents:
        validate_filename_and_path(document, canonical_root, violations)
        validate_required_metadata(document, violations)
        validate_metadata_formats(document, violations)
        validate_required_headings(document, violations)

    id_index = build_id_index(documents, violations)
    validate_supersession_links(documents, id_index, violations)

    return violations


def build_status_index(documents: Sequence[ADRDocument]) -> Dict[str, Tuple[str, ADRDocument, int]]:
    index: Dict[str, Tuple[str, ADRDocument, int]] = {}
    for document in documents:
        adr_id, _ = get_single_metadata_value(document, "ADR-ID")
        status, status_line = get_single_metadata_value(document, "Status")
        if adr_id is None or status is None or status_line is None:
            continue
        if not ADR_ID_PATTERN.match(adr_id):
            continue
        if status not in ALLOWED_STATUSES:
            continue
        index[adr_id] = (status, document, status_line)
    return index


def validate_transitions(
    before_docs: Sequence[ADRDocument],
    after_docs: Sequence[ADRDocument],
) -> List[Violation]:
    violations: List[Violation] = []
    before_status = build_status_index(before_docs)
    after_status = build_status_index(after_docs)

    for adr_id in sorted(set(before_status).intersection(after_status)):
        prior_status, _, _ = before_status[adr_id]
        next_status, next_doc, next_line = after_status[adr_id]

        if prior_status == next_status:
            continue
        if (prior_status, next_status) in ALLOWED_TRANSITIONS:
            continue

        add_violation(
            violations,
            rule_id="ADR009",
            path=next_doc.display_path,
            line=next_line,
            message=(
                f"Invalid status transition for ADR '{adr_id}': "
                f"{prior_status} -> {next_status}."
            ),
            remediation=(
                "Use an allowed transition: Draft->Proposed, Proposed->Accepted|Deprecated, "
                "Accepted->Superseded|Deprecated."
            ),
        )

    return violations


def format_violation_line(violation: Violation) -> str:
    return (
        f"{violation.rule_id} {violation.severity} "
        f"{violation.path}:{violation.line} {violation.message} "
        f"| remediation: {violation.remediation}"
    )


def create_json_report(
    violations: Sequence[Violation], files_scanned: int
) -> Dict[str, object]:
    rules_triggered = sorted({violation.rule_id for violation in violations})
    errors = sum(1 for violation in violations if violation.severity == "error")
    warnings = sum(1 for violation in violations if violation.severity == "warning")
    return {
        "summary": {
            "files_scanned": files_scanned,
            "errors": errors,
            "warnings": warnings,
            "rules_triggered": rules_triggered,
        },
        "violations": [asdict(violation) for violation in violations],
    }


def run_validation(args: argparse.Namespace) -> int:
    cwd = Path.cwd().resolve()
    canonical_root = (cwd / args.canonical_root).resolve()
    target_path = Path(args.path).resolve()

    documents = collect_documents(
        target_path=target_path,
        cwd=cwd,
        include_globs=args.include_glob,
        exclude_globs=args.exclude_glob,
    )

    violations = validate_documents(documents, canonical_root=canonical_root)

    if args.check_transitions:
        before_docs = collect_documents(
            target_path=Path(args.before).resolve(),
            cwd=cwd,
            include_globs=args.include_glob,
            exclude_globs=args.exclude_glob,
        )
        after_docs = collect_documents(
            target_path=Path(args.after).resolve(),
            cwd=cwd,
            include_globs=args.include_glob,
            exclude_globs=args.exclude_glob,
        )
        violations.extend(validate_transitions(before_docs, after_docs))

    violations.sort(key=lambda item: (item.path, item.line, item.rule_id, item.message))

    if args.json:
        report = create_json_report(violations, files_scanned=len(documents))
        print(json.dumps(report, indent=2, sort_keys=False))
    else:
        if violations:
            for violation in violations:
                print(format_violation_line(violation))
        else:
            print("ADR validation passed.")

    has_errors = any(v.severity == "error" for v in violations)
    has_warnings = any(v.severity == "warning" for v in violations)

    if has_errors:
        return 1
    if args.strict and has_warnings:
        return 1
    return 0


def main() -> int:
    try:
        args = parse_args()
        return run_validation(args)
    except (FileNotFoundError, RuntimeError) as exc:
        print(f"ADR validation runtime error: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("ADR validation interrupted.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
