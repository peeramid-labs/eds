// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IDistributor} from "./IDistributor.sol";
import "../ERC7746/ILayer.sol";

interface IInstaller is ILayer {
    error InvalidDistributor(IDistributor distributor);
    error InvalidTarget(address target);
    error AllDistributionsAllowed(IDistributor distributor);
    event DistributorAdded(IDistributor indexed distributor);
    event DistributorRemoved(IDistributor indexed distributor);

    function addDistributor(IDistributor distributor) external;
    function removeDistributor(IDistributor distributor) external;

    function allowDistribution(IDistributor distributor, bytes32 distributionId) external;

    function disallowDistribution(IDistributor distributor, bytes32 distributionId) external;

    function listPermittedDistributions(IDistributor distributor) external view returns (bytes32[] memory);

    function allowAllDistributions(IDistributor distributor) external;

    function disallowAllDistributions(IDistributor distributor) external;

    function isDistributor(IDistributor distributor) external view returns (bool);

    function getDistributors() external view returns (address[] memory);

    event Installed(address indexed instance, bytes32 indexed distributionId, bytes32 indexed permissions, bytes args);
    event Uninstalled(address indexed instance);

    function install(
        IDistributor distributor,
        bytes32 distributionId,
        bytes calldata args
    ) external payable returns (uint256 instanceId);

    function uninstall(uint256 instanceId) external;

    function getInstance(uint256 instanceId) external view returns (address[] memory instaneContracts);

    function getInstancesNum() external view returns (uint256);

    function isInstance(address instance) external view returns (bool);

    function distributorOf(address instance) external view returns (IDistributor);

    function target() external view returns (address);

    error NotAnInstance(address instance);
}
