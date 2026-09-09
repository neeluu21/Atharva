# 3. Branching & Merging

## Why Branch?

A branch is a lightweight, movable pointer to a commit. Branching lets you develop features, fix bugs, or experiment **without touching the stable code** on your main branch. This is Git's most powerful feature.

```
main:     A---B---C---F---G
                \       /
feature:         D-----E
```

## Working with Branches

```bash
git branch                      # list local branches (* marks current)
git branch -a                   # list all branches, including remotes
git branch -r                   # list remote-tracking branches only
git branch new-feature          # create a new branch (doesn't switch to it)
git switch new-feature          # switch to it (modern command)
git checkout new-feature        # switch to it (older command)
git switch -c new-feature       # create AND switch in one step
git checkout -b new-feature     # same, older syntax

git branch -m old-name new-name # rename a branch
git branch -d branch-name       # delete a branch (safe: blocks if unmerged)
git branch -D branch-name       # force-delete a branch (discards work)
```

## Merging

Merging integrates changes from one branch into another.

```bash
git switch main
git merge feature-branch
```

Two kinds of merges:

**1. Fast-forward merge** — happens when `main` hasn't diverged (no new commits since the branch was created). Git just moves the pointer forward; no merge commit is created.

```
Before:  main: A---B
                    \
         feature:    C---D

After:   main: A---B---C---D
```

**2. Three-way (true) merge** — happens when both branches have diverged. Git creates a new **merge commit** with two parents.

```
Before:  main:     A---B-------F
                        \
         feature:        C---D

After:   main:     A---B-------F---M
                        \         /
         feature:        C-----D
```

```bash
git merge feature-branch                 # normal merge
git merge --no-ff feature-branch         # force a merge commit even if fast-forward is possible
git merge --abort                        # cancel a merge with conflicts
```

## Rebasing

Rebasing replays your branch's commits on top of another branch, producing a **linear history** instead of a merge commit.

```
Before:  main:     A---B---F
                        \
         feature:        C---D

After (rebase feature onto main):
         feature:            C'---D'
                            /
         main:     A---B---F
```

```bash
git switch feature-branch
git rebase main
```

**Interactive rebase** — rewrite, reorder, squash, or edit commits before they're finalized:

```bash
git rebase -i HEAD~3     # interactively edit the last 3 commits
```
This opens an editor with options per commit:
```
pick   f7f3f6d Add login form
squash 310154e Fix typo
reword a5f4a0d Update tests
```
- `pick` = keep as-is
- `reword` = keep changes, edit message
- `edit` = pause to amend the commit
- `squash` = combine into previous commit (keep both messages)
- `fixup` = combine into previous commit (discard this message)
- `drop` = remove the commit entirely

### ⚠️ The Golden Rule of Rebasing

**Never rebase commits that have already been pushed and shared with others.** Rebasing rewrites commit history (new hashes), so anyone who already pulled the old commits will get conflicting histories. Only rebase local, unpushed work — or branches you're certain nobody else is using.

## Merge vs. Rebase — When to Use Which

| | Merge | Rebase |
|---|---|---|
| History | Preserves exact history, non-linear | Linear, "cleaner" history |
| Safety | Safe on shared/public branches | Risky on shared branches |
| Merge commits | Creates them | Avoids them |
| Best for | Integrating a finished feature into `main` | Cleaning up your own branch before sharing it |

Common team convention: rebase your feature branch on `main` locally to stay up to date and keep history tidy, but merge (often via a squash merge) into `main` through a pull request.

## Resolving Merge Conflicts

A conflict happens when the same lines were changed differently on both branches. Git pauses and marks the file:

```
<<<<<<< HEAD
This is the version on your current branch.
=======
This is the version from the branch being merged in.
>>>>>>> feature-branch
```

Steps to resolve:
1. Open the file, decide what the final content should be, delete the `<<<<<<<`, `=======`, `>>>>>>>` markers.
2. `git add <file>` to mark it resolved.
3. `git commit` (for a merge) or `git rebase --continue` (for a rebase).

Useful commands during conflicts:
```bash
git status                  # shows which files still have conflicts
git diff                    # shows the conflicting sections
git merge --abort           # bail out and return to pre-merge state
git rebase --abort          # bail out of a rebase
git rebase --skip           # skip the current commit during a rebase
git checkout --ours file.txt    # take your side entirely for this file
git checkout --theirs file.txt  # take their side entirely for this file
```

## Cherry-Picking

Apply a single specific commit from one branch onto another, without merging the whole branch:

```bash
git cherry-pick <commit-hash>
git cherry-pick <hash1> <hash2>   # multiple commits
git cherry-pick --continue        # after resolving a conflict
git cherry-pick --abort
```

← Back to [02-git-basics.md](02-git-basics.md) | Continue to [04-git-advanced.md](04-git-advanced.md) →
