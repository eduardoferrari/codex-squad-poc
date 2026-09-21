---
name: documentation
description: Create and maintain project documentation while preserving technical accuracy and consistency with the existing repository.
---

# Documentation Skill

## Purpose

Create and maintain project documentation while preserving technical
accuracy and consistency with the existing repository.

## When to use

Use this skill when:

- The issue requires documentation changes.
- Existing documentation is incomplete or incorrect.
- Usage instructions need to be added or updated.

## When not to use

Do not use this skill when:

- The issue does not require documentation changes.
- Documentation changes would be unrelated to the requested task.

## Responsibilities

The agent using this skill must:

- Inspect existing documentation before modifying it.
- Follow the repository's documentation conventions.
- Keep instructions consistent with the actual implementation.
- Make focused documentation changes.

## Constraints

The agent must not:

- Modify application code unnecessarily.
- Invent commands, configuration, or behavior.
- Rewrite unrelated documentation.

## Workflow

1. Identify the documentation affected by the issue.
2. Inspect the existing documentation and relevant implementation.
3. Determine the required documentation changes.
4. Update the documentation.
5. Verify that documented commands and configuration match the repository.

## Validation

Before considering this skill complete:

- Documentation reflects the current implementation.
- Commands and configuration examples are valid.
- No unrelated documentation was modified.

## Completion criteria

The requested documentation is complete, accurate, and consistent with
the repository.