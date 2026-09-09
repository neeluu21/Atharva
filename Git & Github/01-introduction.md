# 1. Introduction to Git & GitHub

## What is Git?

Git is a **distributed version control system (DVCS)** created by Linus Torvalds in 2005 to manage the Linux kernel source code. It tracks changes to files over time so you can:

- Recall specific versions later
- See who changed what, and when
- Work on multiple features in parallel (branches)
- Merge changes from multiple people without losing work
- Revert mistakes safely

"Distributed" means every developer has a **full copy of the entire history** on their own machine — not just the latest snapshot. This makes Git fast, resilient (no single point of failure), and usable offline.

## What is GitHub?

GitHub is a **cloud hosting service for Git repositories**. Git itself is just the version control engine; GitHub adds:

- Remote storage for repositories
- A web UI for browsing code and history
- Pull requests (structured code review before merging)
- Issue tracking and project boards
- GitHub Actions (CI/CD automation)
- Team/organization permission management
- Social features: stars, forks, followers

Git works fine without GitHub (e.g., you can host repos yourself or use GitLab/Bitbucket). GitHub is one popular *host* for Git repositories — the most widely used one.

## Installing Git

**Windows:**
Download from https://git-scm.com/download/win and run the installer.

**macOS:**
```bash
brew install git
# or it comes bundled with Xcode Command Line Tools
xcode-select --install
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt update
sudo apt install git
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install git
```

Verify installation:
```bash
git --version
```

## Initial Configuration

Before your first commit, tell Git who you are — this information is embedded in every commit you make.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Other useful global settings:

```bash
# Set default branch name for new repos
git config --global init.defaultBranch main

# Set your default text editor (used for commit messages, etc.)
git config --global core.editor "code --wait"   # VS Code
git config --global core.editor "vim"           # Vim
git config --global core.editor "nano"          # Nano

# Enable helpful colored output
git config --global color.ui auto

# Set a default merge/pull behavior
git config --global pull.rebase false   # merge (default)
# or
git config --global pull.rebase true    # rebase instead of merge

# View all current settings
git config --list

# View where a setting came from
git config --list --show-origin
```

Configuration is stored in three possible scopes, in order of precedence (most specific wins):

| Scope | Flag | File location |
|---|---|---|
| System | `--system` | `/etc/gitconfig` |
| Global (user) | `--global` | `~/.gitconfig` |
| Local (repo) | `--local` (default) | `.git/config` inside the repo |

## Connecting to GitHub

You need to authenticate before you can push to GitHub. Two main methods:

### SSH (recommended)

```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "you@example.com"

# Start the ssh-agent and add your key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy the public key
cat ~/.ssh/id_ed25519.pub
```
Paste the copied key into **GitHub → Settings → SSH and GPG keys → New SSH key**.

Test the connection:
```bash
ssh -T git@github.com
```

### HTTPS with a Personal Access Token (PAT)

GitHub no longer accepts your account password for Git operations over HTTPS. Instead, generate a token at **GitHub → Settings → Developer settings → Personal access tokens**, and use it in place of a password when prompted, or store it via a credential manager:

```bash
git config --global credential.helper cache      # temporary cache
git config --global credential.helper store      # persistent (less secure)
# macOS
git config --global credential.helper osxkeychain
# Windows
git config --global credential.helper manager
```

## Core Concepts at a Glance

| Term | Meaning |
|---|---|
| Repository (repo) | A project tracked by Git; contains all files and their full history |
| Commit | A saved snapshot of changes, with a message and unique ID (SHA hash) |
| Branch | An independent line of development |
| Remote | A version of your repo hosted elsewhere (e.g., on GitHub) |
| Clone | Downloading a full copy of a remote repo |
| Working directory | The actual files on your disk |
| Staging area (index) | A holding area for changes you're about to commit |
| `.git` folder | Hidden folder holding the entire repository's history and metadata |

Continue to [02-git-basics.md](02-git-basics.md) →
