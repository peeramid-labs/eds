# Ethereum Distribution System

This repository introduces a standardized, on-chain distribution system for Ethereum smart contracts, designed as a flexible, user-centric, and developer-friendly alternative to traditional upgradeability patterns.

## Overview

This system prioritizes bytecode over contract location, enabling code queries by bytecode hash (`address.codehash`). It aims to be loosely coupled and easy to use, while providing a robust foundation for complex system distribution.

### Key Features

- **Bytecode Verification:** Stateless distribution components are easily verifiable by anyone through their bytecode.
- **Permissionless Distribution:** Anyone can deploy distribution components without requiring permissions.
- **Trustless Code Indexing:** The `CodeIndex` contract registers the association between bytecode and its on-chain location.
- **Source Versioning:** The `Repository` interface enables versioning and management of multiple resource versions.
- **Resource Management:** The `Installer` contract manages multiple instances of the same resource from various distributors.
- **Encapsulated Ownership Domains:** Different components are owned by distinct parties, simplifying auditing and trust management.
- **Efficiency:** Extensive reuse of the same bytecode reduces gas costs, increasing efficiency across the industry.

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

- **Stateless Contracts:**
  - Any smart contract indexed by `CodeIndex` based on its bytecode.
  - `Distribution` contract is a special stateless contract for instantiating from a resource or repository. Its lack of state ensures easy verification and trust.
- **CodeIndex:**
  - The only stateful, permissionless contract in the system.
  - A `CREATE2` contract maintaining an immutable mapping between bytecode hash and its on-chain location.

#### Developer Domain

- **Repositories:**
  - Stateful, permissioned contracts allowing developers to manage resources and versions.
  - Not indexed by `CodeIndex` and expected to return `IDistribution` interface-compatible contracts when used for resource distribution.

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
