#!/usr/bin/env python3
"""Upsert a freshly-fetched traffic/download window into a persistent history JSON.

The Bulwark traffic-stats workflow fetches the same rolling window every run
(GitHub traffic = last 14 days; npm range = last ~30 days). A naive append would
double-count the overlapping days. This script keys every record by ISO date
(YYYY-MM-DD) and upserts: the latest fetch for a given date wins. That makes the
merge idempotent and same-day-finalization-safe (today's count grows during the
day; the last write before purge is the one that sticks).

Two source shapes are handled explicitly (no auto-detect — CS2: no magic):

  --source github : window is the GitHub traffic API response. The per-day array
                    lives under --series-key (``clones`` or ``views``); each item
                    is {"timestamp": "<ISO datetime>", "count": int, "uniques": int}.
                    Stored as daily[date] = {"count": int, "uniques": int}.

  --source npm    : window is the npm downloads/range response. The per-day array
                    lives under ``downloads``; each item is
                    {"downloads": int, "day": "YYYY-MM-DD"}.
                    Stored as daily[date] = int.

Output is deterministic: history is dumped with sorted keys and a fixed indent,
and ``last_updated`` is set to the latest date present (NOT wall-clock time) so an
unchanged data set re-serializes byte-identically. That lets the workflow use
``git diff --quiet`` to skip no-op commits.

Usage:
  merge_history.py --history <path> --window <path> --source github \
      --metric clones --series-key clones --package QBall-Inc/the-bulwark
  merge_history.py --history <path> --window <path> --source npm \
      --metric downloads --package @qball-inc/the-bulwark
"""

import argparse
import json
import sys


def load_history(path, package, metric):
    """Load an existing history file, or return a fresh empty skeleton.

    First-run (file absent or empty) must not error — the orphan branch may not
    yet hold any data. A present-but-corrupt file is a hard error (fail fast,
    CS3) rather than a silent reset that would destroy prior history.
    """
    try:
        with open(path, "r", encoding="utf-8") as fh:
            text = fh.read().strip()
    except FileNotFoundError:
        return {"package": package, "metric": metric, "daily": {}, "last_updated": None}
    if not text:
        return {"package": package, "metric": metric, "daily": {}, "last_updated": None}
    data = json.loads(text)  # raises on corrupt JSON — intentional fail-fast
    data.setdefault("package", package)
    data.setdefault("metric", metric)
    data.setdefault("daily", {})
    data.setdefault("last_updated", None)
    return data


def upsert_github(daily, window, series_key):
    """Upsert GitHub traffic items keyed by the date portion of the timestamp."""
    items = window.get(series_key, [])
    for item in items:
        timestamp = item.get("timestamp", "")
        date = timestamp[:10]  # "2026-06-08T00:00:00Z" -> "2026-06-08"
        if not date:
            continue
        daily[date] = {"count": item.get("count", 0), "uniques": item.get("uniques", 0)}
    return daily


def upsert_npm(daily, window):
    """Upsert npm download items keyed by the ``day`` field."""
    items = window.get("downloads", [])
    for item in items:
        date = item.get("day", "")
        if not date:
            continue
        daily[date] = item.get("downloads", 0)
    return daily


def merge(args):
    history = load_history(args.history, args.package, args.metric)
    with open(args.window, "r", encoding="utf-8") as fh:
        window = json.load(fh)

    daily = history["daily"]
    if args.source == "github":
        if not args.series_key:
            sys.exit("ERROR: --series-key is required for --source github")
        daily = upsert_github(daily, window, args.series_key)
    elif args.source == "npm":
        daily = upsert_npm(daily, window)
    else:  # argparse choices already constrain this; defensive per CS3
        sys.exit(f"ERROR: unknown source '{args.source}'")

    history["daily"] = daily
    history["last_updated"] = max(daily) if daily else None

    with open(args.history, "w", encoding="utf-8") as fh:
        json.dump(history, fh, sort_keys=True, indent=2)
        fh.write("\n")  # trailing newline for clean diffs
    return history


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Upsert a traffic/download window into history JSON.")
    parser.add_argument("--history", required=True, help="Path to the persistent history JSON (created if absent).")
    parser.add_argument("--window", required=True, help="Path to the freshly-fetched window JSON.")
    parser.add_argument("--source", required=True, choices=["github", "npm"], help="Window response shape.")
    parser.add_argument("--metric", required=True, help="Metric name stored in the history (clones/views/downloads).")
    parser.add_argument("--series-key", help="Array key in a GitHub window (clones|views). Required for --source github.")
    parser.add_argument("--package", required=True, help="Package/repo identifier stored in the history.")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    history = merge(args)
    days = len(history["daily"])
    print(f"merged: {args.metric} -> {days} day(s) in history (last_updated={history['last_updated']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
