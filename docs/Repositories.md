# Repositories

Repositories are used to list and manage distributions.

Repositories are made for developer convenience in case when continous improvements are expected. They are thought as abstraction layer above single Distributions and allow versioning code using [Versioning](./Versioning.md) system.

## CLI

> [!NOTE]
> The CLI provides utilities to manage repositories.

```bash
# Deploy a new repository
eds repository deploy --name <repository-name> [--options]

# List all versions in a repository
eds repository <address> list [--format json|table]

# Get the latest version
eds repository <address> latest

# Get a specific version that satisfies requirements
eds repository <address> get --version <version-requirement>

# Resolve a version requirement to a specific version
eds repository <address> resolve --version <version-requirement>

# Add a new version to the repository
eds repository <address> put <source-hash> --version <version> [--metadata <metadata>] [--migration <migration-hash>]

# Get a migration script for a major version
eds repository <address> migration get <major-version>

# Set a migration script for a major version
eds repository <address> migration set <major-version> <migration-hash>

# Get the repository name
eds repository <address> name

# Get metadata for a specific version
eds repository <address> metadata get <version>

# Update metadata for a specific version
eds repository <address> metadata put <version> --metadata <metadata>

# Common options available for all commands
--rpc-url <url>       # RPC endpoint
--private-key <key>   # Private key for transactions
--gas-limit <limit>   # Optional gas limit
--gas-price <price>   # Optional gas price
```

