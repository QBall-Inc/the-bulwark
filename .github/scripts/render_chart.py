#!/usr/bin/env python3
"""Render a Bulwark history JSON into a deterministic SVG line chart (stdlib only).

Reads a history file produced by ``merge_history.py`` and emits an SVG line chart.
The series are derived from the shape of ``daily`` values (documented, not magic):

  * dict values  -> one line per numeric sub-key (e.g. GitHub clones: ``count`` +
                    ``uniques``). Sub-keys are plotted in sorted order for
                    deterministic colour assignment.
  * scalar values -> a single line under the series name ``--metric`` (e.g. npm
                    ``downloads``).

Determinism guarantees (so re-renders of unchanged data are byte-identical and the
workflow can skip no-op commits via ``git diff --quiet``):
  * No timestamps, no RNG, no locale-dependent formatting in the output.
  * Fixed canvas, fixed colour palette, axis bounds derived only from the data.
  * Dates plotted in sorted order.

Usage:
  render_chart.py --history clones.json --out clones.svg --title "GitHub clones"
  render_chart.py --history npm-downloads.json --out npm-downloads.svg \
      --title "npm downloads" --metric downloads
"""

import argparse
import json
import sys

# Fixed canvas + layout (no RNG, no env). Changing these changes every SVG, which
# is acceptable as an intentional, reviewed layout change.
WIDTH = 760
HEIGHT = 300
PAD_LEFT = 50
PAD_RIGHT = 20
PAD_TOP = 40
PAD_BOTTOM = 40
PLOT_W = WIDTH - PAD_LEFT - PAD_RIGHT
PLOT_H = HEIGHT - PAD_TOP - PAD_BOTTOM

# Deterministic palette (assigned to series in sorted-key order).
PALETTE = ["#2563eb", "#16a34a", "#dc2626", "#9333ea", "#ea580c"]

MAX_X_LABELS = 8  # cap x-axis tick labels to avoid crowding


def load_series(history, metric):
    """Return (dates_sorted, {series_name: [values aligned to dates]})."""
    daily = history.get("daily", {})
    dates = sorted(daily)
    if not dates:
        return [], {}

    sample = daily[dates[0]]
    if isinstance(sample, dict):
        series_names = sorted(sample.keys())
        series = {name: [daily[d].get(name, 0) for d in dates] for name in series_names}
    else:
        series = {metric: [daily[d] for d in dates]}
    return dates, series


def _x(i, n):
    """X pixel for the i-th of n points (n>=1)."""
    if n == 1:
        return PAD_LEFT + PLOT_W / 2.0
    return PAD_LEFT + (PLOT_W * i / (n - 1))


def _y(value, ymax):
    """Y pixel for a value given the axis max (0 at bottom)."""
    if ymax <= 0:
        return PAD_TOP + PLOT_H
    return PAD_TOP + PLOT_H - (PLOT_H * value / ymax)


def _fmt(num):
    """Format a coordinate to 2 decimals, trimming trailing zeros (locale-free)."""
    return f"{num:.2f}".rstrip("0").rstrip(".")


def render_svg(history, title, metric):
    dates, series = load_series(history, metric)
    parts = []
    parts.append(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" '
        f'viewBox="0 0 {WIDTH} {HEIGHT}" font-family="sans-serif">'
    )
    parts.append(f'<rect width="{WIDTH}" height="{HEIGHT}" fill="#ffffff"/>')
    parts.append(
        f'<text x="{PAD_LEFT}" y="24" font-size="16" font-weight="bold" fill="#111827">'
        f"{_escape(title)}</text>"
    )

    if not dates:
        parts.append(
            f'<text x="{WIDTH / 2}" y="{HEIGHT / 2}" font-size="13" fill="#6b7280" '
            f'text-anchor="middle">no data yet</text>'
        )
        parts.append("</svg>")
        return "\n".join(parts) + "\n"

    ymax = max((max(vals) for vals in series.values()), default=0)
    ymax = _nice_max(ymax)

    # Axes.
    parts.append(
        f'<line x1="{PAD_LEFT}" y1="{PAD_TOP}" x2="{PAD_LEFT}" y2="{PAD_TOP + PLOT_H}" '
        f'stroke="#d1d5db" stroke-width="1"/>'
    )
    parts.append(
        f'<line x1="{PAD_LEFT}" y1="{PAD_TOP + PLOT_H}" x2="{PAD_LEFT + PLOT_W}" '
        f'y2="{PAD_TOP + PLOT_H}" stroke="#d1d5db" stroke-width="1"/>'
    )

    # Y gridlines + labels (0, half, max).
    for frac in (0.0, 0.5, 1.0):
        val = ymax * frac
        y = _y(val, ymax)
        parts.append(
            f'<line x1="{PAD_LEFT}" y1="{_fmt(y)}" x2="{PAD_LEFT + PLOT_W}" y2="{_fmt(y)}" '
            f'stroke="#f3f4f6" stroke-width="1"/>'
        )
        parts.append(
            f'<text x="{PAD_LEFT - 6}" y="{_fmt(y + 4)}" font-size="10" fill="#6b7280" '
            f'text-anchor="end">{_fmt_int(val)}</text>'
        )

    # X tick labels (subset of dates).
    n = len(dates)
    step = max(1, (n + MAX_X_LABELS - 1) // MAX_X_LABELS)
    for i in range(0, n, step):
        x = _x(i, n)
        parts.append(
            f'<text x="{_fmt(x)}" y="{PAD_TOP + PLOT_H + 16}" font-size="9" fill="#6b7280" '
            f'text-anchor="middle">{_escape(dates[i][5:])}</text>'  # MM-DD
        )

    # Series polylines + legend.
    series_names = list(series.keys())  # already sorted by load_series
    for idx, name in enumerate(series_names):
        colour = PALETTE[idx % len(PALETTE)]
        points = " ".join(
            f"{_fmt(_x(i, n))},{_fmt(_y(v, ymax))}" for i, v in enumerate(series[name])
        )
        parts.append(
            f'<polyline fill="none" stroke="{colour}" stroke-width="2" points="{points}"/>'
        )
        # Legend entry.
        lx = PAD_LEFT + idx * 110
        ly = HEIGHT - 8
        parts.append(f'<rect x="{lx}" y="{ly - 9}" width="10" height="10" fill="{colour}"/>')
        parts.append(
            f'<text x="{lx + 14}" y="{ly}" font-size="10" fill="#374151">{_escape(name)}</text>'
        )

    parts.append("</svg>")
    return "\n".join(parts) + "\n"


def _nice_max(ymax):
    """Round the axis max up to a clean bound so gridline labels are tidy."""
    if ymax <= 0:
        return 1
    if ymax <= 5:
        return 5
    if ymax <= 10:
        return 10
    # Round up to the next multiple of 10.
    return ((ymax + 9) // 10) * 10


def _fmt_int(val):
    return str(int(round(val)))


def _escape(text):
    return (
        str(text)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Render a history JSON into an SVG line chart.")
    parser.add_argument("--history", required=True, help="Path to the history JSON.")
    parser.add_argument("--out", required=True, help="Output SVG path.")
    parser.add_argument("--title", required=True, help="Chart title.")
    parser.add_argument(
        "--metric",
        default="value",
        help="Series name for scalar-valued history (e.g. downloads). Ignored for dict-valued history.",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    with open(args.history, "r", encoding="utf-8") as fh:
        history = json.load(fh)
    svg = render_svg(history, args.title, args.metric)
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write(svg)
    print(f"rendered: {args.out} ({len(history.get('daily', {}))} day(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
