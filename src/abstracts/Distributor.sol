// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IDistribution.sol";
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IInitializer.sol";
import "../abstracts/CodeIndexer.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IContractURI} from "../interfaces/IContractURI.sol";
/**
 * @title Distributor
 * @notice Abstract contract that implements the IDistributor interface, CodeIndexer, and ERC165.
 * This contract serves as a base for creating distributor contracts with specific functionalities.
 * It provides the necessary structure and functions to be extended by other contracts.
 * @author Peeramid Labs, 2024
 */
abstract contract Distributor is IDistributor, CodeIndexer, ERC165 {
    using LibSemver for LibSemver.Version;
    struct DistributionComponent {
        address distributionLocation;
        address initializer;
    }

    struct VersionedDistribution {
        LibSemver.VersionRequirement requirement;
    }

    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private distirbutionsSet;
    mapping(address instance => uint256 instanceId) private instanceIds;
    mapping(uint256 instance => bytes32 distributorsId) public distributionOf;
    mapping(bytes32 distributorsId => DistributionComponent distirbution) public distributionComponents;
    mapping(bytes32 distributorsId => LibSemver.VersionRequirement VersionRequirement) public versionRequirements;
    mapping(uint256 instanceId => LibSemver.Version instanceVersion) public instanceVersions;

    uint256 public numInstances;
    // @inheritdoc IDistributor
    function getDistributions() external view returns (bytes32[] memory) {
        return distirbutionsSet.values();
    }
    // @inheritdoc IDistributor
    function getDistributionId(address instance) external view virtual returns (bytes32) {
        return distributionOf[getInstanceId(instance)];
    }
    // @inheritdoc IDistributor
    function getInstanceId(address instance) public view virtual returns (uint256) {
        return instanceIds[instance];
    }
    // @inheritdoc IDistributor
    function getDistributionURI(bytes32 distributorsId) external view returns (string memory) {
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        return IContractURI(distributionComponent.distributionLocation).contractURI();
    }

    function _addDistribution(
        address repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement
    ) internal {
        if (!ERC165Checker.supportsInterface(address(repository), type(IRepository).interfaceId)) {
            revert InvalidRepository(repository);
        }
        bytes32 distributorId = keccak256(abi.encode(repository, initializer));
        if (LibSemver.toUint256(requirement.version) == 0) {
            revert InvalidVersionRequested(distributorId, LibSemver.toString(requirement.version));
        }
        _newDistriubutionRecord(distributorId, repository, initializer);
        versionRequirements[distributorId] = requirement;
        emit VersionChanged(distributorId, requirement, requirement);
    }

    function _newDistriubutionRecord(bytes32 distributorId, address source, address initializer) private {
        if (distirbutionsSet.contains(distributorId)) revert DistributionExists(distributorId);
        distirbutionsSet.add(distributorId);
        distributionComponents[distributorId] = DistributionComponent(source, initializer);
        emit DistributionAdded(distributorId, source, initializer);
    }
    function _addDistribution(bytes32 id, address initializerAddress) internal {
        ICodeIndex codeIndex = getContractsIndex();
        address distributionLocation = codeIndex.get(id);
        if (distributionLocation == address(0)) revert DistributionNotFound(id);
        bytes32 distributorsId = keccak256(abi.encode(id, initializerAddress));
        _newDistriubutionRecord(distributorsId, distributionLocation, initializerAddress);
    }

    function _removeDistribution(bytes32 distributorsId) internal virtual {
        if (!distirbutionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        distirbutionsSet.remove(distributorsId);
        delete distributionComponents[distributorsId];
        delete versionRequirements[distributorsId];
        emit DistributionRemoved(distributorsId);
    }

    /**
     * @notice Internal function to instantiate a new instance.
     * @dev WARNING: This function will DELEGATECALL to initializer if such is provided. Initializer contract MUST be trusted by distributor.
     */
    function _instantiate(
        bytes32 distributorsId,
        bytes memory args
    ) internal virtual returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion) {
        if (!distirbutionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        LibSemver.VersionRequirement memory versionRequirement = versionRequirements[distributorsId];

        // External initializer is provided, delegatecall to it
        // Countrary, if no initializer is provided, the distribution is expected to be self-initializing
        bool externallyInitialized = distributionComponent.initializer == address(0);
        bytes4 selector = IInitializer.initialize.selector;
        bytes memory instantiationArgs = externallyInitialized ? args : bytes("");
        address distributionLocation;
        numInstances++;
        uint256 instanceId = numInstances;

        if (LibSemver.toUint256(versionRequirement.version) == 0) {
            // Unversioned distribution, expect IDistribution
            distributionLocation = distributionComponent.distributionLocation;
            // Name and version are inferred from what the distribution provides
            (instances, distributionName, distributionVersion) = IDistribution(distributionLocation).instantiate(
                instantiationArgs
            );
            // Unversioned distributions are considered to be at version 0, and are not expected to change
            // This might change in the future, as it could make sence to inherit `distributionVersion` from the distribution
            // Yet for ease of runtime validation and to avoid potential issues, we keep it at 0
            instanceVersions[numInstances] = LibSemver.parse(0);
        } else {
            // Versioned distribution, expect IRepository
            IRepository repository = IRepository(distributionComponent.distributionLocation);
            IRepository.Source memory repoSource = repository.get(versionRequirement);
            ICodeIndex codeIndex = getContractsIndex();
            distributionLocation = codeIndex.get(repoSource.sourceId);
            if (distributionLocation == address(0)) revert DistributionNotFound(repoSource.sourceId);
            (instances, , ) = IDistribution(distributionLocation).instantiate(instantiationArgs);
            distributionName = repository.repositoryName();
            distributionVersion = LibSemver.toUint256(repoSource.version);
            instanceVersions[numInstances] = repoSource.version;
        }

        if (externallyInitialized) {
            (bool success, bytes memory result) = address(distributionComponent.initializer).delegatecall(
                abi.encodeWithSelector(selector, instances, args)
            );
            if (!success) {
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert("initializer delegatecall failed without revert reason");
                }
            }
        }

        {
            uint256 instancesLength = instances.length;
            for (uint256 i; i < instancesLength; ++i) {
                instanceIds[instances[i]] = instanceId;
                distributionOf[instanceId] = distributorsId;
            }
        }
        emit Instantiated(distributorsId, instanceId, distributionVersion, instances, args);
    }

    /**
     * @inheritdoc IERC7746
     * @notice This is ERC7746 hook must be called by instance methods that access scope is limited to the same instance or distribution
     * @dev it will revert if: (1) `msg.sender` is not a valid instance; (2) `maybeInstance` is not a valid instance (3) `instanceId` belongs to disactivated distribution
     */
    function beforeCall(
        bytes memory config,
        bytes4,
        address maybeInstance,
        uint256,
        bytes memory
    ) external view virtual returns (bytes memory) {
        address target = config.length > 0 ? abi.decode(config, (address)) : msg.sender;
        bytes32 distributorsId = distributionOf[getInstanceId(maybeInstance)];
        uint256 instanceId = getInstanceId(maybeInstance);
        if (
            distributorsId != bytes32(0) &&
            getInstanceId(target) == instanceId &&
            distirbutionsSet.contains(distributorsId)
        ) {
            // ToDo: This check could be based on DistributionOf, hence allowing cross-instance calls
            // Use layerConfig to allow client to configure requirement for the call
            if (!LibSemver.compare(instanceVersions[instanceId], versionRequirements[distributorsId])) {
                revert VersionOutdated(distributorsId, LibSemver.toString(instanceVersions[instanceId]));
            }
            return abi.encode(distributorsId, "");
        }
        revert InvalidInstance(maybeInstance);
    }
    /**
     * @inheritdoc IERC7746
     * @notice This is ERC7746 hook must be called by instance methods that access scope is limited to the same instance or distribution
     * @dev it will revert if: (1) `msg.sender` is not a valid instance; (2) `maybeInstance` is not a valid instance (3) `instanceId` belongs to disactivated distribution
     */
    function afterCall(
        bytes memory config,
        bytes4,
        address maybeInstance,
        uint256,
        bytes memory,
        bytes memory
    ) external virtual {
        address target = config.length > 0 ? abi.decode(config, (address)) : msg.sender;
        bytes32 distributorsId = distributionOf[getInstanceId(maybeInstance)];
        uint256 instanceId = getInstanceId(maybeInstance);
        if ((getInstanceId(target) != getInstanceId(maybeInstance)) && distirbutionsSet.contains(distributorsId)) {
            revert InvalidInstance(maybeInstance);
        }
        if (!LibSemver.compare(instanceVersions[instanceId], versionRequirements[distributorsId])) {
            revert VersionOutdated(distributorsId, LibSemver.toString(instanceVersions[instanceId]));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IDistributor).interfaceId || super.supportsInterface(interfaceId);
    }

    function _changeVersion(bytes32 distributionId, LibSemver.VersionRequirement memory newRequirement) internal {
        if (!distirbutionsSet.contains(distributionId)) revert DistributionNotFound(distributionId);
        LibSemver.VersionRequirement memory oldRequirement = versionRequirements[distributionId];
        if (LibSemver.toUint256(oldRequirement.version) == 0) {
            revert UniversionedDistribution(distributionId);
        }
        if (LibSemver.toUint256(newRequirement.version) == 0) {
            revert InvalidVersionRequested(distributionId, LibSemver.toString(newRequirement.version));
        }
        if (LibSemver.areEqual(oldRequirement.version, newRequirement.version)) {
            revert InvalidVersionRequested(distributionId, LibSemver.toString(newRequirement.version));
        }
        versionRequirements[distributionId] = newRequirement;
    }
}
