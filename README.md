# Codex Squad POC

Small project used to validate autonomous Codex workflows.

## Requirements

- Python 3.8 or newer

## Local setup

From the repository root, create and activate a virtual environment:

```powershell
python3 -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Install the development dependency used by the project:

```powershell
python3 -m pip install pytest
```

## Run the application

The project exposes its calculator functions as a Python module. Run this
example from the repository root:

```powershell
python3 -c "from src.calculator import add; print(add(2, 3))"
```

To run the automated test suite instead, use:

```powershell
python3 -m pytest
```

Ferrari auto-test-codex-squad-poc
Outro-teste-codex-squad-poc
Mais-um-teste-codex-squad-poc
