"""Exercise configuration boundaries and the checked-in example."""

import tomllib
from pathlib import Path

import pytest

from therma.config import load_config

ROOT = Path(__file__).resolve().parents[1]


def test_example_config() -> None:
    config = load_config(ROOT / "configs/project.toml")
    assert config.name == "THERMA"
    assert config.description


def test_defaults_and_whitespace(tmp_path: Path) -> None:
    path = tmp_path / "project.toml"
    path.write_text('[project]\nname = " THERMA "\n', encoding="utf-8")
    config = load_config(path)
    assert config.name == "THERMA"
    assert config.description == ""


@pytest.mark.parametrize(
    "content",
    [
        "",
        '[project]\nname = ""',
        "[project]\nname = 12",
        '[project]\nname = "THERMA"\ndescription = false',
        '[project]\nname = "THERMA"\nunknown = 1',
        '[project]\nname = "THERMA"\n[unexpected]',
        'project = "THERMA"',
    ],
)
def test_invalid_config(tmp_path: Path, content: str) -> None:
    path = tmp_path / "invalid.toml"
    path.write_text(content, encoding="utf-8")
    with pytest.raises(ValueError):
        load_config(path)


def test_missing_file(tmp_path: Path) -> None:
    with pytest.raises(FileNotFoundError):
        load_config(tmp_path / "missing.toml")


def test_malformed_toml(tmp_path: Path) -> None:
    path = tmp_path / "broken.toml"
    path.write_text("[project", encoding="utf-8")
    with pytest.raises(tomllib.TOMLDecodeError):
        load_config(path)
