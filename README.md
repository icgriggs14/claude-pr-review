# Claude PR Review

[![GitHub release](https://img.shields.io/github/v/release/icgriggs14/claude-pr-review)](https://github.com/icgriggs14/claude-pr-review/releases)
[![GitHub Marketplace](https://img.shields.io/badge/marketplace-claude--pr--review-blue?logo=github)](https://github.com/marketplace/actions/claude-pr-review)
[![GitHub Stars](https://img.shields.io/github/stars/icgriggs14/claude-pr-review?style=social)](https://github.com/icgriggs14/claude-pr-review)

Automated PR code review using Claude AI. Every pull request gets an AI review that finds bugs, security issues, and logic errors before they merge — in under 30 seconds.

## Quick start

```yaml
# .github/workflows/pr-review.yml
name: Claude PR Review
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: icgriggs14/claude-pr-review@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

**Setup (2 minutes):**
1. Get an [Anthropic API key](https://console.anthropic.com/) (free tier available)
2. Add it as a GitHub secret: `Settings → Secrets and variables → Actions → New repository secret`
   - Name: `ANTHROPIC_API_KEY`
3. Add the workflow file above to `.github/workflows/pr-review.yml`

Done. Claude will review every new PR automatically.

## What it does

On each PR open/update, the action:
1. Fetches the PR diff (up to `max_files` changed files)
2. Sends the diff + PR description to Claude
3. Posts a structured review comment with:
   - **Summary** of what changed
   - **Issues** flagged as 🔴 CRITICAL / 🟡 WARNING / 💡 SUGGESTION
   - **Verdict**: LGTM ✅ / NEEDS WORK 🔧 / BLOCKED 🚫

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `anthropic_api_key` | ✅ | — | Anthropic API key (use GitHub Secrets) |
| `model` | ❌ | `claude-haiku-4-5-20251001` | Claude model (`claude-haiku-*`=fast+cheap, `claude-sonnet-*`=deeper) |
| `max_files` | ❌ | `10` | Max files to review per PR (controls cost) |

## Cost estimate

| Model | Cost per PR | Speed |
|---|---|---|
| `claude-haiku-4-5-20251001` (default) | ~$0.001–0.005 | < 15 seconds |
| `claude-sonnet-4-6` | ~$0.01–0.05 | ~20 seconds |

A typical engineering team with 20 PRs/week costs < $0.10/week on Haiku. Add a spending limit in [Anthropic Console](https://console.anthropic.com/) for peace of mind.

## Requirements

- Workflow trigger: `pull_request`
- Permission: `pull-requests: write` (to post the review comment)
- `jq` and `curl` — both available on all GitHub-hosted runners (`ubuntu-latest`, `macos-latest`, `windows-latest`)

## Advanced usage

```yaml
# Use Sonnet for deeper analysis on main branch PRs
- uses: icgriggs14/claude-pr-review@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    model: claude-sonnet-4-6
    max_files: 20
```

## Support

If this saves you review time, consider [sponsoring on GitHub](https://github.com/sponsors/icgriggs14) ☕ — it keeps the project maintained and free.

Found a bug or want a feature? [Open an issue](https://github.com/icgriggs14/claude-pr-review/issues).

## Related tools

- **[claude-pr-review CLI](https://github.com/icgriggs14/claude-pr-review-cli)** — npm CLI companion: `npx claude-pr-review` runs the same review locally before you push. Works with any git repo, no GitHub required.
- **[claude-commit](https://github.com/icgriggs14/claude-commit)** — `npx claude-commit` reads your staged diff → Claude Haiku → perfect conventional commit message in seconds.
- **[claude-changelog-action](https://github.com/icgriggs14/claude-changelog-action)** — Auto-generate changelogs on every release via GitHub Actions.
- **[claude-test-writer](https://github.com/icgriggs14/claude-test-writer)** — Generate unit tests for uncovered files via GitHub Action or `npx claude-test-writer`.

---

## Related tools

Part of the **claude autonomous-rail suite** — AI-powered developer tools that run entirely in GitHub Actions:

- [**claude-changelog-action**](https://github.com/icgriggs14/claude-changelog-action) — Auto-generate changelogs & release notes from git history
- [**claude-test-writer**](https://github.com/icgriggs14/claude-test-writer) — Auto-generate unit tests for every PR
- **claude-pr-review** — AI code review on every PR (this repo)

**npm CLI companions** (coming soon to npm):
- `npx claude-pr-review` — run PR review from the command line
- `npx claude-commit` — AI-powered conventional commit messages

---

Built with [Claude Code](https://claude.ai/code). MIT License.


## Other Claude AI Tools

These companion tools from the same author work great together:

- **[claude-changelog-action](https://github.com/icgriggs14/claude-changelog-action)** — Auto-generate changelogs from commits using Claude
- **[claude-test-writer](https://github.com/icgriggs14/claude-test-writer)** — AI unit test generation CLI + GitHub Action
- **[react-doctor-action](https://github.com/icgriggs14/react-doctor-action)** — CI health checks for React projects
- **[knip-action](https://github.com/icgriggs14/knip-action)** — CI enforcement for knip unused-exports detection
- **[secretlint-action](https://github.com/icgriggs14/secretlint-action)** — CI credential leak detection using secretlint

[Sponsor this work on GitHub Sponsors](https://github.com/sponsors/icgriggs14)
