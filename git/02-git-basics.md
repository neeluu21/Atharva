# 2. Git Basics

## The Three Areas

Git manages files across three areas:

```
Working Directory  --add-->  Staging Area (Index)  --commit-->  Repository (.git)
     (your files)              (what will be                    (permanent
                                 committed next)                   history)
```

- **Working directory**: the files you see and edit.
- **Staging area**: a preview of your next commit — you choose exactly which changes to include.
- **Repository**: the committed, permanent history stored in `.git/`.

## Creating a Repository

```bash
# Start a brand-new repo in the current folder
git init

# Start a repo in a new folder
git init my-project

# Copy an existing remote repo (and its full history)
git clone https://github.com/user/repo.git
git clone git@github.com:user/repo.git      # via SSH
git clone https://github.com/user/repo.git custom-folder-name
```

## Checking Status and Differences

```bash
git status              # what's changed, staged, or untracked
git status -s           # short format
git diff                # unstaged changes (working dir vs staging)
git diff --staged       # staged changes (staging vs last commit)
git diff HEAD           # all changes since last commit
git diff branch1 branch2   # compare two branches
```

## Staging Changes

```bash
git add file.txt              # stage a specific file
git add file1.txt file2.txt   # stage multiple files
git add folder/               # stage everything in a folder
git add .                     # stage everything in current dir and below
git add -A                    # stage everything in the whole repo
git add -p                    # interactively choose hunks to stage
git restore --staged file.txt # unstage a file (undo git add)
```

## Committing

```bash
git commit -m "Add login form validation"

# Stage all tracked, modified files AND commit in one step
# (does NOT include new/untracked files)
git commit -am "Fix typo in README"

# Open your editor for a longer, multi-line commit message
git commit

# Amend the previous commit (edit message or add forgotten files)
git commit --amend
git commit --amend --no-edit    # keep the same message, just add staged changes
```

### Writing good commit messages

```
Short summary in imperative mood, ≤ 50 chars

Optional longer explanation of *why* the change was made,
wrapped at ~72 characters. Explain the reasoning, not just
what changed (the diff already shows what changed).

Fixes #123
```

Convention: "Add feature" not "Added feature" or "Adds feature" — write as if giving a command.

## Viewing History

```bash
git log                       # full history
git log --oneline             # condensed, one line per commit
git log --oneline --graph --all   # visual branch graph
git log -p                    # show full diffs per commit
git log -5                    # last 5 commits
git log --author="Jane"       # filter by author
git log --since="2 weeks ago"
git log --grep="bugfix"       # search commit messages
git log -- path/to/file.txt   # history of a specific file
git show <commit-hash>        # full details of one commit
git blame file.txt            # who last changed each line
```

## Removing and Renaming

```bash
git rm file.txt                 # delete file + stage the deletion
git rm --cached file.txt        # stop tracking, but keep the local file
git mv old_name.txt new_name.txt   # rename/move + stage it
```

## Ignoring Files: `.gitignore`

Create a `.gitignore` file in your repo root to tell Git which files/folders to never track (build artifacts, dependencies, secrets, OS files):

```gitignore
# Dependencies
node_modules/
vendor/

# Build output
dist/
build/
*.pyc
__pycache__/

# Environment / secrets
.env
.env.local
*.pem

# OS/editor files
.DS_Store
Thumbs.db
.vscode/
.idea/

# Logs
*.log
```

Rules:
- `#` starts a comment
- `*` wildcard matches anything within a path segment
- `**` matches across directories
- `/` at the end matches directories only
- `!` negates a pattern (re-includes something previously ignored)
- A leading `/` anchors the pattern to the repo root

If a file is *already tracked*, adding it to `.gitignore` won't stop Git from tracking it — you must untrack it first:
```bash
git rm --cached file.txt
```

GitHub maintains a large library of starter `.gitignore` templates per language at https://github.com/github/gitignore.

## Undoing Changes (basic)

```bash
git restore file.txt            # discard uncommitted changes in working dir
git restore --staged file.txt   # unstage (keep the changes, just unstage)
git checkout -- file.txt        # older syntax, same as restore
```

See [04-git-advanced.md](04-git-advanced.md) for `reset`, `revert`, and history rewriting.

← Back to [01-introduction.md](01-introduction.md) | Continue to [03-git-branching-merging.md](03-git-branching-merging.md) →
