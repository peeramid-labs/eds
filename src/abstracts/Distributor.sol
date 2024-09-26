// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IDistribution.sol";
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IInitializer.sol";
import "../abstracts/CodeIndexer.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
abstract contract Distributor is IDistributor, CodeIndexer, ERC165 {
    struct DistributionComponent {
        bytes32 id;
        address initializer;
    }
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private distirbutionsSet;
    mapping(bytes32 => IInitializer) private initializers;
    mapping(address => uint256) private instanceIds;
    uint256 numInstances;
    mapping(uint256 => bytes32) public distributionOf;
    mapping(bytes32 => DistributionComponent) private distributionComponents;

    function getDistributions() public view returns (bytes32[] memory) {
        return distirbutionsSet.values();
    }

    function getDistributionId(address instance) public view virtual returns (bytes32) {
        return distributionOf[getInstanceId(instance)];
    }

    function getInstanceId(address instance) public view virtual returns (uint256) {
        return instanceIds[instance];
    }

    function getDistributionURI(bytes32 distributorsId) public view returns (string memory) {
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        ICodeIndex codeIndex = getContractsIndex();
        return IDistribution(codeIndex.get(distributionComponent.id)).getMetadata();
    }

    function _addDistribution(bytes32 id, address initializerAddress) internal virtual {
        ICodeIndex codeIndex = getContractsIndex();
        if (codeIndex.get(id) == address(0)) revert DistributionNotFound(id);
        bytes32 distributorsId = keccak256(abi.encode(id, initializerAddress));
        if (distirbutionsSet.contains(distributorsId)) revert DistributionExists(distributorsId);
        distirbutionsSet.add(distributorsId);
        distributionComponents[distributorsId] = DistributionComponent(id, initializerAddress);
        emit DistributionAdded(id, initializerAddress);
    }

    function _removeDistribution(bytes32 distributorsId) internal virtual {
        if (!distirbutionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        distirbutionsSet.remove(distributorsId);
        initializers[distributorsId] = IInitializer(address(0));
        emit DistributionRemoved(distributorsId);
    }

    function _instantiate(
        bytes32 distributorsId,
        bytes memory args
    ) internal virtual returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion) {
        ICodeIndex codeIndex = getContractsIndex();
        if (!distirbutionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        address initializer = address(initializers[distributionComponent.id]);
        bytes4 selector = IInitializer.initialize.selector;
        // bytes memory instantiationArgs = initializer != address(0) ? args : bytes ("");
        (instances, distributionName, distributionVersion) = IDistribution(codeIndex.get(distributionComponent.id))
            .instantiate(args);
        if (initializer != address(0)) {
            (bool success, bytes memory result) = address(distributionComponent.initializer).delegatecall(
                abi.encodeWithSelector(selector, instances, args)
            );
            require(success, string(result));
        }
        numInstances++;
        uint256 instanceId = numInstances;
        for (uint256 i = 0; i < instances.length; i++) {
            instanceIds[instances[i]] = instanceId;
            distributionOf[instanceId] = distributorsId;
        }
        emit Instantiated(distributorsId, instanceId, args, instances);
        return (instances, distributionName, distributionVersion);
    }

    /*
     * @dev This is ERC7746 implementation
     * This hook must be called by instance methods that access scope is
     * limited to the same instance or distribution
     * it will revert if `msg.sender` is not a valid instance
     * it will revert if `maybeInstance` is not a valid instance
     * it will revert if instanceId belongs to disactivated distribution
     */
    function beforeCall(
        bytes memory config,
        bytes4,
        address maybeInstance,
        uint256,
        bytes memory
    ) public view virtual returns (bytes memory) {
        (address target) = abi.decode(config, (address));
        bytes32 distributorsId = distributionOf[getInstanceId(maybeInstance)];
        if (
            distributorsId != bytes32(0) &&
            getInstanceId(target) == getInstanceId(maybeInstance) &&
            distirbutionsSet.contains(distributorsId) == true
        ) {
            // ToDo: This check could be based on DistributionOf, hence allowing cross-instance calls
            // Use layerConfig to allow client to configure requirement for the call
            return abi.encode(distributorsId, "");
        }
        revert InvalidInstance(maybeInstance);
    }

    function afterCall(
        bytes memory config,
        bytes4,
        address maybeInstance,
        uint256,
        bytes memory,
        bytes memory
    ) public virtual {
        (address target) = abi.decode(config, (address));
        bytes32 distributorsId = distributionOf[getInstanceId(maybeInstance)];
        if (
            (getInstanceId(target) != getInstanceId(maybeInstance)) &&
            distirbutionsSet.contains(distributorsId) == true
        ) {
            revert InvalidInstance(maybeInstance);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IDistributor).interfaceId || super.supportsInterface(interfaceId);
    }
}
