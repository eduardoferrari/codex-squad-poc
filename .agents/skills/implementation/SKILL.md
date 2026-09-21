---
name: implementation
description: Implement a GitHub issue in the repository, including tests and validation.
---

# Implementation Skill

## Purpose

Implement application changes required by a software engineering task while
preserving the existing architecture and behavior.

## When to use

Use this skill when:

- The issue requires modifying application code.
- The issue requires adding new functionality.
- The issue requires changing existing behavior.
- The issue requires fixing a defect in application code.

## When not to use

Do not use this skill when:

- The task is purely documentation-related.
- The task only requires investigation without code changes.
- The requested change is outside the repository scope.

## Responsibilities

The agent using this skill must:

- Understand the existing implementation before making changes.
- Follow the repository architecture and coding conventions.
- Make the smallest appropriate change.
- Preserve unrelated existing behavior.
- Add or update tests when required.
- Avoid unrelated refactoring.

## Constraints

The agent must not:

- Rewrite unrelated components.
- Introduce speculative abstractions.
- Modify unrelated files.
- Remove existing functionality unless explicitly required.
- Ignore repository instructions.

## Workflow

1. Inspect the relevant existing implementation.
2. Identify the smallest appropriate implementation change.
3. Implement the requested functionality.
4. Review the changes for correctness and scope.
5. Prepare the changes for validation.

## Validation

Before considering this skill complete:

- The implementation must be syntactically valid.
- The relevant project must build or otherwise validate successfully when applicable.
- Relevant tests must be added or updated when necessary.

## Completion criteria

The skill is complete when:

- The requested functionality is implemented.
- Existing unrelated behavior is preserved.
- The implementation follows repository conventions.
- The resulting changes are ready for testing and review.