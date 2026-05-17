#!/usr/bin/env python3
"""Per-file pipeline-coverage checker for suggest-pipeline-stop.sh.

Extracted from the bash heredoc into a standalone module (S117 L-001/L-002)
for testability and to remove ~300 lines of Python embedded in shell.

Usage:
    python3 coverage_check.py ACCUMULATOR REGISTRY LOGS_DIR PROJECT_DIR SLACK_SECONDS

Inputs (positional argv):
    ACCUMULATOR       Path to tmp/bulwark-changed-files.json (read).
    REGISTRY          Path to tmp/bulwark-review-registry.json (read+write).
    LOGS_DIR          Project logs/ directory (read).
    PROJECT_DIR       Project root (informational).
    SLACK_SECONDS     Window pre-padding for coverage check (int).

Output (stdout):
    JSON: {"fire_list": [...], "counts": {"code": N, "test": N, "script": N}}

Side effect:
    Atomic-rewrites REGISTRY with PENDING entries removed for covered files.

Exit codes:
    0 — always (graceful degrade for any malformed input). Bash side detects
        empty/exit-nonzero and silent-passes per CS3.

Hardening (S115 self-test findings):
    SEC-001/002/006 — path safety + symlink reject
    SEC-003          — read cap (1 MB per log)
    SEC-004          — atomic registry write
    TS-01..06        — parse + arithmetic guards
    L-003            — WATCHED dedup helper
"""
import sys, os, json, re, glob, time
from datetime import datetime

# Module-level globals are set in main() from argv.
LOGS_DIR = ""
SLACK_SECONDS = 0

# SEC-003 mitigation — cap per-log read at 1 MB. Pipeline logs that exceed
# this size are almost certainly malformed; capping bounds parser worst-case.
MAX_LOG_BYTES = 1 * 1024 * 1024

# ---------------------------------------------------------------------------
# Watched-paths configuration
# ---------------------------------------------------------------------------
# L-003 — helper to expand a prefix into the standard yaml/md/json triple.
def _ymj(prefix):
    return [f"{prefix}.yaml", f"{prefix}.md", f"{prefix}.json"]

WATCHED = {
    "code": (
        _ymj("code-review/**/*")
        + _ymj("code-review-*")
        + _ymj("diagnostics/code-review-*")
        + _ymj("implementer-*")
        + _ymj("validations/fix-validation-*")
    ),
    "test": (
        _ymj("test-audit/**/*")
        + _ymj("test-audit-*")
        + _ymj("mock-detection-*")
        + _ymj("test-classification-*")
        + _ymj("diagnostics/test-audit-*")
        + _ymj("diagnostics/mock-detection-*")
        + _ymj("diagnostics/test-classification-*")
        + _ymj("implementer-*")
        + _ymj("validations/fix-validation-*")
    ),
    "script": (
        _ymj("code-review/**/*")
        + _ymj("code-review-*")
        + _ymj("validations/*")
        + _ymj("diagnostics/bulwark-scaffold-*")
        + _ymj("scaffold-*")
        + _ymj("bulwark-verify-*")
        + _ymj("diagnostics/bulwark-verify-*")
    ),
}

# Diagnostic-prefix routing: filename prefix (under logs/diagnostics/) -> bucket.
# Default-deny on unknown prefixes — new emitters fire normally until added.
DIAG_PREFIX_TO_BUCKET = {
    "code-review-": "code",
    "test-audit-": "test",
    "mock-detection-": "test",
    "test-classification-": "test",
    "bulwark-scaffold-": "script",
    "bulwark-verify-": "script",
}

# SEC-001/002 — path safety. Rejects:
#   - shell metacharacters that would be active in `reason` text seen by Claude
#   - .. segments (path traversal)
#   - absolute paths (we expect project-relative)
#   - empty / whitespace-only
SAFE_PATH_RE = re.compile(r'^[A-Za-z0-9._/\-]+$')

def is_safe_path(p):
    if not p or not isinstance(p, str):
        return False
    if not SAFE_PATH_RE.match(p):
        return False
    if p.startswith('/') or p.startswith('./..'):
        return False
    parts = p.split('/')
    if any(seg == '..' for seg in parts):
        return False
    return True

def normalize_path(p):
    if not p:
        return p
    p = p.replace("\\", "/")
    while p.startswith("./"):
        p = p[2:]
    return p

def classify_file(path):
    """File-type classification with cross-stack test detection (P10.19).

    Priority order (first match wins):
      1. Path-component test detection — any path component matching a known
         test directory name (tests, test, __tests__, spec, specs) or the
         two-component sequence src/test signals test intent regardless of
         filename. Component-based check (not substring) avoids false matches
         on names like "specs-disabled" or "testdata".
      2. PascalCase JVM/.NET test detection (case-sensitive) — *Test.{java,kt,
         scala,cs,vb,fs}, *Tests.{cs,vb}, *Spec.{kt,scala}, *Specs.cs, *IT.java.
      3. Filename-based test detection — test_* / test-* prefix or *_test.* /
         *-test.* / *_spec.* / *-spec.* / *.test.* / *.spec.* suffix patterns.
      4. Config extensions (.json, .yaml, .yml, .toml, .ini, .env) → script
         bucket. Config files are security-sensitive (credentials, hook config,
         build settings) and route to "Code Review (security focus)" per the
         canonical mapping in pipeline-templates SKILL.md.
      5. Script extensions (.sh, .bash, .zsh, .fish, .ps1) → script bucket.
      6. Generic code extensions → code bucket.
      7. Anything else → other (skipped by the hook).

    Out of scope (documented in pipeline-templates SKILL.md):
      - Rust inline #[test] annotations — content-only signal, no path detection.
      - Python doctests — same rationale.
    """
    norm = path.replace("\\", "/")
    lower = norm.lower()
    parts = norm.split("/")
    basename = parts[-1] if parts else norm

    # 1. Path-component test detection. SEC-SUG-2 (P10.19 hardening) — switched
    # from substring containment to component-equality to prevent false matches
    # on suffixed names (e.g., "tests-disabled/", "test_data/").
    single_test_dirs = {"tests", "test", "__tests__", "spec", "specs"}
    if any(p in single_test_dirs for p in parts):
        return "test"
    # Two-component sequence: .../src/test/...
    for i in range(len(parts) - 1):
        if parts[i] == "src" and parts[i + 1] == "test":
            return "test"

    # 2. PascalCase JVM/.NET test detection (case-sensitive on basename).
    if re.search(r'(Test|Tests|Spec|Specs|IT)\.(java|kt|scala|cs|vb|fs)$', basename):
        return "test"

    # 3. Filename-based test detection.
    lower_base = basename.lower()
    if lower_base.startswith("test_") or lower_base.startswith("test-"):
        return "test"
    if re.search(r'(_test|-test|_spec|-spec|\.test|\.spec)\.[a-z0-9]+$', lower_base):
        return "test"

    # 4. Config extensions — security-sensitive, route to script bucket.
    # STD-SUG-1 (P10.19 hardening) — closes contract drift with SKILL.md
    # mapping table which lists Config files under "Code Review (security focus)".
    if re.search(r'\.(json|yaml|yml|toml|ini|env)$', lower):
        return "script"

    # 5. Script extensions.
    if re.search(r'\.(sh|bash|zsh|fish|ps1)$', lower):
        return "script"

    # 6. Generic code extensions.
    if re.search(r'\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|java|cpp|c|rb|php|swift|kt|scala|exs|ex|cs|fs|vb)$', lower):
        return "code"

    return "other"

def parse_reviewed_files(log_path):
    """Parse top-level reviewed_files: [...] from a YAML/Markdown log file.
    Returns list[str] | None (None = field absent or unparseable = strict no-coverage).
    Reads up to MAX_LOG_BYTES to bound parser cost (SEC-003 mitigation)."""
    try:
        size = os.path.getsize(log_path)
        with open(log_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read(MAX_LOG_BYTES) if size > MAX_LOG_BYTES else f.read()
    except (IOError, OSError):
        return None
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if not line.startswith('reviewed_files:'):
            continue
        rest = line[len('reviewed_files:'):]
        rest = re.sub(r'\s+#.*$', '', rest).strip()
        # Flow form
        if rest.startswith('['):
            full = rest
            j = i
            while ']' not in full and j + 1 < len(lines):
                j += 1
                full += ' ' + lines[j].strip()
            m = re.search(r'\[(.*?)\]', full)
            if not m:
                return None
            inner = m.group(1).strip()
            if not inner:
                return []
            items = []
            for it in inner.split(','):
                it = it.strip().strip('"').strip("'")
                if it:
                    items.append(normalize_path(it))
            return items
        if rest and rest not in ('|', '>', '~', 'null', 'Null', 'NULL'):
            return None
        # Block form
        items = []
        j = i + 1
        while j < len(lines):
            cur_line = lines[j]
            stripped = cur_line.strip()
            if not stripped:
                j += 1
                continue
            if not (cur_line.startswith(' ') or cur_line.startswith('\t')):
                break
            if stripped.startswith('-'):
                item = stripped[1:].strip().strip('"').strip("'")
                if item:
                    items.append(normalize_path(item))
                j += 1
            else:
                break
        return items
    return None

def _parse_followup_kv(text, target):
    """Helper: parse `key: value` line into target dict (used by
    parse_followup_edits_expected for block-form list-item children)."""
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$', text)
    if not m:
        return
    key, val = m.group(1), m.group(2).strip()
    val = re.sub(r'\s+#.*$', '', val).strip()
    if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
        val = val[1:-1]
    if key == 'grace_window_seconds':
        try:
            target[key] = int(val)
        except (ValueError, TypeError):
            return  # silently drop malformed numeric — coverage check uses default
    elif key == 'finding_ids':
        m2 = re.match(r'^\[(.*)\]$', val)
        if m2:
            inner = m2.group(1).strip()
            if not inner:
                target[key] = []
            else:
                target[key] = [it.strip().strip('"').strip("'") for it in inner.split(',') if it.strip()]
        else:
            target[key] = val
    else:
        target[key] = val


def parse_followup_edits_expected(log_path):
    """Parse top-level followup_edits_expected: [...] from a YAML/Markdown log.

    Returns list[dict] | None (None = field absent or unparseable).
    Each dict may have keys: file (required), grace_window_seconds (optional,
    default 1800 applied at coverage-check time), finding_ids (optional,
    informational), rationale (optional, informational).

    Reads up to MAX_LOG_BYTES per SEC-003. SEC-006 symlink rejection is
    inherited from expand_watched_paths() at the caller boundary."""
    try:
        size = os.path.getsize(log_path)
        with open(log_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read(MAX_LOG_BYTES) if size > MAX_LOG_BYTES else f.read()
    except (IOError, OSError):
        return None
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if not line.startswith('followup_edits_expected:'):
            continue
        rest = line[len('followup_edits_expected:'):]
        rest = re.sub(r'\s+#.*$', '', rest).strip()
        # Empty flow list
        if rest == '[]':
            return []
        # Non-empty flow list with nested mappings is unsupported — treat malformed
        if rest.startswith('['):
            return None
        # Scalar after the key — malformed for a list-of-mappings field
        if rest and rest not in ('|', '>', '~', 'null', 'Null', 'NULL'):
            return None
        # Block form
        entries = []
        current = None
        j = i + 1
        while j < len(lines):
            cur_line = lines[j]
            stripped = cur_line.strip()
            if not stripped or stripped.startswith('#'):
                j += 1
                continue
            if not (cur_line.startswith(' ') or cur_line.startswith('\t')):
                break
            if stripped.startswith('- '):
                if current is not None:
                    entries.append(current)
                current = {}
                rest_item = stripped[1:].strip()
                if rest_item:
                    _parse_followup_kv(rest_item, current)
            elif current is not None and ':' in stripped:
                _parse_followup_kv(stripped, current)
            j += 1
        if current is not None:
            entries.append(current)
        return entries
    return None


def diag_routes_to_bucket(basename, bucket):
    """logs/diagnostics/<basename>: True iff basename's prefix maps to bucket.

    Default-deny on unknown prefixes — this is the security-relevant invariant.
    A diagnostic log whose filename prefix is not in DIAG_PREFIX_TO_BUCKET is
    treated as NOT covering the bucket; uncovered files keep firing until a
    routing entry is added explicitly. This prevents new (or attacker-named)
    diagnostic emitters from silently suppressing pipeline fire decisions.
    """
    for prefix, target in DIAG_PREFIX_TO_BUCKET.items():
        if basename.startswith(prefix):
            return target == bucket
    return False  # default-deny

def expand_watched_paths(bucket):
    """Yield absolute log paths matching any watched pattern for bucket,
    after applying diagnostic-prefix routing and SEC-006 symlink rejection."""
    seen = set()
    logs_dir_abs = os.path.realpath(LOGS_DIR)
    for pat in WATCHED.get(bucket, []):
        full_pat = os.path.join(LOGS_DIR, pat)
        for match in glob.glob(full_pat, recursive=True):
            if match in seen:
                continue
            seen.add(match)
            # SEC-006 — reject symlinks pointing outside LOGS_DIR.
            try:
                resolved = os.path.realpath(match)
            except OSError:
                continue
            if not resolved.startswith(logs_dir_abs + os.sep) and resolved != logs_dir_abs:
                continue
            rel = os.path.relpath(match, LOGS_DIR).replace("\\", "/")
            if rel.startswith("diagnostics/"):
                base = os.path.basename(rel)
                if not diag_routes_to_bucket(base, bucket):
                    continue
            yield match

def coverage_in_window(file_path, bucket, first_edit_epoch):
    # TS-04 — None first_edit_epoch = unparseable timestamp = no coverage = fire.
    if first_edit_epoch is None:
        return False
    target = normalize_path(file_path)
    now_epoch = int(time.time())
    window_start = first_edit_epoch - SLACK_SECONDS
    for log_path in expand_watched_paths(bucket):
        try:
            mtime = int(os.path.getmtime(log_path))
        except OSError:
            continue
        # Standard window: log mtime in [first_edit - SLACK, now] → reviewed_files match.
        if window_start <= mtime <= now_epoch:
            reviewed = parse_reviewed_files(log_path)
            if reviewed is not None and any(normalize_path(rf) == target for rf in reviewed):
                return True
            continue
        # P10.22 grace window: log mtime BEFORE standard window. The pipeline ran
        # earlier in the session and may have declared follow-up edits expected
        # for this file. If the file's first edit lands within the declared grace
        # period of that pipeline log, treat as covered.
        if mtime < window_start:
            grace = parse_followup_edits_expected(log_path)
            if grace is None:
                continue
            for entry in grace:
                if not isinstance(entry, dict):
                    continue
                entry_file = entry.get("file", "")
                if not entry_file or normalize_path(entry_file) != target:
                    continue
                grace_seconds = entry.get("grace_window_seconds", 1800)
                if not isinstance(grace_seconds, int) or grace_seconds < 0:
                    grace_seconds = 1800
                if mtime <= first_edit_epoch <= mtime + grace_seconds:
                    return True
    return False

def iso_to_epoch(s):
    """TS-04 — return None on parse failure, never 0 (which would set
    window_start=-5 and over-suppress against any pipeline log ever written)."""
    if not s:
        return None
    try:
        return int(datetime.fromisoformat(s.replace('Z', '+00:00')).timestamp())
    except (ValueError, TypeError):
        return None

def load_json_with_retry(path):
    """TS-03 — small TOCTOU mitigation: retry once on partial-write JSONDecodeError."""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        time.sleep(0.05)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return None

def write_json_atomic(path, data):
    """SEC-004 — atomic registry write via tempfile + rename."""
    tmp_path = path + ".tmp"
    with open(tmp_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    os.replace(tmp_path, path)


def main():
    global LOGS_DIR, SLACK_SECONDS

    # Argv guards (TS-02): bail out gracefully on malformed invocation.
    try:
        ACCUMULATOR_PATH = sys.argv[1]
        REGISTRY_PATH = sys.argv[2]
        LOGS_DIR = sys.argv[3]
        PROJECT_DIR = sys.argv[4]  # noqa: F841 — informational, not used here.
        SLACK_SECONDS = int(sys.argv[5])
    except (IndexError, ValueError) as e:
        sys.stderr.write(f"argv parse failed: {e}\n")
        print(json.dumps({"fire_list": [], "counts": {"code": 0, "test": 0, "script": 0}}))
        sys.exit(0)

    # --- Load state ---
    acc = load_json_with_retry(ACCUMULATOR_PATH)
    if acc is None or not isinstance(acc, dict):
        print(json.dumps({"fire_list": [], "counts": {"code": 0, "test": 0, "script": 0}}))
        sys.exit(0)

    registry = load_json_with_retry(REGISTRY_PATH)
    if (not isinstance(registry, dict)
            or 'files' not in registry
            or not isinstance(registry.get('files'), dict)):
        registry = {"version": "1.0", "files": {}}

    fire_list = []
    counts = {"code": 0, "test": 0, "script": 0}

    for entry in acc.get("files", []):
        file_path = entry.get("path", "")
        # SEC-001/002 — silently drop unsafe paths. They never reach `reason`,
        # the registry, or the fire list.
        if not is_safe_path(file_path):
            continue
        bucket = classify_file(file_path)
        if bucket == "other":
            continue
        norm = normalize_path(file_path)
        info = registry["files"].get(norm)
        if info is None:
            registry["files"][norm] = {
                "first_edit_at": entry.get("time", ""),
                "bucket": bucket,
            }
            fire_list.append({
                "path": file_path,
                "tool": entry.get("tool", ""),
                "bucket": bucket,
            })
            counts[bucket] += 1
        else:
            first_edit_epoch = iso_to_epoch(info.get("first_edit_at", ""))
            if coverage_in_window(file_path, bucket, first_edit_epoch):
                del registry["files"][norm]
            else:
                fire_list.append({
                    "path": file_path,
                    "tool": entry.get("tool", ""),
                    "bucket": bucket,
                })
                counts[bucket] += 1

    write_json_atomic(REGISTRY_PATH, registry)

    print(json.dumps({"fire_list": fire_list, "counts": counts}))


if __name__ == "__main__":
    main()
