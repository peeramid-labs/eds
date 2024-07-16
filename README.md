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

- **CodeIndex:**
- **Distribution:** A stateless, permissionless contract enabling instantiation from a resource (bytecode) or repository.
- **Distributor:** A stateful, permissioned contract allowing instantiation of distributions or repositories and managing their versions.
- **Installer:** A stateful, permissioned contract for managing permissions to access targets by multiple instances from various distributors.
- **Repository:** A stateful, permissioned contract enabling developers to version and manage multiple versions of the same functional resource.

#### Permission-less Domain

##### CodeIndex

A stateful, permissionless contract allowing anyone to register associations between bytecode and its on-chain location. Any smart contract may be indexed by `CodeIndex` based on its bytecode.
Proposed `CREATE2` implementation with deterministic address : `0xC0d31dB079b9eb23f6942A44c29F1ece9e118C30`

##### `Distribution`

Interface for contracts that allow specific mechanics of instantiation of referred bytecode identifiers in the `CodeIndex`. It may be using different methods for instantiation, yet it is ultimately referred by it's bytecode hash and instantiation methods kept non-parametric, to promote hardcoding of instantiation logic by the distribution creator, ultimately making any distribution a unique part of code ecosystem.
It also allows distribution creators to associate own metadata with the distribution, such as URIs defined in [ERC-190](https://eips.ethereum.org/EIPS/eip-190)

#### Developer Domain

##### Repositories

Repositories are interfaces provided for stateful, permissioned contracts allowing developers to manage resources and versions. Such repositories may return any kind of source code reference, including system-internal used ones, like `IDistribution`. It allows developers to increment versions according to [Semver](http://semver.org/) as well as implement version requirements lookup for the clients.

##### Non-Stateless Distributions

Any implementation of Distribution interface mentioned in the Permission-less Domain, that is stateful is considered as a Developer Domain component. It is possible in principle, yet will be used only for specific use-cases, where stateful distribution is required and will require distribution users to use direct location addressing, effectively excluding it from the global index system.

#### Distributor Domain

##### Distributor

Stateful, permissioned contract interface for managing distributions. It allows distributors, who may act as trusted source for many, to have their own index of trusted distributions coupled to any, parametric, initialization logic that they might need. This is a first point on instantiation chain that allows to configure distribution after it's been instantiated.

##### Version Distributor

Same as Distributor, but with additional functionality to manage versions of distributions. It allows to manage multiple versions of the same distribution and to provide version requirements lookup for the clients. Distributor may change the version of the repository, effectively disabling, in one go, every outdated version instances from operating in the system.

#### User Domain

##### Installer

Stateful, permissioned contracts for managing permissions and accessing targets from multiple distributors. Allows end-users to manage trusted sources for their installations.

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
