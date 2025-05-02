# Upgradeability in EDS

## Introduction

EDS implements a multi-party trust model for contract upgradeability. This model ensures both distributors and end-users have control over the upgrade process, creating a balance of power that prevents either party from unilaterally forcing upgrades.

## Trust Model & Security Architecture

Upgradeability in EDS is built on a carefully designed trust model with clear boundaries between different domains:

**1. Ethereum (blockchain consensus) domain:**
- The [ERC7744 Indexer](./Indexer.md) serves as the foundational layer, trusted by all parties to reference code by its bytecode hash.
- [Distributions](./Distributions.md) maintain their trust by exclusively using the ERC7744 Indexer to reference code objects.

**2. Developer domain:**
- Developers manage [Repositories](./Repositories.md) that index their code versions.
- They define upgrade paths and may implement migration scripts for major version changes.
- Developers trust the ERC7744 Indexer and can list any of their developed distributions in their repositories.

**3. Distributor domain:**
- Distributors curate which distributions and versions they support.
- They define migration plans for supporting upgrades between versions.
- They act as middlewares for runtime verification and upgrade transactions.
- Distributors trust the code indexed by ERC7744 and explicitly listed in their registries.

**4. End-user (Installer) domain:**
- End-users interact with applications through the [Installer](./Installer.md) contract.
- They choose which distributor to trust for a given application.
- They must explicitly consent to any upgrade through the middleware pattern.

## ERC7746 Middleware & Web3 Hooks

The core of the upgrade security model is the ERC7746 middleware pattern, implemented through the `ERC7746Hooked` and `LibMiddleware` components.

### How the Middleware Works:

1. Proxies like `WrappedTransparentUpgradeableProxy` inherit from `ERC7746Hooked` and apply the `ERC7746` modifier to their `fallback()` function.

2. When functions related to proxy administration (particularly `upgradeToAndCall`) are invoked, the modifier:
   - Calls `LibMiddleware.beforeCall()`, which iterates through registered middleware layers.
   - Each layer (notably the distributor) can validate the call and enforce rules.
   - After the function executes, `LibMiddleware.afterCall()` is called in reverse order.
   - Middleware layers can perform post-execution validations or cleanup.

3. This middleware pattern is used for two key scenarios:
   - **Upgrades:** To ensure both distributor and end-user consent to upgrades.
   - **Cross-app Interactions:** To verify that interactions between applications follow distributor-defined rules.

### Call Flow During an Upgrade:

```
When upgradeToAndCall is invoked:
  - beforeCall: Proxy → Distributor  (validateLayerBeforeCall)
  - Actual upgradeToAndCall function execution
  - afterCall: Distributor → Proxy (validateLayerAfterCall)
```

## Upgradeable Proxy Architecture

EDS uses a specialized proxy implementation, `WrappedTransparentUpgradeableProxy`, which extends OpenZeppelin's `TransparentUpgradeableProxy` with ERC7746 middleware capabilities.

Key features:

1. **Dual Authority Model:**
   - The proxy has a standard **owner** (typically the end-user/installer) who controls standard admin functions.
   - The proxy also has an **admin** (typically the distributor) who controls implementation upgrades.
   - The admin is also registered as the sole middleware layer using `LibMiddleware.setLayers()`.

2. **Upgrade Protection:**
   - Upgrade attempts trigger the ERC7746 middleware hooks.
   - The distributor can validate that the upgrade follows its version and migration policies.
   - The installer can validate that it has authorized the upgrade through a separate channel.

3. **Deployment Flow:**
   - The proxy is deployed by the `UpgradableDistribution` contract.
   - The end-user is set as the owner.
   - The distributor (instantiator) is set as the admin and middleware layer.

## Upgrade Process

The complete upgrade flow combines distributor, installer, and proxy mechanisms:

1. **Preparation:**
   - A distributor adds a new version to its supported versions list.
   - The distributor defines a migration plan using `addVersionMigration()`.

2. **Initiation:**
   - The installer (end-user) signals upgrade intent by calling its `upgradeApp()` function.
   - The installer sets a flag indicating the app is in upgrade mode.

3. **Execution:**
   - The installer calls the distributor's `upgradeUserInstance()` function.
   - The distributor validates the upgrade request against its policies.
   - The distributor executes the migration plan based on the selected strategy:
     - **CALL:** Directly calls a migration contract
     - **DELEGATECALL:** Uses delegatecall to a migration contract
     - **DELEGATE_REPOSITORY:** Executes migrations defined in the repository

4. **Proxy Upgrade:**
   - The migration ultimately calls `upgradeToAndCall()` on the proxy.
   - This triggers the ERC7746 middleware hooks.
   - The distributor validates the upgrade is the one it initiated.
   - The installer validates the upgrade was initiated by itself.

5. **Completion:**
   - The proxy's implementation is updated.
   - The installer clears the upgrade mode flag.
   - The distributor updates its record of the app's version.

## Migration Plans

Migration plans define how to transition between versions:

```solidity
struct MigrationPlan {
    LibSemver.VersionRequirement from;
    LibSemver.VersionRequirement to;
    IMigration migrationContract;
    MigrationStrategy strategy;
}
```

### Strategies:

1. **CALL:**
   - The distributor calls the migration contract directly.
   - The migration contract handles all upgrade logic.

2. **DELEGATECALL:**
   - The distributor performs a delegatecall to the migration contract.
   - The migration contract executes with the distributor's storage context.

3. **DELEGATE_REPOSITORY:**
   - The distributor delegates to migrations defined in the repository.
   - For major version changes, it executes sequential migrations (e.g., v1→v2→v3).
   - The repository's defined migrations handle state transformations.

## Renouncing Distributor Control

End-users can permanently or temporarily remove a distributor's upgrade control:

- The installer can call `changeDistributor()` to:
  - Transfer control to a new distributor
  - Completely renounce distributor control
  - Transfer control directly to the end-user

- This process:
  - Updates the installer's records
  - Calls the distributor to inform it of the change
  - For `WrappedTransparentUpgradeableProxy`, transfers the admin role accordingly

> [!WARNING]
> Renouncing distributor control means losing access to guided upgrades and any security or compliance features the distributor provides. This should be done with caution.

## CLI Operations

> [!NOTE]
> The CLI provides utilities to manage upgrades.

```bash
# View available versions for an app
eds installer app <app-id> versions

# Initiate an upgrade
eds installer app <app-id> upgrade --version <version>

# Get migration information
eds distributor <address> migration list --app <app-id>

# Add a migration plan
eds distributor <address> migration add <migration-hash> --name <distribution-name> --from <version> --to <version> --strategy <strategy>

# Change distributor
eds installer app <app-id> change-distributor <new-distributor>

# Renounce distributor
eds installer app <app-id> renounce-distributor

# Common options available for all commands
--rpc-url <url>       # RPC endpoint
--private-key <key>   # Private key for transactions