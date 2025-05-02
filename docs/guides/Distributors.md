# Distributors

Distributors are smart contracts that manage the lifecycle, versioning, and distribution of code within EDS. They serve as trusted intermediaries between contracts and end-users, providing a management layer on top of stateless [Distributions](./Distributions.md).

## Core Concepts

The distributor system is built around the abstract `Distributor` contract (`src/distributors/Distributor.sol`), which implements the `IDistributor` interface.

Key functionalities include:

*   **Distribution Registry:** Maintains a registry of distribution components, identified by a unique `distributorId`. Each distribution component consists of:
    *   A `distributionLocation` (the address of either an `IDistribution` contract or an `IRepository` contract)
    *   An optional `initializer` contract address (used for specialized initialization logic during instantiation)
    *   For versioned distributions, it tracks version requirements using `LibSemver`

*   **App Instance Management:** Creates and tracks deployed instances of distributions:
    *   Each time a distribution is instantiated, it's assigned a unique `appId` and the instantiated contract addresses are recorded
    *   Maintains mappings between app components, app IDs, and distributions
    *   Records the installed version of each app instance

*   **Versioning and Migrations:** For versioned distributions (backed by a `Repository`):
    *   Tracks version requirements for distributions
    *   Manages migration plans between different versions
    *   Provides functionality to upgrade app instances from one version to another

*   **ERC7746 Middleware Integration:**
    *   Implements the ERC7746 middleware pattern as a security layer
    *   Provides hooks (`beforeCall`, `afterCall`) that are triggered by proxies during upgrade attempts
    *   Uses these hooks to enforce that only authorized parties (the distributor and the app's installer/owner) can perform upgrades

## Distributor Implementations

Several concrete implementations are provided:

### 1. `OwnableDistributor`

The `OwnableDistributor` contract (`src/distributors/OwnableDistributor.sol`) extends the base `Distributor` with OpenZeppelin's `Ownable` access control. This restricts administration functions to a designated owner, who can:

*   Add new distributions (both unversioned via code hash or versioned via repository)
*   Change version requirements for distributions
*   Disable distributions
*   Add or remove version migrations
*   The `instantiate` function, however, is public, allowing anyone to create instances of registered distributions

### 2. `TokenizedDistributor`

The `TokenizedDistributor` contract (`src/distributors/TokenizedDistributor.sol`) introduces a payment model to the distributor pattern. Key features:

*   Requires payment in a specified ERC20 token to instantiate a distribution
*   Configurable fees per distribution (or a default fee)
*   Payments are forwarded to a designated beneficiary
*   This model allows for monetizing access to managed distributions

### 3. Special Purpose: `WrappedProxyInitializer`

The `WrappedProxyInitializer` contract (`src/distributors/WrappedProxyInitializer.sol`) is not a distributor itself, but a helper contract that implements the `IInitializer` interface. It's used by distributors to:

*   Set up the instantiation flow for `UpgradableDistribution` contracts
*   Properly encode the installer address (the `msg.sender` that calls the distributor) and initialization data
*   Handle error propagation during instantiation
*   This initializer enables distributors to create proxies where the caller becomes the proxy owner/installer, while the distributor remains as the admin/middleware

## Upgrade Flow with ERC7746

A key feature of distributors is their role in the multi-party upgrade process:

1.  A distributor maintains a registry of app instances and their versions
2.  When an upgrade is initiated (via `upgradeUserInstance`), the distributor:
    *   Verifies that the app is valid and a migration plan exists for the target version
    *   Executes the migration, which may involve calling a migration script or directly upgrading the proxy
    *   During the upgrade, the proxy's ERC7746 middleware call is intercepted by the distributor's hooks
    *   The hooks verify that both the distributor and the app's installer consent to the upgrade
3.  This design ensures that neither the distributor nor the installer can unilaterally force an upgrade

For details on how this works at the proxy level, see the [Upgradability](./Upgradability.md) documentation.

## CLI Operations

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
eds distributor <address> migration list [--distribution <n>]

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








