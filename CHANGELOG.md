# @peeramid-labs/eds

## 2.3.2

### Patch Changes

- [`824fe7e716e2bd515f4ecfd35f27c70324df4189`](https://github.com/peeramid-labs/eds/commit/824fe7e716e2bd515f4ecfd35f27c70324df4189) Thanks [@peersky](https://github.com/peersky)! - implemented deploy script as js to avoid compilation need when using as dept

## 2.3.1

### Patch Changes

- [`6b10f436d8a9438f13729b284e8a4d5db019e3c9`](https://github.com/peeramid-labs/eds/commit/6b10f436d8a9438f13729b284e8a4d5db019e3c9) Thanks [@peersky](https://github.com/peersky)! - added deploy script to package files

## 2.3.0

### Minor Changes

- [#42](https://github.com/peeramid-labs/eds/pull/42) [`8a86a52a7472ac4ef13484b58bd9b809339fc4a0`](https://github.com/peeramid-labs/eds/commit/8a86a52a7472ac4ef13484b58bd9b809339fc4a0) Thanks [@peersky](https://github.com/peersky)! - - Removed metadata from compilation artifact

  - Renamed CodeIndex artifacts into ERC7744 to be more explicit
  - Adjusted tests
  - Bumped compilation for ERC7744 to solidity 0.8.28
  - Added artifacts to npm package exports to allow 3rd party projects deploy ERC7744 on their own

  ## Breaking changes

  - ERC7744 Code Index address changes to `0xC0dE1D2F7662c63796E544B2647b2A94EE658E07`
  - ICodeIndexRef.sol was removed, you can now directly interface from IERC7744
  - ICodeIndex.sol and CodeIndex.sol renamed to IERC7744.sol and ERC7744.sol

## 2.2.3

### Patch Changes

- [#40](https://github.com/peeramid-labs/eds/pull/40) [`aad52fdf2042ce85a5221b78f23d3e11e8d8137b`](https://github.com/peeramid-labs/eds/commit/aad52fdf2042ce85a5221b78f23d3e11e8d8137b) Thanks [@peersky](https://github.com/peersky)! - added playbook script for running deployments locally

## 2.2.2

### Patch Changes

- [#38](https://github.com/peeramid-labs/eds/pull/38) [`79801938a6b449b0bda1dd8f8021195e76d58a4f`](https://github.com/peeramid-labs/eds/commit/79801938a6b449b0bda1dd8f8021195e76d58a4f) Thanks [@peersky](https://github.com/peersky)! - added viem compatible typescript abi exports during release

## 2.2.1

### Patch Changes

- [#36](https://github.com/peeramid-labs/eds/pull/36) [`a7cabce0ab76f7f737ce875de4cc33b4ddc58f87`](https://github.com/peeramid-labs/eds/commit/a7cabce0ab76f7f737ce875de4cc33b4ddc58f87) Thanks [@peersky](https://github.com/peersky)! - ci chore

## 2.2.0

### Minor Changes

- [#34](https://github.com/peeramid-labs/eds/pull/34) [`f43876e7cba08a68e87ff724cdea7289bd359b0e`](https://github.com/peeramid-labs/eds/commit/f43876e7cba08a68e87ff724cdea7289bd359b0e) Thanks [@peersky](https://github.com/peersky)! - added devnet deployment arfifacts

- [#33](https://github.com/peeramid-labs/eds/pull/33) [`3ca5234d820bbbd7328aeed73aad057319fd6ba5`](https://github.com/peeramid-labs/eds/commit/3ca5234d820bbbd7328aeed73aad057319fd6ba5) Thanks [@peersky](https://github.com/peersky)! - added interface to add named distributions

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
