// SPDX-License-Identifier: MIT

pragma solidity =0.8.20;
import "../interfaces/IDistribution.sol";
import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IInitializer.sol";
import "../abstracts/CodeIndexer.sol";

abstract contract Distributor is IDistributor, CodeIndexer {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private distirbutionsSet;
    mapping(bytes32 => IInitializer) private initializers;
    mapping(address => bytes32) private distributionOf;

    function getDistributions() public view returns (bytes32[] memory) {
        return distirbutionsSet.values();
    }

    function distributionId(address instance) public view virtual returns (bytes32 instanceId)
    {
        return distributionOf[instance];
    }

    function getDistributionURI(bytes32 id) public view returns (string memory) {
        ICodeIndex codeIndex = getContractsIndex();
        return IDistribution(codeIndex.get(id)).getMetadata();
    }

    function _addDistribution(bytes32 id, bytes32 initId) internal virtual {
        ICodeIndex codeIndex = getContractsIndex();
        address initializerAddress = codeIndex.get(initId);
        if (codeIndex.get(id) == address(0)) revert DistributionNotFound(id);
        if (initializerAddress == address(0) && initId != bytes32(0)) revert InitializerNotFound(initId);
        if (distirbutionsSet.contains(id)) revert DistributionExists(id);
        distirbutionsSet.add(id);
        initializers[id] = IInitializer(initializerAddress);
        emit DistributionAdded(id, initId);
    }

    function _removeDistribution(bytes32 id) internal virtual {
        if (!distirbutionsSet.contains(id)) revert DistributionNotFound(id);
        distirbutionsSet.remove(id);
        emit DistributionRemoved(id);
    }

    function _instantiate(bytes32 id, bytes calldata args) internal virtual returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion) {
        ICodeIndex codeIndex = getContractsIndex();
        if (!distirbutionsSet.contains(id)) revert DistributionNotFound(id);
        (instances, distributionName, distributionVersion) = IDistribution(codeIndex.get(id)).instantiate();
        bytes4 selector = IInitializer.initialize.selector;
        // This ensures instance owner (distributor) performs initialization.
        // It is distirbutor responsibility to make sure calldata and initializer are safe to execute
        address initializer = address(initializers[id]);
        if (initializer != address(0)) {
            (bool success, bytes memory result) = address(initializers[id]).delegatecall(
                abi.encodeWithSelector(selector, instances, args)
            );
            require(success, string(result));
        }
        for (uint256 i = 0; i < instances.length; i++) {
            distributionOf[instances[i]] = id;
        }
        emit Instantiated(id, args);
        return (instances, distributionName, distributionVersion);
    }

    function beforeCall(
        bytes memory,
        bytes4,
        address instance,
        uint256,
        bytes memory
    ) public view virtual returns (bytes memory) {
        bytes32 id = distributionOf[instance];
        if (id != bytes32(0) && distirbutionsSet.contains(id) == true) {
            return "";
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
