# Ethereum Distribution System

The Ethereum Distribution System (EDS) is an open and decentralized, fully on-chain distribution (factory) system for Ethereum smart contracts. 
Using EDS enables developers to publish and reuse each other's code in a trustless manner. Built-in system for [semantic versioning](http://semver.org/), managing versions and combining into higher level distributions allows developers to avoid using upgradability patterns, instead relying on version control. 

System provisions for generic interfaces for distributors, developers and installers, each with their own responsibilities and constraints. 

## Why is EDS Important?

- It enables developers to efficiently reuse each other's code, effectively reducing the number of needed deployment artifacts in order to get projects going. 

- It enables distributors to act as a source of trust for users, packing the global permissionless domain of available packages into a distributor entity specific instantiation that may be parametrized in predictable ways.

- It enables security firms to attest for security of deployed code and revoke such signatures in O(1) for every instance in case of vulnerabilities. 

- It enables users (smart accounts) to manage their trusted distributions and distributors while delegating runtime security as needed. 

- It paves the door for a better, more performant Ethereum ecosystem, provisioning software abstracted features such as objects passing between same distribution instances. (e.g., don’t need approve for ERC20 transfers between such)

## Overview

This system acts as generalized and efficient factory which is designed in one-fits-all principle. It achieves this by referring bytecode instead of location, enabling code queries by bytecode hash (`address.codehash`). Developers when interacting with the system first must register their bytecode to the code indexer contract which is defined by [ERC7744](https://eips.ethereum.org/EIPS/eip-7744).
After that, they may create a distribution contract that links multiple various required code hashes in one place. 

If the developer wants to manage multiple versions of the same resource, they can create a _Repository_ contract to add own index on top of global. 

In order to provide functionality to users, developers may pack their code to _Distributions_, which have hardcoded instructions for instantiation. Such hardcoded bytecode later can be itself consumed by Distributors, which are responsible for determining custom instantiation arguments and initializer interfaces that will wrap the Distribution. Finally, Installers are used by end-users to manage resources and permissions

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

System components are broken down into four domains: Permission-less, Developer, Distributor and User. Each domain has its own set of contracts and interfaces, which are designed to work together to provide a seamless experience for developers and users.

#### Permission-less Domain

##### CodeIndex ([ERC-7744](https://eips.ethereum.org/EIPS/eip-7744))

A stateful, permissionless contract allowing anyone to register associations between bytecode and its on-chain location. Any smart contract may be indexed by `CodeIndex` based on its bytecode.
Proposed `CREATE2` implementation with deterministic address : `0xc0D31d398c5ee86C5f8a23FA253ee8a586dA03Ce`

##### `Distribution`

Interface for contracts that allow specific mechanics of instantiation of referred bytecode identifiers in the `CodeIndex`. It may be using different methods for instantiation, yet it is ultimately referred by it's bytecode hash and instantiation methods kept non-parametric, to promote hardcoding of instantiation logic by the distribution creator, ultimately making any distribution a unique part of code ecosystem.
It also allows distribution creators to associate own metadata with the distribution, such as URIs defined in [ERC-190](https://eips.ethereum.org/EIPS/eip-190) or [ERC-2678](https://eips.ethereum.org/EIPS/eip-2678)

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







