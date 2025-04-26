# Distributions

Distributions are the main entities in EDS. They are used to distribute and upgrade contracts.

Distributions are enshrined to be developed in state-less manner, this allows easier auditing and secure portability of code cross-chain.

> [!WARNING]
> If you deploy stateless distributions they will may likely be problematic to adapt by developers because of bytecode hash referencing by [Indexer](./Indexer.md). This is done intentionally to enshrine more secure development best practices.

## Stateful distributions

Stateful distributions are distributions that are not stateless. They are used to distribute and upgrade contracts that are not stateless.

If you need to deploy such stateful distributions, we suggest using [Distributor](./Distributors.md) instead that will manage state of your distribution and is designed with features for that in mind.

## Creating a distribution

In order to create a distribution, first deploy your contract on-chain or copy address you want to use and then index contract code using [Indexer](./Indexer.md)

Once indexed, you can create a distribution using one of available [distribution contracts](../src/distributions)

When extending distributions, you must implement `sources()` virtual function. For every source you return there, distribution abstracts will create one way or another a proxy that will deploy and link every source to proxy.

Here is simple example of stateless distribution using [CloneDistribution](../src/distributions/CloneDistribution.sol):

```solidity
import "@openzeppelin/contracts/utils/Strings.sol";
import "@peeramid-labs/eds/versioning/LibSemver.sol";
import "@peeramid-labs/eds/distributions/CloneDistribution.sol";
contract MyDistribution is CloneDistribution {

    ShortString private immutable distributionName;
    uint256 private immutable distributionVersion;


    constructor(LibSemver.Version memory version) {
        distributionName = ShortStrings.toShortString("MyDistribution");
        distributionVersion = version.toUint256();
    }
    using LibSemver for LibSemver.Version;
    function sources() public pure override returns (address[] memory sources, bytes32 name, uint256 version) {
        sources = new address[](1);
        sources[0] = 0x1234567890123456789012345678901234567890;
        name = ShortString.unwrap(distributionName);
        version = distributionVersion;
    }
}
```

### Creating upgradable repository managed distribution

In EDS [Upgradability](./Upgradability.md) is complex multi-party trust process. It enables pattern where distributor & user must agree on upgrade before it can be executed.

In order to enable this process, standard upgradable proxies cannot be used. Instead, we must use proxies that have [ERC7746 Hooks](./Hooks.md) implemented within immutable part of the contract.
This hooks must be implemented by developer of the distribution in such way, that only [Distributor](./Distributors.md) can upgrade the distribution, but the Installer consent is checked in runtime.

Example of such upgradable distribution is [WrappedTransparentUpgradeableProxy](../src/proxies/WrappedTransparentUpgradeableProxy.sol).

Management of the upgrades & migrations on developer side is done via [Repository](./Repositories.md) contract.
Distributors are free to implement their own logic of migration of the state, wrapping or completley bypassing Developer packages as they need to.

For more details refer to [Upgradability](./Upgradability.md) documentation.

## Creating Distributions from CLI

> [!NOTE]
> The CLI provides utilities to create and manage distributions.

```bash
# Deploy a new distribution with source addresses
eds distribution deploy <source-addresses> --proxy-type <Upgradable|Clonable> --name <distribution-name> --version <version> [--uri <uri>]

# Deploy a distribution with source code hashes
eds distribution deploy-with-hashes <source-hashes> --proxy-type <Upgradable|Clonable> --name <distribution-name> --version <version> [--uri <uri>]

# Get information about a distribution
eds distribution <address> info

# Instantiate a distribution
eds distribution <address> instantiate [--data <hex-data>]

# Verify a distribution's source code matches code hashes
eds distribution <address> verify

# Common options available for all commands
--rpc-url <url>       # RPC endpoint
--private-key <key>   # Private key for transactions
--gas-limit <limit>   # Optional gas limit
--gas-price <price>   # Optional gas price
```



