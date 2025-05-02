# **Ethereum Distribution System**

The Ethereum Distribution System (EDS) is an open and decentralized, fully on-chain distribution (factory) system for Ethereum smart contracts. Using EDS enables developers to publish and reuse each other's code in a trustless manner, potentially monetize their sources, and manage upgrades securely. It features built-in support for [semantic versioning](./docs/guides/Versioning.md) (`SemVer`), sophisticated version management, and a robust upgrade process involving multiple parties.
System provisions for generic interfaces for developers, distributors and installers, each with their own responsibilities and constraints.


> [!WARNING]
> This repository is still in development. Please treat it as unstable with possible API changes. If you want to use it in production environment please reach back to Peeramid Labs so we can prioritize accordingly.

## **Use cases**

* **Standardized Factory Framework**: Deploy code instances using standard [`Distribution`](./docs/guides/Distributions.md) contracts instead of writing custom factories.
* **Code Reusability & Faster Shipping**: Reduce deployment artifacts by reusing indexed code ([`ERC7744`](./docs/guides/Indexer.md)) via [`Repositories`](./docs/guides/Repositories.md) and [`Distributions`](./docs/guides/Distributions.md).
* **Runtime Security & Compliance**: Implement security oracles or compliance checks via [`Distributor`](./docs/guides/Distributors.md) contracts acting as middleware ([`ERC7746`](./docs/guides/Upgradability.md)).
* **Semantic Versioning & EIP712**: Utilize the built-in [versioning system](./docs/guides/Versioning.md) in `Repositories` for clarity and consistency.
* **Multi-Party Upgradability**: Implement secure upgrade flows requiring consent from both the [`Distributor`](./docs/guides/Distributors.md) and the end-user (`Installer`) via the [upgradeability model](./docs/guides/Upgradability.md).
* **Improved User UX**: Pre-configure trust relationships within Distributions or Distributors.
* **On-chain Code Indexing**: Reference code immutably by its bytecode hash using [`ERC7744`](./docs/guides/Indexer.md).
* **Monetization Models**: Build payment systems or subscription models using contracts like `TokenizedDistributor` (detailed in [`Distributors`](./docs/guides/Distributors.md)).

## **Overview**

EDS provides a generalized and efficient factory system by defining clear roles and interactions:

* **Developers**: Create stateless, reusable contract logic ([`Distributions`](./docs/guides/Distributions.md)) and manage their versions, metadata, and migration paths using [`Repositories`](./docs/guides/Repositories.md).
* **Distributors**: Curate lists of trusted [`Distributions`](./docs/guides/Distributions.md) or [`Repositories`](./docs/guides/Repositories.md), manage version requirements, define migration plans, and act as a security/compliance layer (middleware) for instantiated applications. ([Distributors Guide](./docs/guides/Distributors.md))
* **Installers (End Users)**: Interact with applications via `Installer` contracts, choosing trusted `Distributors` and participating in the secure upgrade process detailed in the [Upgradability Guide](./docs/guides/Upgradability.md).

The system heavily utilizes proxies for deployed application instances. These proxies are often integrated with the [`ERC7746`](./docs/guides/Upgradability.md) middleware standard. This allows `Distributors` to act as hooks, intercepting calls (especially for upgrades) to enforce security policies and version constraints, requiring consent from both the `Distributor` and the `Installer`.

### Key Features

- **Verifiable:** Stateless distributions are verifiable via bytecode hashes ([`ERC7744`](./docs/guides/Indexer.md)).
- **Permission-less:** Anyone can index code ([`ERC7744`](./docs/guides/Indexer.md)) or deploy basic [`Distributions`](./docs/guides/Distributions.md).
- **Composable:** Integrates existing on-chain contracts and allows building complex applications from smaller parts.
- **Versionable:** Robust [`SemVer`](./docs/guides/Versioning.md) based versioning via [`Repositories`](./docs/guides/Repositories.md).
- **Upgradable:** Secure multi-party [upgrade mechanism](./docs/guides/Upgradability.md) via [`Distributors`](./docs/guides/Distributors.md) and [`ERC7746`](./docs/guides/Upgradability.md) middleware.
- **Secure:** Trust boundaries between domains, with runtime checks enforced by [`Distributors`](./docs/guides/Distributors.md).
- **Efficient:** Promotes code reuse via [`ERC7744`](./docs/guides/Indexer.md) indexing, potentially reducing deployment costs.

![image](https://github.com/user-attachments/assets/52fa7028-177c-4de2-9259-3f883491a3d3)

### Key Components

System components are broken down into four domains: Permission-less, Developer, Distributor and User. Each domain has its own set of contracts and interfaces. For more details, see the specific guides linked below or in the [`docs/guides/`](./docs/guides/) directory.

#### Permission-less Domain

##### CodeIndex ([`ERC-7744`](./docs/guides/Indexer.md))

A global, permissionless registry mapping contract bytecode hashes to their on-chain deployment addresses. This allows referencing code immutably. ([Indexer Guide](./docs/guides/Indexer.md))
Proposed `CREATE2` implementation with deterministic address : `0xC0dE1D2F7662c63796E544B2647b2A94EE658E07`

##### [`Distribution`](./docs/guides/Distributions.md) (Interface & Implementations)

Contracts responsible for instantiating specific contract logic referenced by a code hash or address. ([Distributions Guide](./docs/guides/Distributions.md)) Base implementations include:
*   `CloneDistribution`: Creates simple clones of a source contract.
*   `CodeHashDistribution`: Instantiates code based on an `ERC7744` code hash.
*   `LatestVersionDistribution`: Instantiates the latest version from a `Repository`.
*   `UpgradableDistribution`: Deploys `WrappedTransparentUpgradeableProxy` instances integrated with the ERC7746 upgrade flow.
Distributions aim to be stateless, focusing only on deployment logic.

#### Developer Domain

##### [`Repository`](./docs/guides/Repositories.md)

Stateful, permissioned contracts managed by developers to organize versions of their code. ([Repositories Guide](./docs/guides/Repositories.md)) Key features:
*   Manages releases using [Semantic Versioning](./docs/guides/Versioning.md) (Major.Minor.Patch).
*   Maps versions to source IDs (e.g., `ERC7744` code hashes).
*   Stores version-specific metadata.
*   Associates migration scripts with major version changes.
*   Allows resolving version requirements (e.g., `^1.2.0`, `~2.0.0`).

#### Distributor Domain

##### [`Distributor`](./docs/guides/Distributors.md)

Stateful, permissioned contracts that act as trusted intermediaries. ([Distributors Guide](./docs/guides/Distributors.md)) Key roles:
*   Maintain a registry of trusted `Distributions` or `Repositories`.
*   Define supported version requirements for repository-backed distributions.
*   Manage `MigrationPlan`s for handling upgrades between versions.
*   Instantiate application instances for users (often via `IInitializer` like `WrappedProxyInitializer`).
*   Act as the **[`ERC7746` middleware](./docs/guides/Upgradability.md)** layer for deployed proxies, enforcing security and upgrade policies.
*   Implementations like `OwnableDistributor` (access control) and `TokenizedDistributor` (monetization) exist.

#### User Domain

##### `Installer`

Contracts (typically part of a user's smart account or wallet setup) used by end-users to manage their application instances. The interaction between Installers, Distributors, and the upgrade process is detailed in the [Upgradability Guide](./docs/guides/Upgradability.md). Key functions:
*   Interact with `Distributors` to instantiate applications.
*   Hold ownership of application proxies.
*   Participate in the upgrade process by initiating upgrades and consenting via the `Distributor`'s middleware checks.
*   Manage trust relationships with `Distributors` (including changing or renouncing them).

## Documentation Guides

For a deeper understanding of each component and concept, refer to the following guides:

*   **[Indexer (`ERC7744`)](./docs/guides/Indexer.md):** Explains the permissionless code registry.
*   **[Distributions](./docs/guides/Distributions.md):** Details the different types of distribution contracts and their instantiation logic.
*   **[Repositories](./docs/guides/Repositories.md):** Covers how developers manage code versions, metadata, and migration scripts.
*   **[Distributors](./docs/guides/Distributors.md):** Describes the role of distributors in managing distributions, versions, upgrades, and security.
*   **[Upgradeability (`ERC7746`)](./docs/guides/Upgradability.md):** Explains the multi-party trust model, middleware hooks, proxy architecture, and the detailed upgrade flow.
*   **[Versioning (`SemVer`)](./docs/guides/Versioning.md):** Details the semantic versioning scheme used throughout EDS.

## Getting Started

### Installation

```bash
pnpm install
pnpm test # Run tests
```

### Examples

Examples of distributions usage can be found in [src/distributions](src/distributions) directory.
Examples of repositories usage can be found in [src/repositories](src/repositories) directory.
Examples of distributors usage can be found in [src/distributors](src/distributors) directory.

Larger example of usage can be found in [Rankify project repo](https://github.com/peeramid-labs/contracts)


## Support || Contribute

If you want to support this project, please click "sponsor" button, or see our gitcoin page:
https://explorer.gitcoin.co/#/projects/0xd4427d0ffc2b8f58c4ef28410deed1158a7d5e405d6cd5bedb0487441d2ba452



You can reach out us on Discord: https://discord.gg/EddGgGUuWC







