# Solidity API

## CodeIndex

You can use this contract to index contracts by their bytecode.

_This allows to query contracts by their bytecode instead of addresses._

### register

```solidity
function register(address container) external
```

Registers a contract in the index by its bytecode hash

_`msg.codeHash` will be used
It will revert if the contract is already indexed_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| container | address | The contract to register |

### get

```solidity
function get(bytes32 id) external view returns (address)
```

Returns the contract address by its bytecode hash

_returns zero if the contract is not indexed_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | bytes32 | The bytecode hash |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The contract address |

## ILayer

### beforeCall

```solidity
function beforeCall(bytes configuration, bytes4 selector, address sender, uint256 value, bytes data) external returns (bytes)
```

Validates a function call before execution.

_MUST revert if validation fails._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| configuration | bytes | Layer-specific configuration data. |
| selector | bytes4 | The function selector being called. |
| sender | address | The address initiating the call. |
| value | uint256 | The amount of ETH sent with the call (if any). |
| data | bytes | The calldata for the function call. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes | beforeCallResult Arbitrary data to be passed to `afterCall`. |

### afterCall

```solidity
function afterCall(bytes configuration, bytes4 selector, address sender, uint256 value, bytes data, bytes beforeCallResult) external
```

Validates a function call after execution.

_MUST revert if validation fails._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| configuration | bytes | Layer-specific configuration data. |
| selector | bytes4 | The function selector being called. |
| sender | address | The address initiating the call. |
| value | uint256 | The amount of ETH sent with the call (if any). |
| data | bytes | The calldata for the function call. |
| beforeCallResult | bytes | The data returned by `beforeCall`. |

## ICodeIndex

### Indexed

```solidity
event Indexed(address container, bytes32 codeHash)
```

### alreadyExists

```solidity
error alreadyExists(bytes32 id, address source)
```

### register

```solidity
function register(address container) external
```

### get

```solidity
function get(bytes32 id) external view returns (address)
```

## CloneDistribution

### sources

```solidity
function sources() internal view virtual returns (address[])
```

### instantiate

```solidity
function instantiate() public virtual returns (address[] instances)
```

### getSources

```solidity
function getSources() public view virtual returns (address[])
```

### getMetadata

```solidity
function getMetadata() public view virtual returns (string)
```

## CodeIndexer

### indexContract

```solidity
contract ICodeIndex indexContract
```

### constructor

```solidity
constructor() internal
```

### getContractsIndex

```solidity
function getContractsIndex() internal pure returns (contract ICodeIndex)
```

### index

```solidity
function index(address source) internal
```

## Distributor

### getDistributions

```solidity
function getDistributions() public view returns (bytes32[])
```

### getDistributionURI

```solidity
function getDistributionURI(bytes32 id) public view returns (string)
```

### _addDistribution

```solidity
function _addDistribution(bytes32 id, bytes32 initId) internal virtual
```

### _removeDistribution

```solidity
function _removeDistribution(bytes32 id) internal virtual
```

### _instantiate

```solidity
function _instantiate(bytes32 id, bytes args) internal virtual returns (address[] instances)
```

### beforeCall

```solidity
function beforeCall(bytes, bytes4, address sender, uint256, bytes) public view virtual returns (bytes)
```

### afterCall

```solidity
function afterCall(bytes layerConfig, bytes4 selector, address sender, uint256 value, bytes data, bytes beforeCallResult) public virtual
```

## Installer

### instancesNum

```solidity
uint256 instancesNum
```

### constructor

```solidity
constructor(address targetAddress) internal
```

### _addDistributor

```solidity
function _addDistributor(contract IDistributor distributor) internal
```

### _removeDistributor

```solidity
function _removeDistributor(contract IDistributor distributor) internal
```

### isDistributor

```solidity
function isDistributor(contract IDistributor distributor) public view returns (bool)
```

### getDistributors

```solidity
function getDistributors() public view returns (address[])
```

### _install

```solidity
function _install(contract IDistributor distributor, bytes32 distributionId, bytes args) internal virtual returns (uint256 instanceId)
```

### _uninstall

```solidity
function _uninstall(uint256 instanceId) internal virtual
```

### getInstance

```solidity
function getInstance(uint256 instanceId) public view returns (address[] instaneContracts)
```

### getInstancesNum

```solidity
function getInstancesNum() public view returns (uint256)
```

### isInstance

```solidity
function isInstance(address instance) public view returns (bool)
```

### distributorOf

```solidity
function distributorOf(address instance) public view returns (contract IDistributor)
```

### target

```solidity
function target() public view returns (address)
```

### beforeCall

```solidity
function beforeCall(bytes layerConfig, bytes4 selector, address sender, uint256 value, bytes data) public returns (bytes)
```

### afterCall

```solidity
function afterCall(bytes layerConfig, bytes4 selector, address sender, uint256 value, bytes data, bytes beforeCallResult) public
```

## Repository

### Uint64WithMetadata

```solidity
struct Uint64WithMetadata {
  uint64 value;
  bytes metadata;
}
```

### Uint128WIthMetadata

```solidity
struct Uint128WIthMetadata {
  uint128 value;
  bytes metadata;
}
```

### versionedSources

```solidity
mapping(uint256 => bytes32) versionedSources
```

### releaseMetadata

```solidity
mapping(uint64 => bytes) releaseMetadata
```

### minorReleaseMetadata

```solidity
mapping(uint128 => bytes) minorReleaseMetadata
```

### patchReleaseMetadata

```solidity
mapping(uint256 => bytes) patchReleaseMetadata
```

### minorReleases

```solidity
mapping(uint64 => uint64) minorReleases
```

### patchReleases

```solidity
mapping(uint128 => uint128) patchReleases
```

### sourceVersions

```solidity
mapping(bytes32 => uint256) sourceVersions
```

### majorReleases

```solidity
uint64 majorReleases
```

### latestVersion

```solidity
uint256 latestVersion
```

### _updateReleaseMetadata

```solidity
function _updateReleaseMetadata(struct LibSemver.Version version, bytes metadata) internal
```

### _newRelease

```solidity
function _newRelease(bytes32 sourceId, bytes metadata, struct LibSemver.Version version) internal
```

### getLatest

```solidity
function getLatest() public view returns (struct IRepository.Source)
```

### get

```solidity
function get(struct LibSemver.Version version, enum LibSemver.requirements requirement) public view returns (struct IRepository.Source)
```

### combineMetadata

```solidity
function combineMetadata(uint256 versionFlat) internal view returns (bytes)
```

### getMajorReleaseMetadata

```solidity
function getMajorReleaseMetadata(uint64 major) public view returns (bytes)
```

### getMinorReleaseMetadata

```solidity
function getMinorReleaseMetadata(uint64 major, uint64 minor) public view returns (bytes)
```

### getPatchReleaseMetadata

```solidity
function getPatchReleaseMetadata(uint64 major, uint64 minor, uint64 patch) public view returns (bytes)
```

### getMajorReleases

```solidity
function getMajorReleases() public view returns (uint64)
```

### getMinorReleases

```solidity
function getMinorReleases(uint64 major) public view returns (uint64)
```

### getPatchReleases

```solidity
function getPatchReleases(uint64 major, uint64 minor) public view returns (uint128)
```

## VersionDistributor

### _addVersionedDistribution

```solidity
function _addVersionedDistribution(contract IRepository repository, struct LibSemver.Version version, enum LibSemver.requirements requirement, bytes32 initializer) internal
```

### _changeRequirement

```solidity
function _changeRequirement(contract IRepository repository, struct LibSemver.Version version, enum LibSemver.requirements requirement) internal
```

### _instantiate

```solidity
function _instantiate(contract IRepository repository, bytes args) internal returns (address[])
```

### getVersionedDistributions

```solidity
function getVersionedDistributions() public view returns (address[] repositories)
```

### getVersionedDistributionURI

```solidity
function getVersionedDistributionURI(contract IRepository repository) public view returns (string)
```

### _removeVersionedDistribution

```solidity
function _removeVersionedDistribution(contract IRepository repository) internal
```

### beforeCall

```solidity
function beforeCall(bytes, bytes4, address sender, uint256, bytes) public view returns (bytes)
```

### afterCall

```solidity
function afterCall(bytes layerConfig, bytes4 selector, address sender, uint256 value, bytes data, bytes beforeCallResult) public
```

## CodeHashDistribution

### metadata

```solidity
bytes32 metadata
```

### _reference

```solidity
address _reference
```

### constructor

```solidity
constructor(bytes32 codeHash, bytes32 _metadata) public
```

### sources

```solidity
function sources() internal view virtual returns (address[])
```

### getMetadata

```solidity
function getMetadata() public view virtual returns (string)
```

## LatestVersionDistribution

### metadata

```solidity
bytes32 metadata
```

### repository

```solidity
contract IRepository repository
```

### constructor

```solidity
constructor(contract IRepository _repository, bytes32 _metadata) public
```

### sources

```solidity
function sources() internal view virtual returns (address[])
```

### getMetadata

```solidity
function getMetadata() public view virtual returns (string)
```

## OwnableDistributor

### constructor

```solidity
constructor(address _owner) public
```

### instantiate

```solidity
function instantiate(bytes32 id, bytes args) public returns (address[])
```

### addDistribution

```solidity
function addDistribution(bytes32 id, bytes32 initId) public
```

### removeDistribution

```solidity
function removeDistribution(bytes32 id) public
```

## OwnableVersionDistributor

### constructor

```solidity
constructor(address _owner) public
```

### instantiate

```solidity
function instantiate(contract IRepository repository, bytes args) public returns (address[])
```

### addVersionedDistribution

```solidity
function addVersionedDistribution(contract IRepository repository, struct LibSemver.Version version, enum LibSemver.requirements requirement, bytes32 initializer) public
```

### removeVersionedDistribution

```solidity
function removeVersionedDistribution(contract IRepository repository) public
```

### changeRequirement

```solidity
function changeRequirement(contract IRepository repository, struct LibSemver.Version version, enum LibSemver.requirements requirement) public
```

## IDistribution

### Distributed

```solidity
event Distributed(address distributor, address[] instances)
```

### instantiate

```solidity
function instantiate() external returns (address[] instances)
```

### getSources

```solidity
function getSources() external view returns (address[])
```

### getMetadata

```solidity
function getMetadata() external view returns (string)
```

## IDistributor

### DistributionNotFound

```solidity
error DistributionNotFound(bytes32 id)
```

### DistributionExists

```solidity
error DistributionExists(bytes32 id)
```

### InitializerNotFound

```solidity
error InitializerNotFound(bytes32 id)
```

### InvalidInstance

```solidity
error InvalidInstance(address instance)
```

### Instantiated

```solidity
event Instantiated(bytes32 distributionId, bytes argsHash)
```

### DistributionRemoved

```solidity
event DistributionRemoved(bytes32 id)
```

### DistributionAdded

```solidity
event DistributionAdded(bytes32 id, bytes32 initializerId)
```

### getDistributions

```solidity
function getDistributions() external view returns (bytes32[] ids)
```

### getDistributionURI

```solidity
function getDistributionURI(bytes32 id) external view returns (string)
```

### instantiate

```solidity
function instantiate(bytes32 id, bytes args) external returns (address[])
```

### addDistribution

```solidity
function addDistribution(bytes32 id, bytes32 initializer) external
```

### removeDistribution

```solidity
function removeDistribution(bytes32 id) external
```

## IInitializer

### Initialized

```solidity
event Initialized(address container, bytes32 codeHash)
```

### initializationFailed

```solidity
error initializationFailed(bytes32 id, string reason)
```

### initialize

```solidity
function initialize(bytes32 id, address[] instances, bytes args) external
```

## IInstaller

### InvalidDistributor

```solidity
error InvalidDistributor(contract IDistributor distributor)
```

### InvalidTarget

```solidity
error InvalidTarget(address target)
```

### DistributorAdded

```solidity
event DistributorAdded(contract IDistributor distributor)
```

### DistributorRemoved

```solidity
event DistributorRemoved(contract IDistributor distributor)
```

### addDistributor

```solidity
function addDistributor(contract IDistributor distributor) external
```

### removeDistributor

```solidity
function removeDistributor(contract IDistributor distributor) external
```

### isDistributor

```solidity
function isDistributor(contract IDistributor distributor) external view returns (bool)
```

### getDistributors

```solidity
function getDistributors() external view returns (address[])
```

### Installed

```solidity
event Installed(address instance, bytes32 distributionId, bytes32 permissions, bytes args)
```

### Uninstalled

```solidity
event Uninstalled(address instance)
```

### install

```solidity
function install(contract IDistributor distributor, bytes32 distributionId, bytes args) external payable returns (uint256 instanceId)
```

### uninstall

```solidity
function uninstall(uint256 instanceId) external
```

### getInstance

```solidity
function getInstance(uint256 instanceId) external view returns (address[] instaneContracts)
```

### getInstancesNum

```solidity
function getInstancesNum() external view returns (uint256)
```

### isInstance

```solidity
function isInstance(address instance) external view returns (bool)
```

### distributorOf

```solidity
function distributorOf(address instance) external view returns (contract IDistributor)
```

### target

```solidity
function target() external view returns (address)
```

### NotAnInstance

```solidity
error NotAnInstance(address instance)
```

## IRepository

### Source

```solidity
struct Source {
  struct LibSemver.Version version;
  bytes32 sourceId;
  bytes metadata;
}
```

### VersionDoesNotExist

```solidity
error VersionDoesNotExist(uint256 version)
```

### ReleaseZeroNotAllowed

```solidity
error ReleaseZeroNotAllowed()
```

### VersionExists

```solidity
error VersionExists(uint256 version)
```

### VersionIncrementInvalid

```solidity
error VersionIncrementInvalid(uint256 version)
```

### EmptyReleaseMetadata

```solidity
error EmptyReleaseMetadata()
```

### ReleaseDoesNotExist

```solidity
error ReleaseDoesNotExist()
```

### VersionAdded

```solidity
event VersionAdded(uint256 version, bytes32 source, bytes buildMetadata)
```

### ReleaseMetadataUpdated

```solidity
event ReleaseMetadataUpdated(uint256 version, bytes releaseMetadata)
```

### updateReleaseMetadata

```solidity
function updateReleaseMetadata(struct LibSemver.Version version, bytes releaseMetadata) external
```

### newRelease

```solidity
function newRelease(bytes32 sourceId, bytes metadata, struct LibSemver.Version version) external
```

### getLatest

```solidity
function getLatest() external view returns (struct IRepository.Source)
```

### get

```solidity
function get(struct LibSemver.Version version, enum LibSemver.requirements requirement) external view returns (struct IRepository.Source)
```

## IVersionDistributor

### InvalidRepository

```solidity
error InvalidRepository(contract IRepository repository)
```

### RepositoryAlreadyExists

```solidity
error RepositoryAlreadyExists(contract IRepository repository)
```

### VersionOutdated

```solidity
error VersionOutdated(contract IRepository repository, uint256 version)
```

### InvalidInstance

```solidity
error InvalidInstance(address instance)
```

### VersionedDistributionAdded

```solidity
event VersionedDistributionAdded(contract IRepository repository, uint256 version, enum LibSemver.requirements requirement, bytes32 initializerId)
```

### VersionChanged

```solidity
event VersionChanged(address repository, uint256 oldVersion, uint256 newVersion)
```

### RequirementChanged

```solidity
event RequirementChanged(contract IRepository repository, enum LibSemver.requirements oldRequirement, enum LibSemver.requirements newRequirement)
```

### VersionedDistributionRemoved

```solidity
event VersionedDistributionRemoved(contract IRepository repository)
```

### Instantiated

```solidity
event Instantiated(address repository, bytes argsHash)
```

### addVersionedDistribution

```solidity
function addVersionedDistribution(contract IRepository repository, struct LibSemver.Version version, enum LibSemver.requirements requirement, bytes32 initializer) external
```

### changeRequirement

```solidity
function changeRequirement(contract IRepository repository, struct LibSemver.Version version, enum LibSemver.requirements requirement) external
```

### getVersionedDistributions

```solidity
function getVersionedDistributions() external view returns (address[] repositories)
```

### getVersionedDistributionURI

```solidity
function getVersionedDistributionURI(contract IRepository repository) external view returns (string)
```

### instantiate

```solidity
function instantiate(contract IRepository repository, bytes args) external returns (address[])
```

### removeVersionedDistribution

```solidity
function removeVersionedDistribution(contract IRepository repository) external
```

## LibSemver

### versionMissmatch

```solidity
error versionMissmatch(string message)
```

### Version

```solidity
struct Version {
  uint64 major;
  uint64 minor;
  uint128 patch;
}
```

### requirements

```solidity
enum requirements {
  ANY,
  EXACT,
  MAJOR,
  MAJOR_MINOR,
  GREATER_EQUAL,
  GREATER,
  LESSER_EQUAL,
  LESSER
}
```

### toUint256

```solidity
function toUint256(struct LibSemver.Version _version) internal pure returns (uint256)
```

### parse

```solidity
function parse(uint256 _version) internal pure returns (struct LibSemver.Version)
```

### toString

```solidity
function toString(struct LibSemver.Version _version) internal pure returns (string)
```

### require_exact

```solidity
function require_exact(struct LibSemver.Version _version1, struct LibSemver.Version _version2) internal pure
```

### require_major

```solidity
function require_major(struct LibSemver.Version _version1, struct LibSemver.Version _version2) internal pure
```

### require_major_minor

```solidity
function require_major_minor(struct LibSemver.Version _version1, struct LibSemver.Version _version2) internal pure
```

### require_greater_equal

```solidity
function require_greater_equal(struct LibSemver.Version _version1, struct LibSemver.Version _version2) internal pure
```

### require_greater

```solidity
function require_greater(struct LibSemver.Version _version1, struct LibSemver.Version _version2) internal pure
```

### require_lesser_equal

```solidity
function require_lesser_equal(struct LibSemver.Version _version1, struct LibSemver.Version _version2) internal pure
```

### require_lesser

```solidity
function require_lesser(struct LibSemver.Version _version1, struct LibSemver.Version _version2) internal pure
```

### compare

```solidity
function compare(struct LibSemver.Version _version1, struct LibSemver.Version _version2) internal pure returns (uint256)
```

### compare

```solidity
function compare(struct LibSemver.Version _version1, struct LibSemver.Version _version2, enum LibSemver.requirements _requirement) internal pure returns (bool)
```

### getNextMajor

```solidity
function getNextMajor(struct LibSemver.Version _version) internal pure returns (struct LibSemver.Version)
```

### getNextMinor

```solidity
function getNextMinor(struct LibSemver.Version _version) internal pure returns (struct LibSemver.Version)
```

### getNextPatch

```solidity
function getNextPatch(struct LibSemver.Version _version) internal pure returns (struct LibSemver.Version)
```

## OwnableRepository

### constructor

```solidity
constructor(address owner) public
```

### updateReleaseMetadata

```solidity
function updateReleaseMetadata(struct LibSemver.Version version, bytes releaseMetadata) public
```

### newRelease

```solidity
function newRelease(bytes32 sourceId, bytes metadata, struct LibSemver.Version version) public
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

