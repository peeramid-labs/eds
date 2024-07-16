# Ethereum Distribution System

The Ethereum Distribution System (EDS) is a open and decentralized, fully on-chain distribution system for Ethereum smart contracts.
EDS maps functionality, expressed as bytecode, to on-chain locations, using a global non-permissioned singleton indexer contract. Using this index, EDS provides developers with a built in system for [Semver](http://semver.org/) versioning, managing multiple versions and distribution of their smart contracts. System provisions for generic interfaces for distributors, developers and installers, each with their own responsibilities and constraints.

## Overview

This system acts as generalized and efficient factory which is designed in one-fits-all principle. It achieves this by referring bytecode instead of location, enabling code queries by bytecode hash (`address.codehash`). Developers when interacting with the system first must register their bytecode to the code indexer contract. After that, they may create a distribution contract that links multiple various required code hashes in one place. If the developer wants to manage multiple versions of the same resource, they can create a repository contract to add own index on top of global. In order to provide functionality to users, developers may pack their code to Distributions, which have hardcoded instructions for instantiation. Such hardcoded bytecode later can be itself consumed by Distributors, which are responsible for determining custom instantiation arguments and initializer interfaces that will wrap the Distribution. Finally, Installers are used by end-users to manage resources and permissions

### Key Features

- **Verifiable:** Stateless distribution components are easily verifiable by anyone through their bytecode.
- **Permission-less:** Anyone can deploy distribution components without requiring permissions.
- **Inclusive:** Can accommodate already deployed on-chain functionality.
- **Versionable:** [Semver](http://semver.org/) based versioning can be applied to manage resources.
- **Plug-n-Play:** Installation procedures,easily customizable for any target platform are provisioned.
- **Secure:** Isolated contract sets and baked-in runtime checks enable trust chain between developers, distributors and users.
- **Efficient:** Extensive reuse of the same bytecode reduces gas costs, increasing efficiency across the industry.

![image](https://github.com/user-attachments/assets/52fa7028-177c-4de2-9259-3f883491a3d3)

### Key Components

- **CodeIndex:** A stateful, permissionless contract allowing anyone to register associations between bytecode and its on-chain location.
- **Distribution:** A stateless, permissionless contract enabling instantiation from a resource (bytecode) or repository.
- **Distributor:** A stateful, permissioned contract allowing instantiation of distributions or repositories and managing their versions.
- **Installer:** A stateful, permissioned contract for managing permissions to access targets by multiple instances from various distributors.
- **Repository:** A stateful, permissioned contract enabling developers to version and manage multiple versions of the same functional resource.

### Ownership Domains

To simplify code reuse, auditing, and encapsulate responsibilities, the system is divided into multiple ownership domains, each with distinct security and trust requirements.

#### Permissionless Domain

**Stateless Contracts:**

- Any smart contract indexed by `CodeIndex` based on its bytecode.
- `Distribution` contract is a special stateless contract for instantiating from a resource or repository. Its lack of state ensures easy verification and trust.
- **CodeIndex:**
  - The only stateful, permissionless contract in the system.
  - A `CREATE2` contract maintaining an immutable mapping between bytecode hash and its on-chain location.
  - `0xC0d31dB079b9eb23f6942A44c29F1ece9e118C30` with given settings is the only valid global `CodeIndex` contract.

#### Developer Domain

- **Repositories:**
  - Stateful, permissioned contracts allowing developers to manage resources and versions.
  - May return `IDistribution` interface-compatible contracts when made for distributor clients.
  - May return anything when made to be consumed by distributions.

#### Distributor Domain

- **Distributors:**
  - Stateful, permissioned contracts for managing resources and versions.
  - Allow custom instantiation arguments and initializer interfaces for flexible distribution customization.

#### User Domain

- **Installers:**
  - Stateful, permissioned contracts for managing permissions and accessing targets from multiple distributors.
  - Primarily used by end-users to manage resources and permissions.

## Getting Started

### Installation

```bash
yarn install
yarn test # Run tests
```

### Examples

Examples of distributions usage can be found in [src/distributions](src/distributions) directory.
Examples of repositories usage can be found in [src/repositories](src/repositories) directory.
Examples of distributors usage can be found in [src/distributors](src/distributors) directory.
