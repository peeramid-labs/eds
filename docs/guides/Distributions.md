# Distributions

Distributions are smart contracts serving as the primary mechanism within EDS for deploying instances of specific contract logic. They encapsulate the source code (or a reference to it) and provide methods to instantiate it, potentially applying versioning or upgradability patterns.

Distributions are generally designed to be stateless, focusing solely on deploying logic. Managing the state *of* deployed instances is typically handled by users or specialized [Distributors](./Distributors.md).

> [!WARNING]
> Deploying stateful logic directly within a Distribution contract itself is discouraged. It complicates upgrades and may interfere with indexers like the [Indexer](./Indexer.md) that rely on bytecode hashes. Use a [Distributor](./Distributors.md) for managing stateful application logic built upon stateless Distribution sources.

## Distribution Types

EDS provides several base distribution contracts:

### 1. Clone-Based Distributions (`CloneDistribution`)

The abstract `CloneDistribution` contract (`src/distributions/CloneDistribution.sol`) serves as a base for distributions that deploy new instances using `Clones.clone`. Concrete implementations must override the `sources()` function to return the address(es) of the logic contract(s) to be cloned, along with the distribution's name and version.

Its `instantiate` function (called via `_instantiate`) clones the source(s) and emits a `Distributed` event.

#### Example: `CodeHashDistribution`

`CodeHashDistribution` (`src/distributions/CodeHashDistribution.sol`) extends `CloneDistribution`. It's initialized with a `codeHash` (referencing code indexed by the [Indexer](./Indexer.md)), metadata, name, and version. Its `sources()` implementation resolves the `codeHash` to the deployed contract address using `LibERC7744.getContainerOrThrow()` and returns that address to be cloned.

```solidity
// Example: Deploying a CodeHashDistribution
// Assume MyLogicContract code is indexed and its hash is CODE_HASH
bytes32 name = "MyDistribution";
uint256 version = LibSemver.toUint256(LibSemver.Version(1, 0, 0));
bytes32 metadata = bytes32(0); // Optional metadata
CodeHashDistribution myDist = new CodeHashDistribution(CODE_HASH, metadata, name, version);

// Later, anyone can instantiate it (if stateless)
(address[] memory instances, ,) = myDist.instantiate(""); // data is unused in base CloneDistribution
address myInstance = instances[0];
```

#### Example: `LatestVersionDistribution`

`LatestVersionDistribution` (`src/distributions/LatestVersionDistribution.sol`) also extends `CloneDistribution`. It links to a [Repository](./Repositories.md). Its `sources()` implementation calls `repository.getLatest()` to find the `sourceId` of the latest version in the repository, resolves it to an address using `LibERC7744.getContainerOrThrow()`, and returns that address to be cloned. This ensures users always instantiate the most recent version available in the linked repository.

### 2. Upgradable Distributions (`UpgradableDistribution`)

The `UpgradableDistribution` contract (`src/distributions/UpgradableDistribution.sol`) provides a mechanism for deploying instances that follow a specific upgradability pattern, integrating with [Distributors](./Distributors.md) and the [Upgradability](./Upgradability.md) flow. It does *not* inherit from `CloneDistribution`.

**Mechanism:**

1.  It's initialized similarly to `CodeHashDistribution` with a `codeHash`, metadata, name, and version.
2.  Its `instantiate` function requires ABI-encoded `data` containing the `installer` address and initialization `args` for the proxy.
3.  Crucially, `instantiate` deploys a `WrappedTransparentUpgradeableProxy` (`src/proxies/WrappedTransparentUpgradeableProxy.sol`) for each source.
4.  When creating the `WrappedTransparentUpgradeableProxy`:
    *   The logic contract address (resolved from `codeHash`) is set as the implementation.
    *   The **installer** address (from `data`) is set as the proxy's *owner*.
    *   The **distributor** address (`msg.sender` of the `instantiate` call) is set as the proxy's *admin* and registered as the sole middleware layer using `ERC7746Hooked` (`src/middleware/ERC7746Hooked.sol`).
5.  This setup means:
    *   Standard proxy owner functions (like changing the admin) are controlled by the **installer**.
    *   Upgrades (changing the implementation) are controlled by the **distributor** acting as the `ProxyAdmin` *and* the middleware layer. The upgrade process happens via the distributor calling the proxy, triggering the ERC7746 hook flow detailed in the [Upgradability](./Upgradability.md) guide. This flow may involve checks requiring installer consent, depending on the Distributor's implementation.

```solidity
// Example: Instantiating an UpgradableDistribution
// Assume upDist is an instance of UpgradableDistribution
// Assume distributorContract is the address of the Distributor managing upgrades
// Assume installerAddress is the end-user installing the instance
// Assume initArgs is the ABI encoded initialization data for the logic contract

bytes memory data = abi.encode(installerAddress, initArgs);

// Called by the distributor:
(address[] memory instances, ,) = distributorContract.call{value: 0}( // Or however the distributor triggers instantiation
    abi.encodeWithSelector(
        upDist.instantiate.selector,
        data
    )
);
address proxyInstance = instances[0];

// Now, proxyInstance points to the logic, owned by installerAddress,
// with upgrades managed by distributorContract via ERC7746 middleware.
```

For comprehensive details on the multi-party trust process for upgrades, refer to the [Upgradability](./Upgradability.md) documentation. Management of versions and migration scripts on the developer side is handled via the [Repository](./Repositories.md).

## CLI

> [!NOTE]
> The CLI provides utilities to simplify deploying and managing distributions. It may abstract some of the underlying contract details.

```bash
# Deploy a new distribution (CLI might determine type based on flags/sources)
# Example using source addresses (likely creates CloneDistribution or similar internally)
eds distribution deploy <source-addresses> --name <distribution-name> --version <version> [--uri <uri>] [--proxy-type <Clonable?>] # Check CLI help for exact flags

# Example using source code hashes (likely creates CodeHashDistribution or UpgradableDistribution)
eds distribution deploy-with-hashes <source-hashes> --name <distribution-name> --version <version> [--uri <uri>] [--proxy-type <Upgradable|Clonable?>] # Check CLI help

# Get information about a distribution (calls get() and contractURI())
eds distribution <address> info

# Instantiate a distribution (calls instantiate())
# Note: For UpgradableDistribution, '--data' needs correct encoding (installer, args)
eds distribution <address> instantiate [--data <hex-data>]

# Verify a distribution's source code matches code hashes (likely specific to hash-based distributions)
eds distribution <address> verify

# Common options available for all commands
--rpc-url <url>       # RPC endpoint
--private-key <key>   # Private key for transactions
--gas-limit <limit>   # Optional gas limit
--gas-price <price>   # Optional gas price
```



