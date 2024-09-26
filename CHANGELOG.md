# @peeramid-labs/eds

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
