# 5. GitHub Basics

## Creating a Repository on GitHub

1. Click **New** (or the `+` in the top right → **New repository**).
2. Choose a name, visibility (public/private), and optionally initialize with a README, `.gitignore`, and license.
3. GitHub gives you a remote URL, e.g. `https://github.com/username/repo.git`.

### Connecting a local repo to GitHub

If you already have a local project:
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/username/repo.git
git push -u origin main
```

If you're starting from GitHub:
```bash
git clone https://github.com/username/repo.git
```

## Remotes

A "remote" is a named reference to a repository hosted elsewhere.

```bash
git remote -v                          # list remotes and their URLs
git remote add origin <url>            # add a remote named "origin"
git remote add upstream <url>          # common name for the original repo you forked from
git remote rename origin old-origin
git remote remove origin
git remote set-url origin <new-url>    # change a remote's URL
```

`origin` is just a convention — the default name Git gives the remote you cloned from — not a special keyword.

## Pushing and Pulling

```bash
git push origin main                  # push local main to remote main
git push -u origin main               # push AND remember this as the default upstream
git push                              # (after -u) pushes to the remembered upstream
git push origin feature-branch        # push a new branch
git push origin --delete feature-branch   # delete a remote branch

git fetch origin                      # download remote changes WITHOUT merging
git pull origin main                  # fetch + merge (or rebase, per config) in one step
git pull --rebase origin main         # fetch + rebase instead of merge
```

### `fetch` vs. `pull`

- `git fetch` downloads new commits/branches from the remote but does **not** touch your working directory or current branch — safe to run anytime.
- `git pull` = `fetch` + `merge` (or `rebase`) automatically — can cause conflicts or unexpected changes to your working files.

### Force-pushing safely

```bash
git push --force              # dangerous: can silently overwrite others' work
git push --force-with-lease   # safer: fails if the remote has commits you haven't seen
```
Prefer `--force-with-lease` whenever you must force-push (e.g., after an interactive rebase on your own branch).

## HTTPS vs. SSH Remote URLs

```
HTTPS: https://github.com/username/repo.git
SSH:   git@github.com:username/repo.git
```
SSH avoids re-entering credentials once your key is set up (see file 1). Switch a remote's protocol with `git remote set-url`.

## Forking vs. Cloning

- **Clone**: downloads a copy of a repo to your machine. You can push back to it only if you have write access.
- **Fork**: creates your *own copy of the repository on GitHub* (server-side), under your account. Used when you don't have write access to the original (e.g., contributing to open source). You then clone **your fork**, make changes, and open a pull request back to the original.

Typical open-source contribution flow:
```bash
# 1. Fork the repo on GitHub's website (button, top right)
# 2. Clone your fork
git clone git@github.com:your-username/repo.git
cd repo

# 3. Add the original repo as "upstream" to stay in sync
git remote add upstream git@github.com:original-owner/repo.git

# 4. Create a branch for your change
git switch -c fix-typo

# 5. Make changes, commit, push to YOUR fork
git push origin fix-typo

# 6. Open a Pull Request from your fork's branch into the original repo (on GitHub's website)

# Keeping your fork up to date later:
git fetch upstream
git switch main
git merge upstream/main
git push origin main
```

## Repository Visibility & Settings

- **Public**: anyone can view; only collaborators can push.
- **Private**: only invited collaborators can view or push.
- **Internal** (organizations only): visible to all members of the org.

Common settings under a repo's **Settings** tab: default branch, branch protection rules, collaborators/teams, webhooks, secrets (for Actions), Pages, merge button behavior (allow squash/rebase/merge commits).

## READMEs, Licenses, and Other Standard Files

| File | Purpose |
|---|---|
| `README.md` | Project overview, shown on the repo's homepage |
| `LICENSE` | Legal terms for using/reusing the code (MIT, Apache-2.0, GPL, etc.) |
| `.gitignore` | Files Git should never track |
| `CONTRIBUTING.md` | Guidelines for external contributors |
| `CODE_OF_CONDUCT.md` | Community behavior expectations |
| `.github/ISSUE_TEMPLATE/` | Custom templates for new issues |
| `.github/PULL_REQUEST_TEMPLATE.md` | Custom template for new PRs |
| `.github/workflows/*.yml` | GitHub Actions CI/CD pipeline definitions |

## GitHub CLI (`gh`)

An official command-line tool for interacting with GitHub without leaving the terminal.

```bash
gh auth login                    # authenticate
gh repo create my-project        # create a new repo
gh repo clone username/repo
gh pr create                     # open a pull request
gh pr list
gh pr checkout 42                # check out PR #42 locally
gh pr merge 42
gh issue create
gh issue list
```

← Back to [04-git-advanced.md](04-git-advanced.md) | Continue to [06-github-collaboration.md](06-github-collaboration.md) →
