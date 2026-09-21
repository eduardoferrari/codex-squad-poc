---
name: code-review
description: Review the implemented changes for correctness, regressions, maintainability, security concerns, and adherence to repository conventions.
---

# Code Review Skill

## Purpose

Review the implemented changes for correctness, regressions, maintainability,
security concerns, and adherence to repository conventions.

## When to use

Use this skill when:

- A code change has been implemented.
- The task requires review before completion.
- The implementation is sufficiently complete to inspect.

## When not to use

Do not use this skill when:

- No code or configuration changes exist to review.

## Responsibilities

The agent using this skill must:

- Inspect the complete diff.
- Verify that changes are within the issue scope.
- Check for regressions.
- Check adherence to repository conventions.
- Identify missing tests.
- Identify obvious correctness or security problems.

## Constraints

The agent must not:

- Perform unrelated refactoring.
- Change behavior solely based on subjective style preferences.
- Declare the implementation correct without inspecting the actual diff.

## Workflow

1. Inspect the repository status.
2. Inspect the complete diff.
3. Compare the implementation against the issue requirements.
4. Check tests and validation coverage.
5. Identify problems.
6. Fix blocking problems when appropriate.
7. Re-run relevant validation.

## Validation

The review must confirm:

- Requirements are addressed.
- Changes remain within scope.
- Relevant tests exist.
- Relevant validation has been performed.

## Completion criteria

The review is complete when:

- The complete diff has been inspected.
- No known blocking issue remains.
- Relevant validation has passed or remaining failures are explicitly reported.