# Distributors

Distributors are contracts that are used to provide trusted sources to end-users from a entity owned domain.

Distributors may implement business & protocol logic adhoc, example of such may be building security oracles, compliance engines, or other custom logic.

## Creating a distributor

There are readily available distributors in [src/distributors](../src/distributors) directory.

You can use them as is or extend them to fit your needs.

## Using Installer with ERC7746 web3hooks

Distributions that use [ERC7746](./ERC7746.md) middleware approach, or that are installed via [Installer](./Installer.md) can be runtime verified by Distributor.

Distributor gets called with `beforeCall` and `afterCall` hooks and can revert the call.

## Operating Distributor with CLI:

> [!NOTE]
> The CLI provides utilities to manage distributors.

```bash
# Deploy a new distributor
eds distributor deploy --name <distributor-name> [--options]

# List all distributions in a distributor
eds distributor <address> list [--format json|table]

# Get info about a specific distribution
eds distributor <address> info <distribution-name>

# Add an unversioned distribution
eds distributor <address> add unversioned <distribution-codehash> <initializer-address> --name <distribution-name>

# Add a versioned distribution
eds distributor <address> add versioned <repository-address> <initializer-address> --name <distribution-name> --version <version-requirement>

# Remove a distribution
eds distributor <address> remove <distribution-name>

# Change the version requirement for a distribution
eds distributor <address> version change <distribution-name> --version <version-requirement>

# Add a migration for version upgrades
eds distributor <address> migration add <migration-hash> --name <distribution-name> --from-version <version> --to-version <version> --strategy <CALL|DELEGATECALL|DELEGATE_REPOSITORY> [--calldata <data>]

# Remove a migration
eds distributor <address> migration remove <migration-hash>

# List all migrations
eds distributor <address> migration list [--distribution <name>]

# Enable a distribution
eds distributor <address> enable <distribution-name>

# Disable a distribution
eds distributor <address> disable <distribution-name>

# Common options available for all commands
--rpc-url <url>       # RPC endpoint
--private-key <key>   # Private key for transactions
--gas-limit <limit>   # Optional gas limit
--gas-price <price>   # Optional gas price
```








