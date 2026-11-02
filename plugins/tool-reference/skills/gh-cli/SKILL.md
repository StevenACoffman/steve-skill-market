---
name: gh-cli
description: |
  Use when performing any GitHub operation from the command line — creating PRs, managing issues, checking Actions status, working with releases, gists, codespaces, or organizations. Comprehensive reference for the gh CLI.
---

# GitHub CLI (`gh`)

Comprehensive reference for GitHub CLI (`gh`) - work seamlessly with GitHub from the command line.

**Version:** 2.85.0 (current as of January 2026)

## Prerequisites

### Installation

```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt update
sudo apt install gh

# Windows
winget install --id GitHub.cli

# Verify installation
gh --version
```

### Authentication

```bash
# Interactive login (default: github.com)
gh auth login

# Login with specific hostname
gh auth login --hostname enterprise.internal

# Login with token
gh auth login --with-token <mytoken.txt

# Check authentication status
gh auth status

# Switch accounts
gh auth switch --hostname github.com --user username

# Logout
gh auth logout --hostname github.com --user username
```

### Setup Git Integration

```bash
# Configure git to use gh as credential helper
gh auth setup-git

# View active token
gh auth token

# Refresh authentication scopes
gh auth refresh --scopes write:org,read:public_key
```

## Reference Files

The full per-command catalog lives in `references/`. Read only the file for the task at hand:

- [`references/cli-structure.md`](references/cli-structure.md) — read to find which command or subcommand exists.
- [`references/config-and-auth.md`](references/config-and-auth.md) — read when logging in, switching accounts, refreshing scopes, setting `gh config` values, or using environment variables such as `GH_TOKEN` and `GH_REPO`.
- [`references/repos.md`](references/repos.md) — read when creating, cloning, forking, syncing, editing, or deleting repositories, setting the default repo, or using `gh browse`.
- [`references/issues.md`](references/issues.md) — read when creating, listing, editing, closing, commenting on, or transferring issues, or managing labels.
- [`references/pull-requests.md`](references/pull-requests.md) — read when creating, reviewing, checking out, merging, or editing pull requests.
- [`references/actions.md`](references/actions.md) — read when inspecting workflow runs, triggering workflows, or managing caches, secrets, and variables.
- [`references/projects.md`](references/projects.md) — read when working with GitHub Projects.
- [`references/releases.md`](references/releases.md) — read when creating, editing, downloading, or deleting releases.
- [`references/gists-codespaces.md`](references/gists-codespaces.md) — read when working with gists or codespaces.
- [`references/account-and-org.md`](references/account-and-org.md) — read when listing organizations, managing SSH or GPG keys, or using `gh status`.
- [`references/search.md`](references/search.md) — read when searching repos, issues, PRs, code, or commits.
- [`references/api.md`](references/api.md) — read when calling the REST or GraphQL API directly with `gh api`.
- [`references/extensions-and-other.md`](references/extensions-and-other.md) — read when using extensions, aliases, rulesets, attestations, shell completion, `gh preview`, or agent tasks.

## Global Flags

| Flag                       | Description                            |
| -------------------------- | -------------------------------------- |
| `--help` / `-h`            | Show help for command                  |
| `--version`                | Show gh version                        |
| `--repo [HOST/]OWNER/REPO` | Select another repository              |
| `--hostname HOST`          | GitHub hostname                        |
| `--jq EXPRESSION`          | Filter JSON output                     |
| `--json FIELDS`            | Output JSON with specified fields      |
| `--template STRING`        | Format JSON using Go template          |
| `--web`                    | Open in browser                        |
| `--paginate`               | Make additional API calls              |
| `--verbose`                | Show verbose output                    |
| `--debug`                  | Show debug output                      |
| `--timeout SECONDS`        | Maximum API request duration           |
| `--cache CACHE`            | Cache control (default, force, bypass) |

## Output Formatting

### JSON Output

```bash
# Basic JSON
gh repo view --json name,description

# Nested fields
gh repo view --json owner,name --jq '.owner.login + "/" + .name'

# Array operations
gh pr list --json number,title --jq '.[] | select(.number > 100)'

# Complex queries
gh issue list --json number,title,labels \
  --jq '.[] | {number, title: .title, tags: [.labels[].name]}'
```

### Template Output

```bash
# Custom template
gh repo view \
  --template '{{.name}}: {{.description}}'

# Multiline template
gh pr view 123 \
  --template 'Title: {{.title}}
Author: {{.author.login}}
State: {{.state}}
'
```

## Common Workflows

### Create PR from Issue

```bash
# Create branch from issue
gh issue develop 123 --branch feature/issue-123

# Make changes, commit, push
git add .
git commit -m "Fix issue #123"
git push

# Create PR linking to issue
gh pr create --title "Fix #123" --body "Closes #123"
```

### Bulk Operations

```bash
# Close multiple issues
gh issue list --search "label:stale" \
  --json number \
  --jq '.[].number' |
  xargs -I {} gh issue close {} --comment "Closing as stale"

# Add label to multiple PRs
gh pr list --search "review:required" \
  --json number \
  --jq '.[].number' |
  xargs -I {} gh pr edit {} --add-label needs-review
```

### Repository Setup Workflow

```bash
# Create repository with initial setup
gh repo create my-project --public \
  --description "My awesome project" \
  --clone \
  --gitignore python \
  --license mit

cd my-project

# Set up branches
git checkout -b develop
git push -u origin develop

# Create labels
gh label create bug --color "d73a4a" --description "Bug report"
gh label create enhancement --color "a2eeef" --description "Feature request"
gh label create documentation --color "0075ca" --description "Documentation"
```

### CI/CD Workflow

```bash
# Run workflow and wait
RUN_ID=$(gh workflow run ci.yml --ref main --jq '.databaseId')

# Watch the run
gh run watch "$RUN_ID"

# Download artifacts on completion
gh run download "$RUN_ID" --dir ./artifacts
```

### Fork Sync Workflow

```bash
# Fork repository
gh repo fork original/repo --clone

cd repo

# Add upstream remote
git remote add upstream https://github.com/original/repo.git

# Sync fork
gh repo sync

# Or manual sync
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

## Best Practices

1. **Authentication**: Use environment variables for automation

   ```bash
   export GH_TOKEN=$(gh auth token)
   ```

2. **Default Repository**: Set default to avoid repetition

   ```bash
   gh repo set-default owner/repo
   ```

3. **JSON Parsing**: Use jq for complex data extraction

   ```bash
   gh pr list --json number,title --jq '.[] | select(.title | contains("fix"))'
   ```

4. **Pagination**: Use --paginate for large result sets

   ```bash
   gh issue list --state all --paginate
   ```

5. **Caching**: Use cache control for frequently accessed data

   ```bash
   gh api /user --cache force
   ```

## Getting Help

```bash
# General help
gh --help

# Command help
gh pr --help
gh issue create --help

# Help topics
gh help formatting
gh help environment
gh help exit-codes
gh help accessibility
```

## References

- Official Manual: <https://cli.github.com/manual/>
- GitHub Docs: <https://docs.github.com/en/github-cli>
- REST API: <https://docs.github.com/en/rest>
- GraphQL API: <https://docs.github.com/en/graphql>
