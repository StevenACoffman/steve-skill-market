# Organizations, SSH/GPG Keys, and Status

## Organizations (`gh org`)

```bash
# List organizations
gh org list

# List for user
gh org list --user username

# JSON output
gh org list --json login,name,description

# View organization
gh org view orgname

# View organization members
gh org view orgname --json members --jq '.members[] | .login'
```

## SSH Keys (`gh ssh-key`)

```bash
# List SSH keys
gh ssh-key list

# Add SSH key
gh ssh-key add ~/.ssh/id_rsa.pub --title "My laptop"

# Add key with type
gh ssh-key add ~/.ssh/id_ed25519.pub --type "authentication"

# Delete SSH key
gh ssh-key delete 12345

# Delete by title
gh ssh-key delete --title "My laptop"
```

## GPG Keys (`gh gpg-key`)

```bash
# List GPG keys
gh gpg-key list

# Add GPG key
gh gpg-key add ~/.ssh/id_rsa.pub

# Delete GPG key
gh gpg-key delete 12345

# Delete by key ID
gh gpg-key delete ABCD1234
```

## Status (`gh status`)

```bash
# Show status overview
gh status

# Status for specific repositories
gh status --repo owner/repo

# JSON output
gh status --json
```
