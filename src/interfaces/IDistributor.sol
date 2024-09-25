// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./IDistribution.sol";
import {IERC7746} from "../interfaces/IERC7746.sol";
import "../interfaces/IRepository.sol";
import "../libraries/LibSemver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
interface IDistributor is IERC7746, IERC165 {
    error DistributionNotFound(bytes32 id);
    error DistributionExists(bytes32 id);
    error InitializerNotFound(bytes32 id);
    error InvalidInstance(address instance);
    event Instantiated(bytes32 indexed distributionId, bytes indexed argsHash, address[] instances);
    event DistributionRemoved(bytes32 indexed id);

    event DistributionAdded(bytes32 indexed id, address indexed initializer);

    function getDistributions() external view returns (bytes32[] memory distributorIds);

    function getDistributionURI(bytes32 distributorId) external view returns (string memory);

    function instantiate(
        bytes32 distributorId,
        bytes calldata args
    ) external returns (address[] memory, bytes32 distributionName, uint256 distributionVersion);

    function addDistribution(bytes32 distributorId, address initializer) external;

    function removeDistribution(bytes32 distributorId) external;

    function getDistributionId(address instance) external view  returns (bytes32);
    function getInstanceId(address instance) external view  returns (uint256);

}
