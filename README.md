# Codex Squad POC

Small .NET console application used to validate autonomous Codex workflows.

## Requirements

- .NET SDK 10.0 or newer

## Run the application

From the repository root:

```bash
dotnet run --project src/CodexSquadPoc.csproj
```

The sample application prints the result of a calculator operation.

## Run the tests

Run the complete .NET test suite from the repository root:

```bash
dotnet test
```

The former Python implementation and pytest tests are retained under `legacy/`
for reference only. They are not part of the application or test workflow.
