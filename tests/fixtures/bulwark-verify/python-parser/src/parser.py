import csv
from pathlib import Path
from typing import Any
from statistics import mean, median, stdev


class CSVError(Exception):
    pass


def load_csv(file_path: str) -> list[dict[str, Any]]:
    path = Path(file_path)

    if not path.exists():
        raise CSVError(f"File not found: {file_path}")

    if path.suffix.lower() != '.csv':
        raise CSVError(f"Not a CSV file: {file_path}")

    try:
        with open(path, 'r', newline='') as f:
            reader = csv.DictReader(f)
            return list(reader)
    except csv.Error as e:
        raise CSVError(f"CSV parse error: {e}")


def filter_rows(data: list[dict], column: str, value: Any) -> list[dict]:
    return [row for row in data if row.get(column) == str(value)]


def aggregate(data: list[dict], column: str, func: str) -> float:
    values = []
    for row in data:
        try:
            values.append(float(row[column]))
        except (KeyError, ValueError):
            continue

    if not values:
        raise CSVError(f"No numeric values in column: {column}")

    if func == 'sum':
        return sum(values)
    elif func == 'mean':
        return mean(values)
    elif func == 'median':
        return median(values)
    elif func == 'min':
        return min(values)
    elif func == 'max':
        return max(values)
    elif func == 'stdev':
        if len(values) < 2:
            raise CSVError("Need at least 2 values for stdev")
        return stdev(values)
    else:
        raise CSVError(f"Unknown function: {func}")


def group_by(data: list[dict], column: str) -> dict[str, list[dict]]:
    groups = {}
    for row in data:
        key = row.get(column, '')
        if key not in groups:
            groups[key] = []
        groups[key].append(row)
    return groups
