from pathlib import Path


def test_readme_ends_with_repository_marker():
    readme = Path(__file__).parents[1] / "README.md"

    assert readme.read_text(encoding="utf-8").rstrip().splitlines()[-1] == (
        "Ferrari auto-test-codex-squad-poc"
    )
