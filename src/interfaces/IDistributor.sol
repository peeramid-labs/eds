// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
import "./IDistribution.sol";
import "../ERC7746/ILayer.sol";
import "../interfaces/IRepository.sol";
import "../libraries/LibSemver.sol";
interface IDistributor is ILayer {
    error DistributionNotFound(bytes32 id);
    error DistributionExists(bytes32 id);
    error InitializerNotFound(bytes32 id);
    error InvalidInstance(address instance);
    event Instantiated(bytes32 indexed distributionId, bytes indexed argsHash);
    event DistributionRemoved(bytes32 indexed id);

    event DistributionAdded(bytes32 indexed id, bytes32 indexed initializerId);

    function getDistributions() external view returns (bytes32[] memory distributorIds);

    function getDistributionURI(bytes32 distributorId) external view returns (string memory);

    function instantiate(
        bytes32 distributorId,
        bytes calldata args
    ) external returns (address[] memory, bytes32 distributionName, uint256 distributionVersion);

    function addDistribution(bytes32 distributorId, bytes32 initializer) external;

    function removeDistribution(bytes32 distributorId) external;
}
