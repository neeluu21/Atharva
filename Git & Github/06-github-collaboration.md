# 6. GitHub Collaboration Features

## Pull Requests (PRs)

A pull request proposes merging changes from one branch (or fork) into another, with a structured space for review and discussion before the merge happens.

### Typical workflow

```bash
git switch -c feature/user-auth
# ... make changes, commit ...
git push -u origin feature/user-auth
# Open a PR on GitHub: base = main, compare = feature/user-auth
```

On GitHub:
1. Give the PR a clear title and description (what changed, why, how to test).
2. Request reviewers.
3. Reviewers leave comments, request changes, or approve.
4. Address feedback with more commits (they appear automatically in the PR).
5. Once approved and checks pass, merge.

### Merge strategies

| Strategy | Effect |
|---|---|
| **Merge commit** | Preserves all individual commits + adds a merge commit. Full history, less linear. |
| **Squash and merge** | Combines all PR commits into one commit on the base branch. Clean history, loses granular commit detail. |
| **Rebase and merge** | Replays PR commits individually onto the base branch, no merge commit. Linear history, preserves individual commits. |

Repo admins can restrict which strategies are allowed under **Settings → General → Pull Requests**.

### Draft PRs

Open a PR marked "Draft" to share work-in-progress and get early feedback without signaling it's ready to merge.

### Keeping a PR branch up to date

```bash
git switch feature/user-auth
git fetch origin
git merge origin/main        # or: git rebase origin/main
git push
```

## Code Review

- Comment on specific lines by clicking the `+` next to a line in the "Files changed" tab.
- **Approve**, **Request changes**, or **Comment** as an overall review verdict.
- Suggested changes: reviewers can propose exact replacement code that the author can accept with one click.
- Conversations can be marked "resolved" once addressed.

## Issues

Issues track bugs, feature requests, and tasks.

- Assign to a user, apply labels (`bug`, `enhancement`, `good first issue`), set a milestone.
- Reference and auto-close issues from commits/PRs using keywords:
  ```
  Fixes #42
  Closes #42
  Resolves #42
  ```
  Merging a PR containing that phrase automatically closes issue #42.
- Link related issues/PRs by just typing `#` followed by the number — GitHub auto-links it.

## Projects (Boards)

Kanban-style boards (To Do / In Progress / Done, or custom columns) that can auto-populate from issues and PRs across one or more repos. Useful for sprint planning and roadmaps.

## Branch Protection Rules

Under **Settings → Branches**, admins can require, for a given branch (typically `main`):

- Pull request review(s) before merging
- Status checks (CI) to pass before merging
- Signed commits
- Linear history (no merge commits)
- No force-pushes or deletions
- Administrators included in these restrictions

## GitHub Actions (CI/CD)

Automate workflows (tests, builds, deployments) triggered by repo events. Defined in YAML files under `.github/workflows/`.

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm install
      - run: npm test
```

Key concepts:
- **Workflow**: the whole automated process (a YAML file).
- **Job**: a set of steps that run on the same runner.
- **Step**: an individual command or reusable **Action** (from the Marketplace, e.g. `actions/checkout`).
- **Runner**: the machine (GitHub-hosted or self-hosted) executing the job.
- **Secrets**: encrypted environment variables (API keys, tokens) set under **Settings → Secrets and variables**.

## Permissions & Teams (Organizations)

| Role | Typical abilities |
|---|---|
| Read | View and clone |
| Triage | Manage issues/PRs, no code write access |
| Write | Push code, merge PRs |
| Maintain | Write + manage some repo settings |
| Admin | Full control, including danger-zone settings and deletion |

Organizations can group members into **Teams** and grant a team access to multiple repos at once, rather than managing permissions per-person.

## GitHub Pages

Host a static website directly from a repository (often from a `gh-pages` branch or a `/docs` folder). Configured under **Settings → Pages**. Great for documentation sites, portfolios, and project landing pages.

## Releases

Package a specific tagged commit as a formal release, with release notes and downloadable binary assets attached.

```bash
git tag -a v1.2.0 -m "Version 1.2.0"
git push origin v1.2.0
# Then on GitHub: Releases → Draft a new release → choose the tag
```
```bash
gh release create v1.2.0 --notes "Bug fixes and performance improvements"
```

## Security Features

- **Dependabot**: automatically opens PRs to update vulnerable/outdated dependencies.
- **Code scanning (CodeQL)**: static analysis to catch security issues.
- **Secret scanning**: detects accidentally committed credentials/API keys.
- **Security advisories**: privately discuss and disclose vulnerabilities before publishing a fix.

← Back to [05-github-basics.md](05-github-basics.md) | Continue to [07-cheatsheet.md](07-cheatsheet.md) →
