---
name: testing
description: Validate software changes using the repository's existing testing strategy and tooling.
---

# Testing Skill

## Purpose

Validate software changes using the repository's existing testing strategy
and tooling.

## When to use

Use this skill when:

- Code changes require validation.
- New functionality requires automated tests.
- Existing tests may be affected.
- The issue explicitly requires testing.

## When not to use

Do not use this skill when:

- No executable or testable behavior is affected.
- The repository contains no applicable testable component.

## Responsibilities

The agent using this skill must:

- Identify the project's existing test framework and tooling.
- Inspect existing test conventions before creating new tests.
- Prefer existing project tooling over introducing new tooling.
- Add or update tests when appropriate.
- Execute the relevant test suite.
- Report test failures accurately.

## Constraints

The agent must not:

- Replace the project's test framework without justification.
- Introduce a new test dependency when an existing solution is available.
- Claim tests passed when they were not executed.
- Ignore test failures.
- Modify production code solely to hide a failing test.

## Workflow

1. Identify the project's language and test framework.
2. Inspect existing tests and test configuration.
3. Determine the appropriate validation commands.
4. Add or update tests when necessary.
5. Execute the relevant tests.
6. Investigate failures.
7. Re-run the tests after fixes.

## Validation

Record:

- Test command executed.
- Test result.
- Relevant failures, if any.

## Completion criteria

The skill is complete when:

- Relevant tests have been identified.
- Required tests have been executed.
- Test results are known.
- Failures are either resolved or explicitly reported as blocking issues.