#!/usr/bin/env python3
"""
Generate role wiring code from the canonical role registry.

This script reads 00-os/role-registry.yml and generates role-specific
wiring in workflows, compose files, and shell scripts.

Usage:
    python3 00-os/scripts/generate-role-wiring.py [--check]

Options:
    --check   Verify generated files match committed versions (CI mode)
"""

import sys
import argparse
from pathlib import Path
import yaml
import re
from typing import Dict, List, Any


SECRET_NAME_FIELDS = ("app_id_secret", "private_key_secret", "installation_id_secret")
SECRET_NAME_PATTERN = re.compile(r"^[A-Z][A-Z0-9_]*$")
LIKELY_SECRET_VALUE_PATTERNS = (
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----", re.IGNORECASE), "private key material"),
    (re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}\b"), "GitHub token-like value"),
    (re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}\b"), "GitHub fine-grained token-like value"),
)


def slug_to_constant(slug: str) -> str:
    """Convert a role slug like implementation-specialist to IMPLEMENTATION_SPECIALIST."""
    return slug.replace("-", "_").upper()


def slug_to_identifier(slug: str) -> str:
    """Convert a role slug like implementation-specialist to implementation_specialist."""
    return slug.replace("-", "_")


def validate_secret_name_field(role_slug: str, field_name: str, value: Any) -> None:
    """Validate that a role registry secret field contains only a secret name, not a secret value."""
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"Role '{role_slug}' has empty or non-string github_app.{field_name}")

    if "\n" in value or "\r" in value:
        raise ValueError(
            f"Role '{role_slug}' github_app.{field_name} must be a single-line secret name"
        )

    for pattern, description in LIKELY_SECRET_VALUE_PATTERNS:
        if pattern.search(value):
            raise ValueError(
                f"Role '{role_slug}' github_app.{field_name} appears to contain {description}; "
                "store only the secret name"
            )

    if not SECRET_NAME_PATTERN.fullmatch(value):
        raise ValueError(
            f"Role '{role_slug}' github_app.{field_name} must match {SECRET_NAME_PATTERN.pattern}"
        )


def validate_registry_roles(roles: List[Dict[str, Any]]) -> None:
    """Fail fast when role registry secret-name fields contain unsafe values."""
    for role in roles:
        role_slug = role["slug"]
        github_app = role["github_app"]
        for field_name in SECRET_NAME_FIELDS:
            validate_secret_name_field(role_slug, field_name, github_app.get(field_name))


def load_registry(repo_root: Path) -> Dict[str, Any]:
    """Load the canonical role registry."""
    registry_path = repo_root / "00-os" / "role-registry.yml"
    with open(registry_path, 'r') as f:
        return yaml.safe_load(f)


def generate_workflow_sync_matrix(roles: List[Dict]) -> str:
    """Generate the matrix include section for sync-role-repos.yml"""
    lines = []
    for role in roles:
        lines.append(f"          - role_slug: {role['slug']}")
        lines.append(f"            repo_name: {role['repo_name']}")
        lines.append(f"            app_id_value: {role['github_app']['app_id_value']}")
    return "\n".join(lines)


def generate_workflow_app_token_steps(roles: List[Dict]) -> str:
    """Generate per-role app token creation steps with static secret references."""
    lines = []

    for role in roles:
        slug = role["slug"]
        slug_identifier = slug_to_identifier(slug)
        slug_constant = slug_to_constant(slug)

        lines.append(f"      - name: Create role GitHub App token ({slug})")
        lines.append(
            "        if: ${{ steps.role_filter.outputs.run_sync == 'true' && "
            "matrix.role_slug == '" + slug + "' }}"
        )
        lines.append(f"        id: app_token_{slug_identifier}")
        lines.append("        uses: actions/create-github-app-token@v1")
        lines.append("        with:")
        lines.append("          app-id: ${{ matrix.app_id_value }}")
        lines.append(f"          private-key: ${{{{ secrets.{slug_constant}_APP_PRIVATE_KEY }}}}")
        lines.append("          owner: ${{ steps.owner.outputs.owner }}")
        lines.append("          repositories: ${{ matrix.repo_name }}")

    lines.append("")
    lines.append("      - name: Consolidate role GitHub App token")
    lines.append("        if: ${{ steps.role_filter.outputs.run_sync == 'true' }}")
    lines.append("        id: app_token")
    lines.append("        env:")
    lines.append("          ROLE_SLUG: ${{ matrix.role_slug }}")
    for role in roles:
        slug_identifier = slug_to_identifier(role["slug"])
        lines.append(
            f"          TOKEN_{slug_identifier.upper()}: ${{{{ steps.app_token_{slug_identifier}.outputs.token }}}}"
        )
    lines.append("        run: |")
    lines.append("          set -euo pipefail")
    lines.append('          token=""')
    lines.append('          case "$ROLE_SLUG" in')
    for role in roles:
        slug = role["slug"]
        slug_identifier = slug_to_identifier(slug)
        lines.append(f"            {slug})")
        lines.append(f"              token=\"$TOKEN_{slug_identifier.upper()}\"")
        lines.append("              ;;")
    lines.append("            *)")
    lines.append('              echo "Unsupported role slug: $ROLE_SLUG"')
    lines.append("              exit 1")
    lines.append("              ;;")
    lines.append("          esac")
    lines.append('          if [ -z "$token" ]; then')
    lines.append('            echo "Failed to resolve GitHub App token for role $ROLE_SLUG"')
    lines.append("            exit 1")
    lines.append("          fi")
    lines.append('          echo "token=$token" >> "$GITHUB_OUTPUT"')

    return "\n".join(lines)


def generate_workflow_publish_matrix(roles: List[Dict]) -> str:
    """Generate the matrix include section for publish-role-workstation-images.yml"""
    lines = []
    for role in roles:
        lines.append(f"          - role_profile: {role['slug']}")
        lines.append(f"            image_suffix: {role['compose']['image_suffix']}")
        lines.append(f"            role_repo: {role['repo_name']}")
    return "\n".join(lines)


def generate_workflow_dispatch_choices(roles: List[Dict]) -> str:
    """Generate the role choice options for workflow_dispatch"""
    lines = ["          - all"]
    for role in sorted(roles, key=lambda r: r['menu_order']):
        lines.append(f"          - {role['slug']}")
    return "\n".join(lines)


def generate_shell_role_menu(roles: List[Dict]) -> str:
    """Generate the role selection menu for start-role-workstation.sh"""
    lines = []
    for role in sorted(roles, key=lambda r: r['menu_order']):
        lines.append(f'  echo "  {role["menu_order"]}) {role["menu_label"]}"')
    return "\n".join(lines)


def generate_shell_role_case_menu(roles: List[Dict]) -> str:
    """Generate the case statement for role selection in start-role-workstation.sh"""
    lines = []
    for role in sorted(roles, key=lambda r: r['menu_order']):
        lines.append(f'    {role["menu_order"]}) ROLE="{role["menu_label"]}" ;;')
    return "\n".join(lines)


def generate_shell_normalize_role_cases(roles: List[Dict]) -> str:
    """Generate normalize_role case statements"""
    lines = []
    for role in sorted(roles, key=lambda r: r['menu_order']):
        alternatives = [role['menu_label']]
        if role['slug'] != role['menu_label']:
            alternatives.append(role['slug'])
        case_pattern = "|".join(alternatives)
        lines.append(f'    {case_pattern}) echo "{role["menu_label"]}" ;;')
    return "\n".join(lines)


def generate_shell_role_mapping_cases(roles: List[Dict]) -> str:
    """Generate the role variable mapping case statement"""
    lines = []
    for role in sorted(roles, key=lambda r: r['menu_order']):
        profile_line = f'"{role["compose"]["profile"]}"' if role["compose"]["profile"] else '""'
        lines.append(f'  {role["menu_label"]})')
        lines.append(f'    ROLE_PROFILE="{role["slug"]}"')
        lines.append(f'    SERVICE_NAME="{role["compose"]["service_name"]}"')
        lines.append(f'    PROFILE_NAME={profile_line}')
        lines.append(f'    ROLE_ENV_PREFIX="{role["github_app"]["env_prefix"]}"')
        lines.append('    ;;')
    return "\n".join(lines)


def generate_compose_services(roles: List[Dict]) -> str:
    """Generate docker-compose service definitions"""
    services = []
    for role in sorted(roles, key=lambda r: r['menu_order']):
        svc = []
        svc.append(f"  {role['compose']['service_name']}:")
        svc.append("    build:")
        svc.append("      context: ..")
        svc.append("      dockerfile: .devcontainer-workstation/Dockerfile")
        svc.append("      args:")
        svc.append(f"        IMAGE_ROLE_PROFILE: {role['slug']}")
        svc.append(f"    container_name: {role['compose']['service_name']}")
        
        if role['compose']['profile']:
            svc.append("    profiles:")
            svc.append(f"      - {role['compose']['profile']}")
        
        prefix = role['compose']['volume_prefix']
        svc.append("    volumes:")
        svc.append(f"      - {prefix}_projects_data:/workspace")
        svc.append(f"      - {prefix}_gh_config:/root/.config/gh")
        svc.append(f"      - {prefix}_git_config:/root/.config/git")
        svc.append("      # - ssh_data:/root/.ssh")
        svc.append(f"      - {prefix}_codex_home:/root/.codex")
        svc.append("      # Optional: forward host SSH agent into container for commit signing.")
        svc.append("      # Set HOST_SSH_AGENT_SOCK before compose up.")
        svc.append("      # - type: bind")
        svc.append("      #  source: ${HOST_SSH_AGENT_SOCK:-/tmp/codex-no-ssh-agent}")
        svc.append("      #  target: /ssh-agent")
        
        svc.append("    environment:")
        svc.append("      - GH_BOOTSTRAP_TOKEN=${GH_BOOTSTRAP_TOKEN:-}")
        svc.append("      - OPENAI_API_KEY=${OPENAI_API_KEY:-}")
        svc.append("      - WORKSTATION_DEBUG=${WORKSTATION_DEBUG:-false}")
        svc.append("      - CODEX_HOME=/root/.codex")
        svc.append("      # - SSH_AUTH_SOCK=/ssh-agent")
        
        # ROLE_PROFILE: first service has env var override, others are fixed
        if not role['compose']['profile']:
            svc.append(f'      - ROLE_PROFILE=${{ROLE_PROFILE:-{role["slug"]}}}')
        else:
            svc.append(f'      - ROLE_PROFILE={role["slug"]}')
        
        env_prefix = role['github_app']['env_prefix']
        app_id = role['github_app']['app_id_value']
        inst_id = role['github_app']['installation_id_value']
        
        svc.append(f'      - ROLE_GITHUB_AUTH_MODE=${{{env_prefix}_ROLE_GITHUB_AUTH_MODE:-app}}')
        svc.append(f'      - ROLE_GITHUB_APP_ID=${{{env_prefix}_ROLE_GITHUB_APP_ID:-{app_id}}}')
        svc.append(f'      - ROLE_GITHUB_APP_INSTALLATION_ID=${{{env_prefix}_ROLE_GITHUB_APP_INSTALLATION_ID:-{inst_id}}}')
        svc.append(f'      - ROLE_GITHUB_APP_PRIVATE_KEY_PATH=${{{env_prefix}_ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-}}')
        svc.append('      - WORKSPACE_REPO_OWNER=${WORKSPACE_REPO_OWNER:-Josh-Phillips-LLC}')
        svc.append(f'      - WORKSPACE_REPO_URL=${{{env_prefix}_WORKSPACE_REPO_URL:-https://github.com/Josh-Phillips-LLC/{role["repo_name"]}.git}}')
        svc.append(f'      - WORKSPACE_REPO_DIR=/workspace/Projects/${{{env_prefix}_WORKSPACE_REPO_DIR_NAME:-{role["repo_name"]}}}')
        svc.append('      - AUTO_CLONE_WORKSPACE_REPO=${AUTO_CLONE_WORKSPACE_REPO:-true}')
        svc.append('      - ALLOW_FALLBACK_INSTRUCTIONS=${ALLOW_FALLBACK_INSTRUCTIONS:-false}')
        svc.append("")
        svc.append("    # Testing-mode autonomy")
        svc.append("    cap_add:")
        svc.append("      - ALL")
        svc.append("    privileged: true")
        svc.append("    init: true")
        svc.append('    entrypoint: ["/usr/local/bin/init-workstation.sh"]')
        svc.append('    command: ["sleep", "infinity"]')
        
        services.append("\n".join(svc))
    
    return "\n\n".join(services)


def generate_compose_ghcr_services(roles: List[Dict]) -> str:
    """Generate docker-compose.ghcr.yml service definitions"""
    services = []
    for role in sorted(roles, key=lambda r: r['menu_order']):
        svc = []
        svc.append(f"  {role['compose']['service_name']}:")
        svc.append(
            "    image: ghcr.io/${GHCR_OWNER:-josh-phillips-llc}/${GHCR_IMAGE_PREFIX:-context-engineering-workstation}"
            f"-{role['compose']['image_suffix']}:${{GHCR_IMAGE_TAG:-latest}}"
        )
        svc.append(f"    container_name: {role['compose']['service_name']}")
        svc.append("    pull_policy: always")

        if role['compose']['profile']:
            svc.append("    profiles:")
            svc.append(f"      - {role['compose']['profile']}")

        prefix = role['compose']['volume_prefix']
        svc.append("    volumes:")
        svc.append(f"      - {prefix}_projects_data:/workspace")
        svc.append(f"      - {prefix}_gh_config:/root/.config/gh")
        svc.append(f"      - {prefix}_git_config:/root/.config/git")
        svc.append(f"      - {prefix}_codex_home:/root/.codex")
        svc.append("    environment:")
        svc.append("      - GH_BOOTSTRAP_TOKEN=${GH_BOOTSTRAP_TOKEN:-}")
        svc.append("      - OPENAI_API_KEY=${OPENAI_API_KEY:-}")
        svc.append("      - WORKSTATION_DEBUG=${WORKSTATION_DEBUG:-false}")
        svc.append("      - CODEX_HOME=/root/.codex")

        if not role['compose']['profile']:
            svc.append(f'      - ROLE_PROFILE=${{ROLE_PROFILE:-{role["slug"]}}}')
        else:
            svc.append(f'      - ROLE_PROFILE={role["slug"]}')

        env_prefix = role['github_app']['env_prefix']
        app_id = role['github_app']['app_id_value']
        inst_id = role['github_app']['installation_id_value']

        svc.append(f'      - ROLE_GITHUB_AUTH_MODE=${{{env_prefix}_ROLE_GITHUB_AUTH_MODE:-app}}')
        svc.append(f'      - ROLE_GITHUB_APP_ID=${{{env_prefix}_ROLE_GITHUB_APP_ID:-{app_id}}}')
        svc.append(f'      - ROLE_GITHUB_APP_INSTALLATION_ID=${{{env_prefix}_ROLE_GITHUB_APP_INSTALLATION_ID:-{inst_id}}}')
        svc.append(f'      - ROLE_GITHUB_APP_PRIVATE_KEY_PATH=${{{env_prefix}_ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-}}')
        svc.append('      - WORKSPACE_REPO_OWNER=${WORKSPACE_REPO_OWNER:-Josh-Phillips-LLC}')
        svc.append(f'      - WORKSPACE_REPO_URL=${{{env_prefix}_WORKSPACE_REPO_URL:-https://github.com/Josh-Phillips-LLC/{role["repo_name"]}.git}}')
        svc.append(f'      - WORKSPACE_REPO_DIR=/workspace/Projects/${{{env_prefix}_WORKSPACE_REPO_DIR_NAME:-{role["repo_name"]}}}')
        svc.append('      - AUTO_CLONE_WORKSPACE_REPO=${AUTO_CLONE_WORKSPACE_REPO:-true}')
        svc.append('      - ALLOW_FALLBACK_INSTRUCTIONS=${ALLOW_FALLBACK_INSTRUCTIONS:-false}')
        svc.append("")
        svc.append("    cap_add:")
        svc.append("      - ALL")
        svc.append("    privileged: true")
        svc.append("    init: true")
        svc.append('    entrypoint: ["/usr/local/bin/init-workstation.sh"]')
        svc.append('    command: ["sleep", "infinity"]')

        services.append("\n".join(svc))

    return "\n\n".join(services)


def generate_compose_volumes(roles: List[Dict]) -> str:
    """Generate docker-compose volume declarations"""
    volumes = []
    for role in sorted(roles, key=lambda r: r['menu_order']):
        prefix = role['compose']['volume_prefix']
        volumes.append(f"  {prefix}_projects_data:")
        volumes.append(f"  {prefix}_gh_config:")
        volumes.append(f"  {prefix}_git_config:")
        volumes.append(f"  {prefix}_codex_home:")
    return "\n".join(volumes)


def replace_generated_block(content: str, marker: str, new_content: str) -> str:
    """Replace content between GENERATED:BEGIN and GENERATED:END markers"""
    begin_marker = f"# GENERATED:BEGIN:{marker}"
    end_marker = f"# GENERATED:END:{marker}"
    
    # Use simple non-greedy match between exact marker pairs
    # Since marker names are unique, this correctly handles even overlapping prefixes
    pattern = re.compile(
        rf"({re.escape(begin_marker)})(.*?)({re.escape(end_marker)})",
        re.DOTALL
    )
    
    match = pattern.search(content)
    if not match:
        raise ValueError(f"Markers not found: {begin_marker} ... {end_marker}")
    
    replacement = f"{begin_marker}\n{new_content}\n{end_marker}"
    
    # Use sub to replace the matched content
    return pattern.sub(replacement, content, count=1)


def update_file_with_generated(
    file_path: Path, 
    marker: str, 
    new_content: str,
    check_mode: bool = False
) -> bool:
    """Update a file's generated section. Returns True if changes were made."""
    content = file_path.read_text()
    updated = replace_generated_block(content, marker, new_content)
    
    if check_mode:
        if content != updated:
            print(f"FAIL: {file_path} has uncommitted generated changes")
            return True
        return False
    else:
        if content != updated:
            file_path.write_text(updated)
            print(f"Updated: {file_path}")
            return True
        else:
            print(f"No change: {file_path}")
            return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true',
                        help='Verify generated files match committed versions')
    args = parser.parse_args()
    
    repo_root = Path(__file__).parent.parent.parent
    registry = load_registry(repo_root)
    roles = registry['roles']

    validate_registry_roles(roles)
    
    print(f"Loaded {len(roles)} roles from registry")
    
    updates = []
    
    # Update sync-role-repos.yml workflow
    sync_workflow = repo_root / ".github" / "workflows" / "sync-role-repos.yml"
    sync_matrix = generate_workflow_sync_matrix(roles)
    sync_choices = generate_workflow_dispatch_choices(roles)
    sync_app_token_steps = generate_workflow_app_token_steps(roles)
    changed = update_file_with_generated(sync_workflow, "ROLE_MATRIX", sync_matrix, args.check)
    updates.append(("sync matrix", changed))
    changed = update_file_with_generated(sync_workflow, "ROLE_CHOICES", sync_choices, args.check)
    updates.append(("sync choices", changed))
    changed = update_file_with_generated(sync_workflow, "ROLE_APP_TOKEN_STEPS", sync_app_token_steps, args.check)
    updates.append(("sync app token steps", changed))
    
    # Update publish-role-workstation-images.yml workflow
    publish_workflow = repo_root / ".github" / "workflows" / "publish-role-workstation-images.yml"
    publish_matrix = generate_workflow_publish_matrix(roles)
    changed = update_file_with_generated(publish_workflow, "ROLE_MATRIX", publish_matrix, args.check)
    updates.append(("publish matrix", changed))
    
    # Update start-role-workstation.sh script
    start_script = repo_root / ".devcontainer-workstation" / "scripts" / "start-role-workstation.sh"
    menu = generate_shell_role_menu(roles)
    menu_case = generate_shell_role_case_menu(roles)
    normalize_cases = generate_shell_normalize_role_cases(roles)
    mapping_cases = generate_shell_role_mapping_cases(roles)
    
    changed = update_file_with_generated(start_script, "ROLE_MENU", menu, args.check)
    updates.append(("shell menu", changed))
    changed = update_file_with_generated(start_script, "ROLE_MENU_CASE", menu_case, args.check)
    updates.append(("shell menu case", changed))
    changed = update_file_with_generated(start_script, "NORMALIZE_ROLE_CASES", normalize_cases, args.check)
    updates.append(("shell normalize", changed))
    changed = update_file_with_generated(start_script, "ROLE_MAPPING_CASES", mapping_cases, args.check)
    updates.append(("shell mapping", changed))
    
    # Update docker-compose.yml
    compose_file = repo_root / ".devcontainer-workstation" / "docker-compose.yml"
    services = generate_compose_services(roles)
    volumes = generate_compose_volumes(roles)
    
    changed = update_file_with_generated(compose_file, "SERVICES", services, args.check)
    updates.append(("compose services", changed))
    changed = update_file_with_generated(compose_file, "VOLUMES", volumes, args.check)
    updates.append(("compose volumes", changed))

    # Update docker-compose.ghcr.yml
    compose_ghcr_file = repo_root / ".devcontainer-workstation" / "docker-compose.ghcr.yml"
    ghcr_services = generate_compose_ghcr_services(roles)
    changed = update_file_with_generated(compose_ghcr_file, "SERVICES", ghcr_services, args.check)
    updates.append(("compose ghcr services", changed))
    changed = update_file_with_generated(compose_ghcr_file, "VOLUMES", volumes, args.check)
    updates.append(("compose ghcr volumes", changed))
    
    if args.check:
        failures = [name for name, changed in updates if changed]
        if failures:
            print(f"\nERROR: {len(failures)} generated sections are out of sync:")
            for name in failures:
                print(f"  - {name}")
            print("\nRun: python3 00-os/scripts/generate-role-wiring.py")
            sys.exit(1)
        else:
            print("\nSUCCESS: All generated sections are up to date")
    else:
        changed_count = sum(1 for _, changed in updates if changed)
        print(f"\nGeneration complete: {changed_count} of {len(updates)} sections updated")


if __name__ == "__main__":
    main()
