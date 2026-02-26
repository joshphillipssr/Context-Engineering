# PR Metadata Validation Samples

These sample PR bodies are used to validate accepted issue-linkage paths for `00-os/scripts/validate-pr-metadata.py`.

## Included samples
- `valid-gh-issue-develop.md`: recommended branch path using `gh issue develop`.
- `valid-github-native-linkage.md`: alternate GitHub-native linkage path with documented Development-linkage exception evidence.
- `valid-adr-linked-protected-change.md`: architecture/protected-change sample including ADR linkage fields (`Primary-ADR`, `ADR-Status-At-Merge`, supersession traceability).

## Quick verification
```bash
python3 00-os/scripts/validate-pr-metadata.py --input-file 00-os/scripts/pr-metadata-samples/valid-gh-issue-develop.md
python3 00-os/scripts/validate-pr-metadata.py --input-file 00-os/scripts/pr-metadata-samples/valid-github-native-linkage.md
python3 00-os/scripts/validate-pr-metadata.py --input-file 00-os/scripts/pr-metadata-samples/valid-adr-linked-protected-change.md
```
