# 7. Quick Reference Cheatsheet

## Setup
```bash
git config --global user.name "Name"
git config --global user.email "email@example.com"
git init                          # new local repo
git clone <url>                   # copy a remote repo
```

## Daily Workflow
```bash
git status                        # what's changed
git add <file>                    # stage a file
git add .                         # stage everything
git commit -m "message"           # commit staged changes
git push                          # send commits to remote
git pull                          # get + merge remote changes
git log --oneline --graph --all   # visualize history
```

## Branching
```bash
git branch                        # list branches
git switch -c new-branch          # create + switch
git switch main                   # switch branch
git merge feature-branch          # merge into current branch
git branch -d branch-name         # delete (safe)
```

## Undo
```bash
git restore <file>                # discard working-dir changes
git restore --staged <file>       # unstage
git reset --soft HEAD~1           # undo commit, keep changes staged
git reset --hard HEAD~1           # undo commit, discard changes (destructive)
git revert <commit>               # safely undo via a new commit
git commit --amend                # fix last commit
```

## Inspecting
```bash
git diff                          # unstaged changes
git diff --staged                 # staged changes
git show <commit>                 # details of one commit
git blame <file>                  # who changed each line
```

## Stashing
```bash
git stash                         # shelve changes
git stash pop                     # bring them back
git stash list                    # see all stashes
```

## Remotes
```bash
git remote -v                     # list remotes
git remote add origin <url>       # link to GitHub
git push -u origin main           # push + set upstream
git fetch                         # download without merging
```

## Tags
```bash
git tag -a v1.0 -m "message"      # create annotated tag
git push origin v1.0              # push a tag
```

## Rebase (use only on unpushed/private commits)
```bash
git rebase main                   # replay current branch onto main
git rebase -i HEAD~3              # interactive rebase, last 3 commits
git rebase --continue / --abort
```

## Common Situations → Commands

| I want to... | Command |
|---|---|
| Start tracking a new project | `git init` |
| Get a copy of a GitHub repo | `git clone <url>` |
| See what I've changed | `git status` / `git diff` |
| Save my progress | `git add . && git commit -m "..."` |
| Send my work to GitHub | `git push` |
| Get others' work | `git pull` |
| Try something without risk | `git switch -c experiment` |
| Combine two branches | `git switch main && git merge feature` |
| Fix my last commit message | `git commit --amend` |
| Undo my last commit (keep changes) | `git reset --soft HEAD~1` |
| Throw away all local changes | `git restore .` |
| Temporarily set aside changes | `git stash` |
| Find which commit broke something | `git bisect start` |
| Recover a "lost" commit | `git reflog` |
| Update my fork from the original repo | `git fetch upstream && git merge upstream/main` |

## GitHub-Specific Quick Actions (via `gh` CLI)
```bash
gh repo create my-project --public
gh pr create --fill
gh pr checkout 42
gh pr merge 42 --squash
gh issue create --title "Bug: ..." --body "..."
```

← Back to [06-github-collaboration.md](06-github-collaboration.md) | Back to [README.md](README.md)
