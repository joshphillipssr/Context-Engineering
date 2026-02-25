#!/usr/bin/env python3
"""
Validate governance ownership YAML artifacts.

This validator is intentionally deterministic and focused on two files:
  - 00-os/governed-repos.yml
  - .context-engineering/governance.yml

It enforces required keys and allowed state values:
  autonomous | transition | governed
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
from typing import Any

import yaml

ALLOWED_STATES = {"autonomous", "transition", "governed"}
REPO_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")


def load_yaml(path: pathlib.Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return yaml.safe_load(handle)
    except FileNotFoundError:
        raise ValueError(f"{path}: file not found")
    except yaml.YAMLError as exc:
        raise ValueError(f"{path}: invalid YAML ({exc})")


def require_mapping(obj: Any, path: str, errors: list[str]) -> dict[str, Any] | None:
    if not isinstance(obj, dict):
        errors.append(f"{path}: expected mapping/object")
        return None
    return obj


def require_list(obj: Any, path: str, errors: list[str]) -> list[Any] | None:
    if not isinstance(obj, list):
        errors.append(f"{path}: expected list/array")
        return None
    return obj


def require_keys(obj: dict[str, Any], path: str, keys: list[str], errors: list[str]) -> None:
    for key in keys:
        if key not in obj:
            errors.append(f"{path}.{key}: missing required key")


def require_repo_id(value: Any, path: str, errors: list[str]) -> None:
    if not isinstance(value, str) or not REPO_PATTERN.match(value):
        errors.append(f"{path}: expected OWNER/REPO string")


def require_non_empty_string(value: Any, path: str, errors: list[str]) -> None:
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{path}: expected non-empty string")


def require_state(value: Any, path: str, errors: list[str]) -> None:
    if not isinstance(value, str):
        errors.append(f"{path}: expected string state value")
        return
    if value not in ALLOWED_STATES:
        allowed = "|".join(sorted(ALLOWED_STATES))
        errors.append(f"{path}: invalid state '{value}' (allowed: {allowed})")


def validate_registry(data: Any, path: str, errors: list[str]) -> None:
    root = require_mapping(data, path, errors)
    if root is None:
        return

    require_keys(root, path, ["metadata", "state_model", "repositories"], errors)

    metadata = require_mapping(root.get("metadata"), f"{path}.metadata", errors)
    if metadata is not None:
        require_keys(
            metadata,
            f"{path}.metadata",
            ["version", "last_updated", "canonical_source", "governing_policy_ref"],
            errors,
        )

    state_model = require_mapping(root.get("state_model"), f"{path}.state_model", errors)
    if state_model is not None:
        for state in sorted(ALLOWED_STATES):
            if state not in state_model:
                errors.append(f"{path}.state_model.{state}: missing required state definition")
                continue
            state_obj = require_mapping(state_model.get(state), f"{path}.state_model.{state}", errors)
            if state_obj is not None:
                require_keys(state_obj, f"{path}.state_model.{state}", ["description"], errors)

    repositories = require_list(root.get("repositories"), f"{path}.repositories", errors)
    if repositories is None:
        return
    if len(repositories) == 0:
        errors.append(f"{path}.repositories: must contain at least one repository entry")
        return

    seen_repos: set[str] = set()
    for idx, item in enumerate(repositories):
        item_path = f"{path}.repositories[{idx}]"
        repo_entry = require_mapping(item, item_path, errors)
        if repo_entry is None:
            continue

        require_keys(repo_entry, item_path, ["repo", "family", "state", "owner_role", "marker_path"], errors)

        repo_id = repo_entry.get("repo")
        require_repo_id(repo_id, f"{item_path}.repo", errors)
        if isinstance(repo_id, str):
            if repo_id in seen_repos:
                errors.append(f"{item_path}.repo: duplicate repository '{repo_id}'")
            seen_repos.add(repo_id)

        require_state(repo_entry.get("state"), f"{item_path}.state", errors)
        require_non_empty_string(repo_entry.get("family"), f"{item_path}.family", errors)
        require_non_empty_string(repo_entry.get("owner_role"), f"{item_path}.owner_role", errors)
        require_non_empty_string(repo_entry.get("marker_path"), f"{item_path}.marker_path", errors)


def validate_marker(data: Any, path: str, errors: list[str]) -> None:
    root = require_mapping(data, path, errors)
    if root is None:
        return

    require_keys(root, path, ["schema_version", "repository", "governance", "controls", "evidence"], errors)
    require_repo_id(root.get("repository"), f"{path}.repository", errors)

    governance = require_mapping(root.get("governance"), f"{path}.governance", errors)
    if governance is not None:
        require_keys(
            governance,
            f"{path}.governance",
            ["owner_system", "owner_repo", "state", "registry_ref", "policy_ref"],
            errors,
        )
        require_non_empty_string(governance.get("owner_system"), f"{path}.governance.owner_system", errors)
        require_repo_id(governance.get("owner_repo"), f"{path}.governance.owner_repo", errors)
        require_state(governance.get("state"), f"{path}.governance.state", errors)
        require_non_empty_string(governance.get("registry_ref"), f"{path}.governance.registry_ref", errors)
        require_non_empty_string(governance.get("policy_ref"), f"{path}.governance.policy_ref", errors)

    controls = require_mapping(root.get("controls"), f"{path}.controls", errors)
    if controls is not None:
        require_keys(controls, f"{path}.controls", ["profile", "required_reviews"], errors)
        require_state(controls.get("profile"), f"{path}.controls.profile", errors)

        reviews = require_list(controls.get("required_reviews"), f"{path}.controls.required_reviews", errors)
        if reviews is not None:
            if len(reviews) == 0:
                errors.append(f"{path}.controls.required_reviews: must contain at least one reviewer")
            for idx, review in enumerate(reviews):
                require_non_empty_string(review, f"{path}.controls.required_reviews[{idx}]", errors)

    evidence = require_mapping(root.get("evidence"), f"{path}.evidence", errors)
    if evidence is not None:
        require_keys(evidence, f"{path}.evidence", ["adoption_issue"], errors)
        require_non_empty_string(evidence.get("adoption_issue"), f"{path}.evidence.adoption_issue", errors)


def validate_cross_consistency(
    registry: Any,
    marker: Any,
    registry_path: str,
    marker_path: str,
    errors: list[str],
) -> None:
    registry_root = require_mapping(registry, registry_path, errors)
    marker_root = require_mapping(marker, marker_path, errors)
    if registry_root is None or marker_root is None:
        return

    repositories = registry_root.get("repositories")
    if not isinstance(repositories, list):
        return

    marker_repo = marker_root.get("repository")
    if not isinstance(marker_repo, str):
        return

    match = None
    for item in repositories:
        if isinstance(item, dict) and item.get("repo") == marker_repo:
            match = item
            break

    if match is None:
        errors.append(
            f"{marker_path}.repository: '{marker_repo}' not found in {registry_path}.repositories"
        )
        return

    marker_governance = marker_root.get("governance")
    if isinstance(marker_governance, dict):
        marker_state = marker_governance.get("state")
        registry_state = match.get("state")
        if isinstance(marker_state, str) and isinstance(registry_state, str) and marker_state != registry_state:
            errors.append(
                f"{marker_path}.governance.state: '{marker_state}' does not match "
                f"{registry_path}.repositories state '{registry_state}' for {marker_repo}"
            )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate governance ownership YAML artifacts."
    )
    parser.add_argument(
        "--registry",
        default="00-os/governed-repos.yml",
        help="Path to governed repository registry YAML file.",
    )
    parser.add_argument(
        "--marker",
        default=".context-engineering/governance.yml",
        help="Path to local repository governance marker YAML file.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    registry_path = pathlib.Path(args.registry)
    marker_path = pathlib.Path(args.marker)

    errors: list[str] = []

    try:
        registry_data = load_yaml(registry_path)
    except ValueError as exc:
        errors.append(str(exc))
        registry_data = None

    try:
        marker_data = load_yaml(marker_path)
    except ValueError as exc:
        errors.append(str(exc))
        marker_data = None

    if registry_data is not None:
        validate_registry(registry_data, str(registry_path), errors)
    if marker_data is not None:
        validate_marker(marker_data, str(marker_path), errors)
    if registry_data is not None and marker_data is not None:
        validate_cross_consistency(
            registry_data,
            marker_data,
            str(registry_path),
            str(marker_path),
            errors,
        )

    if errors:
        print("Governance ownership validation failed:")
        for entry in errors:
            print(f"  - {entry}")
        return 1

    print(
        "Governance ownership validation passed "
        f"({registry_path}, {marker_path})."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
