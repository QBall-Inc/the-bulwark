# Contributing to The Bulwark

Thanks for your interest in improving The Bulwark. Issues and pull requests are both welcome — this guide explains how contributions flow, because the repository model is a little different from a typical single-repo project.

## How this repository works

This public repository (`QBall-Inc/the-bulwark`) is a **mirror**. Active development happens in a private repository, and the user-facing plugin assets are synced here. That means:

- The code you see here is the published plugin surface, not the full development history.
- Changes merged here are **ported back** into the private repo by the maintainer, which then re-syncs. This keeps the two repositories from diverging.

## Opening an issue

Issues are open to everyone and are the fastest way to help. Please use the structured templates:

- **Bug report** — include reproduction steps, expected vs actual behavior, your plugin version, Claude Code version, OS/platform (WSL / macOS / Linux), and the relevant hook or skill.
- **Feature request** — describe the problem, your proposed solution, and any alternatives you considered.

[Open an issue →](https://github.com/QBall-Inc/the-bulwark/issues/new/choose)

## Submitting a pull request

PRs are **accepted on this public repository.** Here's the flow:

1. Fork the repo and create a branch from `main`.
2. Make your change. Keep it focused — one logical change per PR.
3. If you touch a Claude Code asset (skill, agent, hook, plugin manifest), make sure it still follows the [conventions](docs/reference/conventions.md) and validates against Anthropic's standards.
4. Open the PR against `main` with a clear description of what changed and why.

### What happens after you open a PR

- The maintainer reviews the PR here on the public repo.
- When it's accepted, the change is **merged here and then ported into the private dev repo**, which becomes the source of truth for the next sync. Your contribution is preserved and you are credited.
- Because syncing flows private → public, the porting step is **mandatory** — without it, a later sync would overwrite a merged public PR. The maintainer owns this step; you don't need to do anything beyond opening the PR.

> **Note for the maintainer:** a merged public PR lives only on the public repo until it is ported into the private repo. Port it *before* the next `sync-to-public.sh` run, or the sync will clobber it.

## Development conventions

If you're proposing a code or asset change, it's worth knowing the standards the project enforces on itself:

- **[Conventions](docs/reference/conventions.md)** — the CS / T / V / ID rules (coding standards, testing, verification, issue debugging).
- **[How it works](docs/guides/how-it-works.md)** and **[architecture.md](docs/architecture.md)** — the design model.
- Markdown and shell files use **LF line endings** only.

## Code of conduct

Please be respectful and constructive in issues and PRs. We aim to keep this a welcoming project for contributors of all backgrounds.

## Questions

If something here is unclear, [open an issue](https://github.com/QBall-Inc/the-bulwark/issues) and ask — clarifying questions are welcome.
