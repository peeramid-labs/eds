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

    function getDistributions() external view returns (bytes32[] memory ids);

    function getDistributionURI(bytes32 id) external view returns (string memory);

    function instantiate(bytes32 id, bytes calldata args) external returns (address[] memory);

    function addDistribution(bytes32 id, bytes32 initializer) external;

    function removeDistribution(bytes32 id) external;
}
