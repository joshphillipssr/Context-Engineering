"""Unit tests for PR metadata validation logic."""

import io
import importlib.util
import json
from pathlib import Path
import unittest
from unittest import mock


MODULE_PATH = Path(__file__).resolve().parents[1] / "validate-pr-metadata.py"
SPEC = importlib.util.spec_from_file_location("validate_pr_metadata", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)

SAMPLE_DIR = Path(__file__).resolve().parents[1] / "pr-metadata-samples"


def make_body(
    *,
    primary_role: str = "Implementation Specialist",
    reviewed_by_role: str = "Compliance Officer",
    executive_sponsor_approval: str = "Not-Required",
    primary_issue_ref: str = "Closes #88",
    development_linkage: str = "Exception",
    development_linkage_evidence: str = "Linked issue and PR timeline evidence.",
) -> str:
    return "\n".join(
        [
            f"Primary-Role: {primary_role}",
            f"Reviewed-By-Role: {reviewed_by_role}",
            f"Executive-Sponsor-Approval: {executive_sponsor_approval}",
            f"Primary-Issue-Ref: {primary_issue_ref}",
            f"Development-Linkage: {development_linkage}",
            f"Development-Linkage-Evidence: {development_linkage_evidence}",
        ]
    )


class ParsePrimaryIssueRefTests(unittest.TestCase):
    def test_parses_closes_issue_reference(self):
        self.assertEqual(MODULE.parse_primary_issue_ref("Closes #88"), ("Closes", 88))

    def test_parses_refs_issue_reference(self):
        self.assertEqual(MODULE.parse_primary_issue_ref("Refs #190"), ("Refs", 190))

    def test_rejects_invalid_issue_reference_format(self):
        self.assertIsNone(MODULE.parse_primary_issue_ref("Closes 88"))


class ValidateMetadataTests(unittest.TestCase):
    def test_missing_required_role_fields_fails(self):
        body = "\n".join(
            [
                "Reviewed-By-Role: Compliance Officer",
                "Executive-Sponsor-Approval: Not-Required",
                "Primary-Issue-Ref: Closes #88",
                "Development-Linkage: Exception",
                "Development-Linkage-Evidence: linked",
            ]
        )
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertIn(
            "Missing required PR metadata field 'Primary-Role' or empty value.",
            errors,
        )

    def test_invalid_primary_role_value_fails(self):
        body = make_body(primary_role="Reviewer")
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertIn(
            "Invalid value for 'Primary-Role': 'Reviewer'. Allowed: Executive Sponsor | AI Governance Manager | Compliance Officer | Business Analyst | Implementation Specialist | Systems Architect.",
            errors,
        )

    def test_invalid_primary_issue_ref_format_fails(self):
        body = make_body(primary_issue_ref="Close #88")
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertIn(
            "Invalid 'Primary-Issue-Ref' format. Use exactly one value in the form 'Closes #<ISSUE_NUMBER>' or 'Refs #<ISSUE_NUMBER>'.",
            errors,
        )

    def test_duplicate_primary_issue_ref_fails(self):
        body = make_body() + "\nPrimary-Issue-Ref: Refs #77"
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertIn(
            "Expected exactly one 'Primary-Issue-Ref' field; found 2.",
            errors,
        )

    def test_missing_development_linkage_fails(self):
        body = "\n".join(
            [
                "Primary-Role: Implementation Specialist",
                "Reviewed-By-Role: Compliance Officer",
                "Executive-Sponsor-Approval: Not-Required",
                "Primary-Issue-Ref: Closes #88",
                "Development-Linkage-Evidence: linked",
            ]
        )
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertIn(
            "Missing required field 'Development-Linkage'. Set it to 'Verified' or 'Exception'.",
            errors,
        )

    def test_invalid_development_linkage_value_fails(self):
        body = make_body(development_linkage="Unknown")
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertIn(
            "Invalid 'Development-Linkage' value. Allowed: Verified | Exception.",
            errors,
        )

    def test_missing_development_linkage_evidence_fails(self):
        body = make_body() + "\nDevelopment-Linkage-Evidence:"
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertIn(
            "Expected exactly one 'Development-Linkage-Evidence' field; found 2.",
            errors,
        )

    def test_duplicate_primary_role_field_fails(self):
        body = make_body() + "\nPrimary-Role: Executive Sponsor"
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertIn(
            "Expected exactly one 'Primary-Role' field; found 2.",
            errors,
        )

    def test_valid_sample_body_passes(self):
        body = (SAMPLE_DIR / "valid-gh-issue-develop.md").read_text(encoding="utf-8")
        errors = MODULE.validate(body=body, repo=None, pr_number=None, github_token=None)
        self.assertEqual([], errors)


class QueryIssuePrLinkageTests(unittest.TestCase):
    class _FakeResponse(io.BytesIO):
        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            self.close()
            return False

    def test_paginate_timeline_until_pr_link_found(self):
        first_page = {
            "data": {
                "repository": {
                    "pullRequest": {"closingIssuesReferences": {"nodes": [{"number": 88}]}},
                    "issue": {
                        "timelineItems": {
                            "nodes": [
                                {
                                    "__typename": "CrossReferencedEvent",
                                    "source": {
                                        "__typename": "PullRequest",
                                        "number": 42,
                                    },
                                }
                            ],
                            "pageInfo": {
                                "hasNextPage": True,
                                "endCursor": "cursor-1",
                            },
                        }
                    },
                }
            }
        }
        second_page = {
            "data": {
                "repository": {
                    "pullRequest": {"closingIssuesReferences": {"nodes": [{"number": 88}]}},
                    "issue": {
                        "timelineItems": {
                            "nodes": [
                                {
                                    "__typename": "CrossReferencedEvent",
                                    "source": {
                                        "__typename": "PullRequest",
                                        "number": 89,
                                    },
                                }
                            ],
                            "pageInfo": {
                                "hasNextPage": False,
                                "endCursor": None,
                            },
                        }
                    },
                }
            }
        }

        def fake_urlopen(request, timeout=20):
            del timeout
            payload = json.loads(request.data.decode("utf-8"))
            cursor = payload["variables"].get("timelineCursor")
            if cursor is None:
                document = first_page
            elif cursor == "cursor-1":
                document = second_page
            else:
                self.fail(f"Unexpected cursor: {cursor}")
            return self._FakeResponse(json.dumps(document).encode("utf-8"))

        with mock.patch.object(MODULE.urllib.request, "urlopen", side_effect=fake_urlopen):
            closes_primary_issue, development_linked = MODULE.query_issue_pr_linkage(
                repo="owner/repo",
                pr_number=89,
                issue_number=88,
                github_token="token",
            )

        self.assertTrue(closes_primary_issue)
        self.assertTrue(development_linked)


if __name__ == "__main__":
    unittest.main()
