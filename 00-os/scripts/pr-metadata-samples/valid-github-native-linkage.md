# Summary
- Sample PR body using an alternate GitHub-native issue linkage path.

# Issue
- Linked issue (primary tracked issue):
- Primary-Issue-Ref: Refs #54
- Additional issue references (optional):
- Refs #88

# Issue Linkage (Outcome-Based, Required)
- [x] Exactly one primary tracked issue is declared using `Primary-Issue-Ref: Closes #<ISSUE_NUMBER>` or `Primary-Issue-Ref: Refs #<ISSUE_NUMBER>`
- [x] Primary issue shows this PR in GitHub Development before merge, or an explicit exception with compensating evidence is documented
- [x] `gh issue develop <ISSUE_NUMBER> --checkout` was used where practical (recommended, not mandatory)

# Development Linkage Evidence (Required)
- Development-Linkage: Exception
- Development-Linkage-Evidence: GitHub Development linkage was temporarily unavailable due to API lag; compensating evidence is the linked issue comment and PR timeline references.

# Machine-Readable Metadata (Required)
Primary-Role: Implementation Specialist
Reviewed-By-Role: Compliance Officer
Executive-Sponsor-Approval: Not-Required
