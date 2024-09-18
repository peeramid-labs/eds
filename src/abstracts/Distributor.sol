// SPDX-License-Identifier: MIT

pragma solidity =0.8.20;
import "../interfaces/IDistribution.sol";
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IInitializer.sol";
import "../abstracts/CodeIndexer.sol";
abstract contract Distributor is IDistributor, CodeIndexer {

    struct DistributionComponent {
        bytes32 id;
        address initializer;
    }
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private distirbutionsSet;
    mapping(bytes32 => IInitializer) private initializers;
    mapping(address => bytes32) private distributionOf;
    mapping(bytes32 => DistributionComponent) private distributionComponents;

    function getDistributions() public view returns (bytes32[] memory) {
        return distirbutionsSet.values();
    }

    function distributionId(address instance) public view virtual returns (bytes32 instanceId)
    {
        return distributionOf[instance];
    }

    function getDistributionURI(bytes32 distributorsId) public view returns (string memory) {
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        ICodeIndex codeIndex = getContractsIndex();
        return IDistribution(codeIndex.get(distributionComponent.id)).getMetadata();
    }

    function _addDistribution(bytes32 id, bytes32 initId) internal virtual {
        ICodeIndex codeIndex = getContractsIndex();
        address initializerAddress = codeIndex.get(initId);
        if (codeIndex.get(id) == address(0)) revert DistributionNotFound(id);
        if (initializerAddress == address(0) && initId != bytes32(0)) revert InitializerNotFound(initId);
        bytes32 distributorsId = keccak256(abi.encode(id,initId));
        if (distirbutionsSet.contains(distributorsId)) revert DistributionExists(distributorsId);
        distirbutionsSet.add(distributorsId);
        distributionComponents[distributorsId] = DistributionComponent(id, initializerAddress);
        emit DistributionAdded(id, initId);
    }

    function _removeDistribution(bytes32 distributorsId) internal virtual {
        if (!distirbutionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        distirbutionsSet.remove(distributorsId);
        initializers[distributorsId] = IInitializer(address(0));
        emit DistributionRemoved(distributorsId);
    }

    function _instantiate(bytes32 distributorsId, bytes memory args) internal virtual returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion) {
        ICodeIndex codeIndex = getContractsIndex();
        if (!distirbutionsSet.contains(distributorsId)) revert DistributionNotFound(distributorsId);
        DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        address initializer = address(initializers[distributionComponent.id]);
        bytes4 selector = IInitializer.initialize.selector;
        bytes memory instantiationArgs = initializer != address(0) ? args : bytes ("");
        (instances, distributionName, distributionVersion) = IDistribution(codeIndex.get(distributionComponent.id)).instantiate(instantiationArgs);
        if (initializer != address(0)) {
            (bool success, bytes memory result) = address(distributionComponent.initializer).delegatecall(
                abi.encodeWithSelector(selector, instances, args)
            );
            require(success, string(result));
        }
        for (uint256 i = 0; i < instances.length; i++) {
            distributionOf[instances[i]] = distributorsId;
        }
        emit Instantiated(distributorsId, args);
        return (instances, distributionName, distributionVersion);
    }

    function beforeCall(
        bytes memory,
        bytes4,
        address instance,
        uint256,
        bytes memory
    ) public view virtual returns (bytes memory) {
        bytes32 distributorsId = distributionOf[instance];
        // DistributionComponent memory distributionComponent = distributionComponents[distributorsId];
        if (distributorsId != bytes32(0) && distirbutionsSet.contains(distributorsId) == true) {
            return abi.encode(distributorsId, "");
        } else {
            revert InvalidInstance(instance);
        }
    }

    function afterCall(
        bytes memory layerConfig,
        bytes4 selector,
        address sender,
        uint256 value,
        bytes memory data,
        bytes memory beforeCallResult
    ) public virtual {}
}
