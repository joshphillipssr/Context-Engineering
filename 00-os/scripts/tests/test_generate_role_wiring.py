"""Unit tests for role wiring generation and secret-name validation."""

import importlib.util
from pathlib import Path
import unittest


MODULE_PATH = Path(__file__).resolve().parents[1] / "generate-role-wiring.py"
SPEC = importlib.util.spec_from_file_location("generate_role_wiring", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class SecretNameValidationTests(unittest.TestCase):
    def test_accepts_uppercase_secret_name(self):
        MODULE.validate_secret_name_field(
            "implementation-specialist",
            "private_key_secret",
            "IMPLEMENTATION_SPECIALIST_APP_PRIVATE_KEY",
        )

    def test_rejects_multiline_secret_name(self):
        with self.assertRaisesRegex(ValueError, "single-line"):
            MODULE.validate_secret_name_field(
                "implementation-specialist",
                "private_key_secret",
                "IMPLEMENTATION_SPECIALIST_APP_PRIVATE_KEY\nANOTHER_LINE",
            )

    def test_rejects_private_key_material(self):
        with self.assertRaisesRegex(ValueError, "private key material"):
            MODULE.validate_secret_name_field(
                "implementation-specialist",
                "private_key_secret",
                "-----BEGIN PRIVATE KEY-----",
            )

    def test_rejects_github_token_value(self):
        with self.assertRaisesRegex(ValueError, "GitHub token-like value"):
            MODULE.validate_secret_name_field(
                "implementation-specialist",
                "private_key_secret",
                "ghp_123456789012345678901234567890123456",
            )

    def test_rejects_non_uppercase_secret_name(self):
        with self.assertRaisesRegex(ValueError, "must match"):
            MODULE.validate_secret_name_field(
                "implementation-specialist",
                "private_key_secret",
                "Implementation_Specialist_App_Private_Key",
            )


class WorkflowGenerationTests(unittest.TestCase):
    def setUp(self):
        self.roles = [
            {
                "slug": "implementation-specialist",
                "repo_name": "context-engineering-role-implementation-specialist",
                "github_app": {
                    "app_id_value": 2852927,
                    "app_id_secret": "IMPLEMENTATION_SPECIALIST_APP_ID",
                    "private_key_secret": "IMPLEMENTATION_SPECIALIST_APP_PRIVATE_KEY",
                    "installation_id_secret": "IMPLEMENTATION_SPECIALIST_APP_INSTALLATION_ID",
                },
            },
            {
                "slug": "compliance-officer",
                "repo_name": "context-engineering-role-compliance-officer",
                "github_app": {
                    "app_id_value": 2853078,
                    "app_id_secret": "COMPLIANCE_OFFICER_APP_ID",
                    "private_key_secret": "COMPLIANCE_OFFICER_APP_PRIVATE_KEY",
                    "installation_id_secret": "COMPLIANCE_OFFICER_APP_INSTALLATION_ID",
                },
            },
        ]

    def test_sync_matrix_uses_app_id_value_not_secret_names(self):
        matrix = MODULE.generate_workflow_sync_matrix(self.roles)
        self.assertIn("app_id_value: 2852927", matrix)
        self.assertIn("app_id_value: 2853078", matrix)
        self.assertNotIn("app_id_secret", matrix)
        self.assertNotIn("private_key_secret", matrix)

    def test_app_token_steps_use_static_secret_refs(self):
        steps = MODULE.generate_workflow_app_token_steps(self.roles)
        self.assertIn("private-key: ${{ secrets.IMPLEMENTATION_SPECIALIST_APP_PRIVATE_KEY }}", steps)
        self.assertIn("private-key: ${{ secrets.COMPLIANCE_OFFICER_APP_PRIVATE_KEY }}", steps)
        self.assertNotIn("secrets[matrix.", steps)


if __name__ == "__main__":
    unittest.main()
