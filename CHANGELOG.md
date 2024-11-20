# @peeramid-labs/eds

## 2.1.3

### Patch Changes

- [#30](https://github.com/peeramid-labs/eds/pull/30) [`48570f031cd080d3e324b0244741452698a99bbd`](https://github.com/peeramid-labs/eds/commit/48570f031cd080d3e324b0244741452698a99bbd) Thanks [@peersky](https://github.com/peersky)! - added aux file for codeIndex interface in more loose pragma to be more reusable as library

- [#30](https://github.com/peeramid-labs/eds/pull/30) [`48570f031cd080d3e324b0244741452698a99bbd`](https://github.com/peeramid-labs/eds/commit/48570f031cd080d3e324b0244741452698a99bbd) Thanks [@peersky](https://github.com/peersky)! - changed code indexer dependency

## 2.1.2

### Patch Changes

- [#28](https://github.com/peeramid-labs/eds/pull/28) [`3e2e0429f37fff1e1cb38a27ed7ba08a6ff4c11b`](https://github.com/peeramid-labs/eds/commit/3e2e0429f37fff1e1cb38a27ed7ba08a6ff4c11b) Thanks [@peersky](https://github.com/peersky)! - added aux file for codeIndex interface in more loose pragma to be more reusable as library

## 2.1.1

### Patch Changes

- [#26](https://github.com/peeramid-labs/eds/pull/26) [`ceecabe3ab9f0e7f6c8d45ba816f99a76260098d`](https://github.com/peeramid-labs/eds/commit/ceecabe3ab9f0e7f6c8d45ba816f99a76260098d) Thanks [@peersky](https://github.com/peersky)! - fixed typos

## 2.1.0

### Minor Changes

- [#24](https://github.com/peeramid-labs/eds/pull/24) [`2b2da271d61f6f1fc9314dc1ecc7401d9a988f4e`](https://github.com/peeramid-labs/eds/commit/2b2da271d61f6f1fc9314dc1ecc7401d9a988f4e) Thanks [@peersky](https://github.com/peersky)! - added paid distributor contract

## 2.0.1

### Patch Changes

- [#20](https://github.com/peeramid-labs/eds/pull/20) [`8e4ec30a087fa01402c9f5f588ba451caf7d6390`](https://github.com/peeramid-labs/eds/commit/8e4ec30a087fa01402c9f5f588ba451caf7d6390) Thanks [@peersky](https://github.com/peersky)! - updated linter config

## 2.0.0

### Major Changes

- [#9](https://github.com/peeramid-labs/eds/pull/9) [`6527e018db4e137cef1d5669e713fd9159cfd15b`](https://github.com/peeramid-labs/eds/commit/6527e018db4e137cef1d5669e713fd9159cfd15b) Thanks [@peersky](https://github.com/peersky)! - # Breaking changes

  ## Deprecated getMetadata in favor of contractURI

  contractURI is more widely used and we want to align with the standard.

  ## Merged VersionedDistributor into Distributor

  Now there is only a single `IDistributor` interface. Distribution creators still have two methods of adding distributions - either by specifying repository address, or by specifying a distribution hash id directly.

  The `VersionedDistributor` is now deprecated and will be removed in the next major version.

  Instantiation function will now automatically detect if the provided address is a repository or a distribution id and call the appropriate method.

  ERC7746 checks will now also automatically detect if the provided address is a repository or a distribution and will enforce version control accordingly.

  ### Instantiated event

  Now emits also a version indexed parameter, arshHash was removed, args are availible as not indexed object in data

  ## addDistribution for versioned repositories

  `addDistribution` now takes `LibSemver.VersionRequirement` as an argument, which is more convenient way to pack both version and requirement in a single argument.

  ## Repository now requires cURI

  The `cURI` is now required for all repositories. This is to ensure that all repositories are compliant with the standard contractURI method

  ## Reposotory `get` function

  Repostory `get` function now takes `LibSemver.VersionRequirement` as an argument, which is more convenient way to pack both version and requirement in a single argument.

  ## LibSemver.compare

  `compare` now takes `LibSemver.VersionRequirement` as an argument, which is more convenient way to pack both version and requirement in a single argument.

  ## LibSemver compare(version version) -> areEqual

  `compare(Version memory _version1, Version memory _version2)` now returns a boolean instead of an integer.

## 1.0.1

### Patch Changes

- [#6](https://github.com/peeramid-labs/eds/pull/6) [`3e82c686a66f814cd0c7b7a952d5d83cc6c30f57`](https://github.com/peeramid-labs/eds/commit/3e82c686a66f814cd0c7b7a952d5d83cc6c30f57) Thanks [@peersky](https://github.com/peersky)! - ### Changes

  - Added documentation strings.
  - Made minor logic improvements.
  - Implemented documentation generation from docstrings.
  - Performed gas optimizations.
  - Unified code style.

## 1.0.0

### Major Changes

- [`0b61cff414e19610844c49483dff72be4b9b85a3`](https://github.com/peeramid-labs/eds/commit/0b61cff414e19610844c49483dff72be4b9b85a3) Thanks [@peersky](https://github.com/peersky)! - added distributor instances categorization by instance id referencing distribution id

- [`20cee6ee93d4ffb064d9ccc665393693de8b819b`](https://github.com/peeramid-labs/eds/commit/20cee6ee93d4ffb064d9ccc665393693de8b819b) Thanks [@peersky](https://github.com/peersky)! - Initializer for distributors is an address to accomodate statefull initializers

- [`caaa17e09b4c21f6bc181a642cdbd201d8577f9f`](https://github.com/peeramid-labs/eds/commit/caaa17e09b4c21f6bc181a642cdbd201d8577f9f) Thanks [@peersky](https://github.com/peersky)! - Installer interfaces now allow whitelisting of distributors or explicit distribution ids of distributor

- Distributors now use own ids for distributions that are keccak(distributionId,initializerId)

- [`dbe87be90a558107dbb1457214d6f4e38965fc99`](https://github.com/peeramid-labs/eds/commit/dbe87be90a558107dbb1457214d6f4e38965fc99) Thanks [@peersky](https://github.com/peersky)! - Distributor when doing checks now always infers real target address from config to accommodate for middlewares such as access manager intermediate contract

### Minor Changes

- [`0ea50a03ee6398ec30f50df48de141597e475025`](https://github.com/peeramid-labs/eds/commit/0ea50a03ee6398ec30f50df48de141597e475025) Thanks [@peersky](https://github.com/peersky)! - added interface for allowing specific distribution ids for distributor within installer

## 0.2.1

### Patch Changes

- [`19aef3082c8adbfe6ec81da6c9fbe3120393ae36`](https://github.com/peeramid-labs/eds/commit/19aef3082c8adbfe6ec81da6c9fbe3120393ae36) Thanks [@peersky](https://github.com/peersky)! - fixed initializer interface to return correct types for distribution name and version

## 0.2.0

### Minor Changes

- [`198ceee7711a59c335d48c29233772b21ce0a7a1`](https://github.com/peeramid-labs/eds/commit/198ceee7711a59c335d48c29233772b21ce0a7a1) Thanks [@peersky](https://github.com/peersky)! - instantiation now returns version and name

- [`6ada120ad22dae8af8da88d2bd4cf99db81bee7a`](https://github.com/peeramid-labs/eds/commit/6ada120ad22dae8af8da88d2bd4cf99db81bee7a) Thanks [@peersky](https://github.com/peersky)! - renamed getSources to get, added contract version and name to the return parameters

### Patch Changes

- [`67e1cacd37f961e451d8fda4a7172728735015de`](https://github.com/peeramid-labs/eds/commit/67e1cacd37f961e451d8fda4a7172728735015de) Thanks [@peersky](https://github.com/peersky)! - fixed type errors in tests

## 0.1.0

### Minor Changes

- [`216fcfb08d98031b6689853dc4f84d3c76b5651f`](https://github.com/peeramid-labs/eds/commit/216fcfb08d98031b6689853dc4f84d3c76b5651f) Thanks [@peersky](https://github.com/peersky)! - initial release

- [#2](https://github.com/peeramid-labs/eds/pull/2) [`b86f335303a38f512ad0e950b1fbe8987d21403c`](https://github.com/peeramid-labs/eds/commit/b86f335303a38f512ad0e950b1fbe8987d21403c) Thanks [@peersky](https://github.com/peersky)! - added use of erc7744 and erc7746 for eds components
