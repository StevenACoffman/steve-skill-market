# Extensions, Aliases, and Other Commands

## Extensions (`gh extension`)

```bash
# List installed extensions
gh extension list

# Search extensions
gh extension search github

# Install extension
gh extension install owner/extension-repo

# Install from branch
gh extension install owner/extension-repo --branch develop

# Upgrade extension
gh extension upgrade extension-name

# Remove extension
gh extension remove extension-name

# Create new extension
gh extension create my-extension

# Browse extensions
gh extension browse

# Execute extension command
gh extension exec my-extension --arg value
```

## Aliases (`gh alias`)

```bash
# List aliases
gh alias list

# Set alias
gh alias set prview 'pr view --web'

# Set shell alias
gh alias set co 'pr checkout' --shell

# Delete alias
gh alias delete prview

# Import aliases
gh alias import ./aliases.sh
```

## Rulesets (`gh ruleset`)

```bash
# List rulesets
gh ruleset list

# View ruleset
gh ruleset view 123

# Check ruleset
gh ruleset check --branch feature

# Check specific repository
gh ruleset check --repo owner/repo --branch main
```

## Attestations (`gh attestation`)

```bash
# Download attestation
gh attestation download owner/repo \
  --artifact-id 123456

# Verify attestation
gh attestation verify owner/repo

# Get trusted root
gh attestation trusted-root
```

## Completion (`gh completion`)

```bash
# Generate shell completion
gh completion -s bash >~/.gh-complete.bash
gh completion -s zsh >~/.gh-complete.zsh
gh completion -s fish >~/.gh-complete.fish
gh completion -s powershell >~/.gh-complete.ps1

# Shell-specific instructions
gh completion --shell=bash
gh completion --shell=zsh
```

## Preview (`gh preview`)

```bash
# List preview features
gh preview

# Run preview script
gh preview prompter
```

## Agent Tasks (`gh agent-task`)

```bash
# List agent tasks
gh agent-task list

# View agent task
gh agent-task view 123

# Create agent task
gh agent-task create --description "My task"
```
