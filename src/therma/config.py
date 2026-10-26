"""Load project metadata without assuming any physical system parameters."""

import tomllib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ProjectConfig:
    """Non-physical project settings; physical configuration comes in later phases."""

    name: str
    description: str = ""


def load_config(path: str | Path) -> ProjectConfig:
    """Read a TOML project table, rejecting unknown keys and invalid values.

    Relative paths resolve against the caller's current working directory.
    Missing files and malformed TOML retain their standard Python exceptions.
    """
    with Path(path).open("rb") as stream:
        document = tomllib.load(stream)
    if set(document) != {"project"} or not isinstance(document["project"], dict):
        raise ValueError("Configuration must contain only a [project] table")
    project = document["project"]
    if set(project) - {"name", "description"}:
        raise ValueError("Unknown project configuration keys")
    name = project.get("name")
    description = project.get("description", "")
    if not isinstance(name, str) or not name.strip():
        raise ValueError("project.name must be a nonempty string")
    if not isinstance(description, str):
        raise ValueError("project.description must be a string")
    return ProjectConfig(name=name.strip(), description=description)
