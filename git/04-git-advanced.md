# 4. Advanced Git

## Stashing

Temporarily shelve uncommitted changes so you can switch context, then bring them back later.

```bash
git stash                      # stash tracked, modified changes
git stash -u                   # also stash untracked files
git stash save "wip: login"    # stash with a message
git stash list                 # see all stashes
git stash show -p stash@{0}    # view contents of a stash
git stash pop                  # reapply the most recent stash AND remove it
git stash apply                # reapply but KEEP it in the stash list
git stash apply stash@{2}      # apply a specific stash
git stash drop stash@{0}       # delete a specific stash
git stash clear                # delete all stashes
git stash branch new-branch    # create a new branch from a stash
```

## Undoing Things: `reset`, `revert`, `restore`

These three are easy to confuse:

| Command | Effect | Rewrites history? | Safe on shared branches? |
|---|---|---|---|
| `git restore` | Discard changes in working directory / unstage | No | Yes |
| `git reset` | Move the branch pointer (and optionally undo staging/working changes) | Yes | No |
| `git revert` | Create a *new* commit that undoes a previous commit | No | Yes |

### `git reset`

```bash
git reset --soft HEAD~1    # undo last commit, keep changes staged
git reset --mixed HEAD~1   # undo last commit, keep changes unstaged (default)
git reset --hard HEAD~1    # undo last commit, DISCARD all changes entirely (destructive)

git reset <commit-hash>    # move branch pointer to a specific commit
git reset --hard origin/main   # force local branch to exactly match a remote
```

⚠️ `--hard` permanently discards uncommitted work. Use with caution.

### `git revert`

```bash
git revert <commit-hash>          # create a new commit undoing that commit
git revert HEAD                   # undo the most recent commit
git revert HEAD~3..HEAD           # revert a range of commits
git revert -n <commit-hash>       # revert without auto-committing (stage only)
```
Because `revert` adds new history instead of erasing old history, it's the safe choice once commits have been pushed/shared.

## Tags

Tags mark specific points in history — typically used for releases (`v1.0.0`).

```bash
git tag                          # list tags
git tag v1.0.0                   # lightweight tag on current commit
git tag -a v1.0.0 -m "Version 1.0.0"   # annotated tag (recommended: stores author, date, message)
git tag -a v1.0.0 <commit-hash>  # tag a specific past commit
git show v1.0.0                  # view tag details

git push origin v1.0.0           # push a single tag
git push origin --tags           # push all tags

git tag -d v1.0.0                        # delete a local tag
git push origin --delete v1.0.0          # delete a remote tag
```

## Submodules

Include another Git repository inside your repository (e.g., a shared library).

```bash
git submodule add https://github.com/user/lib.git path/to/lib
git submodule init
git submodule update
git clone --recurse-submodules <url>      # clone a repo AND its submodules
git submodule update --remote             # pull latest changes into submodules
```
Submodules are notoriously fiddly; many teams prefer package managers or monorepos instead where practical.

## The Reflog — Your Safety Net

Git keeps a log of every place `HEAD` has pointed, even after resets, rebases, or deleted branches. This can recover "lost" commits.

```bash
git reflog
# example output:
# a1b2c3d HEAD@{0}: commit: Add feature
# e4f5g6h HEAD@{1}: reset: moving to HEAD~1

git reset --hard HEAD@{1}      # jump back to a previous state
git checkout a1b2c3d           # recover a specific "lost" commit
```

## Hooks

Scripts that run automatically at certain points in Git's workflow. Stored (unpushed, local-only) in `.git/hooks/`.

Common hooks: `pre-commit`, `commit-msg`, `pre-push`, `post-merge`.

```bash
# Example: .git/hooks/pre-commit (must be executable: chmod +x)
#!/bin/sh
npm test
```
For shareable, team-wide hooks, tools like **Husky** (JS) or **pre-commit** (Python) are commonly used, since native hooks aren't tracked by Git itself.

## Searching History

```bash
git log -S "functionName"          # find commits that added/removed a string (pickaxe search)
git log -G "regex pattern"         # search with a regex
git grep "TODO"                    # search the working tree
git bisect start                   # binary search for the commit that introduced a bug
git bisect bad                     # mark current commit as broken
git bisect good <commit-hash>      # mark a known-good commit
# Git checks out a midpoint; keep marking good/bad until it finds the culprit
git bisect reset                   # end the bisect session
```

## Worktrees

Check out multiple branches into separate folders simultaneously, without cloning multiple times:

```bash
git worktree add ../hotfix-dir hotfix-branch
git worktree list
git worktree remove ../hotfix-dir
```

## Rewriting History Broadly

```bash
git commit --amend                       # fix the most recent commit
git rebase -i <commit-hash>              # edit multiple commits (see file 3)
git filter-repo --path secrets.txt --invert-paths   # remove a file from ALL history (requires git-filter-repo tool)
```
⚠️ Rewriting published history requires a force-push and coordination with your team (see file 5's note on `--force-with-lease`).

## Performance & Maintenance

```bash
git gc                    # garbage-collect, compress repo data
git fsck                  # check repository integrity
git count-objects -v      # see repo size stats
```

← Back to [03-git-branching-merging.md](03-git-branching-merging.md) | Continue to [05-github-basics.md](05-github-basics.md) →
