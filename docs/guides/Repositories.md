# Repositories

Repositories are smart contracts designed to list and manage distributions, providing a versioning system for scenarios where continuous improvements are expected. They act as an abstraction layer over individual Distribution sources, leveraging the [Versioning](./Versioning.md) system.

## Core Concepts

The repository system is built around the abstract `Repository` contract (`src/repositories/Repository.sol`), which implements the `IRepository` interface. Key functionalities include:

*   **Versioning:** Manages releases using semantic versioning (Major.Minor.Patch). It tracks the latest version and enforces sequential increments for new releases (`_newRelease`).
*   **Source Management:** Maps each specific version (Major.Minor.Patch) to a `sourceId` (typically a hash or identifier pointing to the distribution source) using the `versionedSources` mapping. The `LibERC7744` library is utilized, often for source identification.
*   **Metadata:** Stores metadata associated with releases at different levels:
    *   Major version metadata (`releaseMetadata`).
    *   Minor version metadata (`minorReleaseMetadata`).
    *   Patch version metadata (`patchReleaseMetadata`).
    *   Metadata can be updated using `_updateReleaseMetadata`. The `get` function automatically combines metadata from all relevant levels for a resolved version.
*   **Migration Scripts:** Allows associating an immutable migration script (identified by its hash/`sourceId`) with each major version (`releaseMigrationHash`). This script can be retrieved using `getMigrationScript` and updated via `_changeMigrationScript`. Migration scripts are only allowed when introducing a new major version.
*   **Version Resolution:** Provides functions like `get` and `resolveVersion` to find the appropriate version based on version requirements (e.g., exact version, latest major, latest minor, greater/less than).
*   **Contract URI:** Supports EIP-721's `contractURI` method to link to off-chain metadata about the repository itself.

A common concrete implementation is `OwnableRepository` (`src/repositories/OwnableRepository.sol`), which inherits from `Repository` and adds `Ownable` access control. This means functions like `newRelease`, `updateReleaseMetadata`, and `changeMigrationScript` can only be called by the contract owner.

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

