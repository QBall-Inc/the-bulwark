"""Simple config file parser for testing verification scripts."""

import json
from pathlib import Path
from typing import Any


class ParseError(Exception):
    """Raised when parsing fails."""
    pass


def parse_config(file_path: str) -> dict[str, Any]:
    """Parse a JSON config file and return its contents.

    Args:
        file_path: Path to the config file

    Returns:
        Parsed config as a dictionary

    Raises:
        ParseError: If file doesn't exist or is invalid JSON
    """
    path = Path(file_path)

    if not path.exists():
        raise ParseError(f"Config file not found: {file_path}")

    try:
        with open(path, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        raise ParseError(f"Invalid JSON in {file_path}: {e}")

    if not isinstance(data, dict):
        raise ParseError(f"Config must be a JSON object, got {type(data).__name__}")

    return data


def get_config_value(config: dict[str, Any], key: str, default: Any = None) -> Any:
    """Get a value from config with dot notation support.

    Args:
        config: Parsed config dictionary
        key: Key to look up (supports dot notation like 'database.host')
        default: Default value if key not found

    Returns:
        The value at the key path, or default if not found
    """
    keys = key.split('.')
    value = config

    for k in keys:
        if isinstance(value, dict) and k in value:
            value = value[k]
        else:
            return default

    return value
