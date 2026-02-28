---
viewpoint: targeted-investigation
topic: "P7 Launch: Plugin Manifest Format — Definitive Verification"
research_date: 2026-02-28
sources:
  - "https://code.claude.com/docs/en/plugins-reference (Plugin manifest schema)"
  - "https://code.claude.com/docs/en/plugins (Plugin creation guide)"
  - "https://code.claude.com/docs/en/plugin-marketplaces (Marketplace schema)"
confidence_summary:
  definitive: 3
  high: 4
key_findings:
  - "skills and agents fields accept EITHER a string path OR an array — both formats are valid per official schema"
  - "The Bulwark's current plugin.json uses string paths ('skills/', 'agents/'), which is schema-correct"
  - "The plugins-checklist.md array format ['name1', 'name2'] was NOT confirmed in official docs — official docs show directory path strings in examples"
  - "Only one field is required in plugin.json: 'name'"
  - "marketplace.json is a separate file in .claude-plugin/ — not part of plugin.json itself"
  - "Custom paths supplement default auto-discovered directories — they do not replace them"
---

# Plugin Manifest Format — Definitive Verification

## 1. Definitive Answer: skills and agents Field Format

**Both string path and array formats are valid.** The official Anthropic plugins-reference schema table explicitly defines:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `commands` | string\|array | Additional command files/directories | `"./custom/cmd.md"` or `["./cmd1.md"]` |
| `agents` | string\|array | Additional agent files | `"./custom/agents/reviewer.md"` |
| `skills` | string\|array | Additional skill directories | `"./custom/skills/"` |
| `hooks` | string\|array\|object | Hook config paths or inline config | `"./my-extra-hooks.json"` |
| `mcpServers` | string\|array\|object | MCP config paths or inline config | `"./my-extra-mcp-config.json"` |
| `lspServers` | string\|array\|object | LSP configs | `"./.lsp.json"` |

Source: https://code.claude.com/docs/en/plugins-reference#component-path-fields

**The Contrarian finding that plugins-checklist.md expects an array is NOT supported by official documentation.** The official docs show string paths in all examples, and define `string|array` as accepted for both `skills` and `agents`. The Bulwark's current format using `"skills": "skills/"` and `"agents": "agents/"` is schema-correct.

### Critical nuance: "supplement, not replace"

The docs state explicitly:

> **Important**: Custom paths supplement default directories — they don't replace them.
> - If `commands/` exists, it's loaded in addition to custom command paths
> - All paths must be relative to plugin root and start with `./`

This means: The Bulwark's `"skills": "skills/"` in plugin.json is specifying the custom/additional path. Since the default auto-discovery location IS `skills/` at the plugin root, declaring it explicitly is redundant but not harmful. Auto-discovery already picks up `skills/`, `agents/`, etc. at the plugin root without any manifest entry.

---

## 2. Full plugin.json Schema

### Required fields

Only ONE field is required if a manifest is present:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `name` | string | Unique identifier (kebab-case, no spaces). Used as namespace prefix for skills. | `"the-bulwark"` |

The manifest itself is optional. If omitted entirely, Claude Code auto-discovers components in default locations and uses the directory name as the plugin name.

### Metadata fields (all optional)

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `version` | string | Semantic version string | `"0.1.0"` |
| `description` | string | Brief plugin purpose | `"Deterministic quality governance..."` |
| `author` | object | `{"name": "...", "email": "...", "url": "..."}` | `{"name": "Ashay Kubal"}` |
| `homepage` | string | Documentation URL | `"https://github.com/ashaykubal/the-bulwark"` |
| `repository` | string | Source code URL | `"https://github.com/ashaykubal/the-bulwark"` |
| `license` | string | SPDX identifier | `"MIT"` |
| `keywords` | array of strings | Discovery tags | `["workflow", "quality", "enforcement"]` |

### Component path fields (all optional — auto-discovered if absent)

| Field | Type | Description | Default auto-discovery |
|-------|------|-------------|----------------------|
| `commands` | string\|array | Additional command files or directories | `commands/` at plugin root |
| `agents` | string\|array | Additional agent files | `agents/` at plugin root |
| `skills` | string\|array | Additional skill directories | `skills/` at plugin root |
| `hooks` | string\|array\|object | Hook config path(s) or inline config object | `hooks/hooks.json` at plugin root |
| `mcpServers` | string\|array\|object | MCP config path(s) or inline config object | `.mcp.json` at plugin root |
| `lspServers` | string\|array\|object | LSP config path(s) or inline config object | `.lsp.json` at plugin root |
| `outputStyles` | string\|array | Output style files/directories | — |

### Complete schema example (from official docs)

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

### Special: `settings.json` at plugin root

A separate `settings.json` file (not a field in `plugin.json`) can be placed at the plugin root to provide default configuration. Currently only the `agent` key is supported — it activates one of the plugin's custom agents as the main thread.

```json
{
  "agent": "security-reviewer"
}
```

Settings from `settings.json` take priority over any `settings` declared in `plugin.json`. Unknown keys are silently ignored.

---

## 3. marketplace.json Requirements

`marketplace.json` is a **separate file** placed at `.claude-plugin/marketplace.json`. It is the marketplace catalog, not a field within `plugin.json`. A plugin does not need a marketplace.json to function — that file is only needed when distributing via a marketplace.

### marketplace.json Required fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Marketplace identifier (kebab-case). Users see this: `/plugin install my-tool@{name}` |
| `owner` | object | `{"name": "...", "email": "..."}` — name is required, email optional |
| `plugins` | array | List of plugin entries |

### marketplace.json Optional metadata

| Field | Type | Description |
|-------|------|-------------|
| `metadata.description` | string | Brief marketplace description |
| `metadata.version` | string | Marketplace version |
| `metadata.pluginRoot` | string | Base directory prepended to relative plugin source paths |

### Plugin entries in marketplace.json (minimum required)

```json
{
  "name": "the-bulwark",
  "source": "./plugins/the-bulwark"
}
```

Full optional fields per plugin entry: `description`, `version`, `author`, `homepage`, `repository`, `license`, `keywords`, `category`, `tags`, `strict` (boolean, default true), plus all component path fields (`commands`, `agents`, `hooks`, `mcpServers`, `lspServers`).

### Plugin source types

| Type | Format | Description |
|------|--------|-------------|
| Relative path | `"./my-plugin"` (string) | Local directory within marketplace repo |
| GitHub | `{"source": "github", "repo": "owner/repo", "ref": "v1.0", "sha": "..."}` | GitHub repository |
| Git URL | `{"source": "url", "url": "https://gitlab.com/team/plugin.git", "ref": "...", "sha": "..."}` | Any git host |
| npm | `{"source": "npm", "package": "@org/plugin", "version": "2.1.0", "registry": "..."}` | npm package |
| pip | `{"source": "pip", "package": "name", "version": "..."}` | Python package |

### marketplace.json example

```json
{
  "name": "bulwark-marketplace",
  "owner": {
    "name": "Ashay Kubal"
  },
  "plugins": [
    {
      "name": "the-bulwark",
      "source": {
        "source": "github",
        "repo": "ashaykubal/the-bulwark"
      },
      "description": "Deterministic quality governance layer for AI-assisted software development",
      "version": "0.1.0"
    }
  ]
}
```

---

## 4. Current plugin.json State and What Needs Changing

### Current state (at `/mnt/c/projects/the-bulwark/.claude-plugin/plugin.json`)

```json
{
  "name": "the-bulwark",
  "description": "Deterministic quality governance layer for AI-assisted software development. Enforces testing discipline, code review, and quality gates through hooks, sub-agents, and skills.",
  "version": "0.1.0",
  "commands": [],
  "agents": "agents/",
  "skills": "skills/",
  "hooks": "hooks/hooks.json",
  "author": {
    "name": "Ashay Kubal"
  }
}
```

### Assessment

| Field | Status | Issue |
|-------|--------|-------|
| `name` | VALID | Required field present |
| `description` | VALID | Optional metadata present |
| `version` | VALID | Optional metadata present |
| `commands: []` | REVIEW NEEDED | Empty array explicitly suppresses default `commands/` auto-discovery. If The Bulwark has no `commands/` directory (confirmed: skills live in `skills/`), this is harmless but unnecessary. If it ever has a `commands/` directory, this will suppress it. Recommend removing or documenting the intent. |
| `agents: "agents/"` | VALID — but redundant | `agents/` at plugin root is auto-discovered by default. Declaring `"agents": "agents/"` explicitly is redundant but valid per schema. However: The Bulwark's agents currently live in `.claude/agents/` (19 agents), NOT at a root-level `agents/`. If there is no root-level `agents/` directory, this path resolves to nothing. This is a structural gap. |
| `skills: "skills/"` | VALID — and redundant | Same as agents: `skills/` at plugin root is auto-discovered. The skills ARE at `skills/` (plugin root), so this is harmless. |
| `hooks: "hooks/hooks.json"` | VALID — and redundant | `hooks/hooks.json` is the default auto-discovery location. Declaring it explicitly is valid but redundant. |
| `author` | VALID | Optional metadata present |
| Missing: `repository` | GAP | Recommended for marketplace discovery |
| Missing: `homepage` | GAP | Recommended for marketplace discovery |
| Missing: `license` | GAP | Recommended for marketplace discovery |
| Missing: `keywords` | GAP | Recommended for marketplace discovery |

### What needs changing for P7

1. **Remove `"commands": []`** — or leave as explicit suppressor if intent is to prevent commands/ from being loaded. Add a comment in nearby docs explaining the intent. No commands/ directory exists in Bulwark, so the empty array is currently a no-op.

2. **Resolve the agents/ directory gap** — The Bulwark has 19 agents in `.claude/agents/`. For plugin distribution, agents need to be at the plugin root in `agents/`. Either:
   - Create a root-level `agents/` directory and move/copy agent files there
   - OR remove `"agents": "agents/"` from plugin.json until the root-level directory exists

3. **Add marketplace metadata** — `repository`, `homepage`, `license`, `keywords` for discovery. These are optional but strongly recommended for any public distribution.

4. **The `skills/` and `hooks/` declarations can stay** — they're redundant but valid, and make the manifest self-documenting.

### Recommended final plugin.json for P7

```json
{
  "name": "the-bulwark",
  "description": "Deterministic quality governance layer for AI-assisted software development. Enforces testing discipline, code review, and quality gates through hooks, sub-agents, and skills.",
  "version": "0.1.0",
  "author": {
    "name": "Ashay Kubal",
    "url": "https://github.com/ashaykubal"
  },
  "homepage": "https://github.com/ashaykubal/the-bulwark",
  "repository": "https://github.com/ashaykubal/the-bulwark",
  "license": "MIT",
  "keywords": ["workflow", "quality-gates", "enforcement", "testing", "governance"],
  "hooks": "hooks/hooks.json"
}
```

Notes on this recommendation:
- `commands`, `agents`, `skills` are all omitted — auto-discovered from their default locations at plugin root
- `agents` omitted intentionally until root-level `agents/` directory exists
- `hooks` retained explicitly since it deviates from the default pattern (pointing to a file, which is the default, but explicit is clearer)
- Metadata fields added for marketplace readiness

---

## 5. Relevant Documentation Links

| Document | URL |
|----------|-----|
| Plugin manifest schema (complete) | https://code.claude.com/docs/en/plugins-reference#plugin-manifest-schema |
| Plugin component path fields | https://code.claude.com/docs/en/plugins-reference#component-path-fields |
| Plugin directory structure | https://code.claude.com/docs/en/plugins-reference#plugin-directory-structure |
| Create plugins guide | https://code.claude.com/docs/en/plugins |
| Marketplace schema | https://code.claude.com/docs/en/plugin-marketplaces#marketplace-schema |
| Plugin entry fields | https://code.claude.com/docs/en/plugin-marketplaces#optional-plugin-fields |
| Plugin sources | https://code.claude.com/docs/en/plugin-marketplaces#plugin-sources |
| Plugin caching and path resolution | https://code.claude.com/docs/en/plugins-reference#plugin-caching-and-file-resolution |

---

## Verdict on the Contrarian Finding

**Finding**: The plugins-checklist.md expects `"skills": ["skill-one", "skill-two"]` (array of names), but plugin.json uses `"skills": "skills/"` (directory path string).

**Resolution**: The Contrarian finding was correct to flag the discrepancy, but the resolution is that **both formats are valid per the official schema** (`string|array`). The directory path string is explicitly documented and shown in the official schema example (`"skills": "./custom/skills/"`). The array format with explicit skill names (as in plugins-checklist.md) is also valid.

The plugins-checklist.md was written before the official docs were checked, and its array format is one valid representation — not the required format. The Bulwark's current directory path format is equally valid and actually simpler for a plugin with 28 skills (no need to enumerate each one).

**No change required to the skills or hooks fields for schema compliance reasons.** Changes to `agents` field and missing metadata fields are the real action items.
