// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import {IDistributor} from "./IDistributor.sol";
import {IERC7746} from "../interfaces/IERC7746.sol";

interface IInstaller is IERC7746 {
    error InvalidDistributor(IDistributor distributor);
    error InvalidTarget(address target);
    error alreadyAllowed(IDistributor distributor);
    error DistributionIsNotPermitted(IDistributor distributor, bytes32 distributionId);

    event DistributorWhitelisted(IDistributor indexed distributor);
    event DistributorWhitelistRevoked(IDistributor indexed distributor);

    event DistributionAllowed(IDistributor indexed distributor, bytes32 indexed distributionId);
    event DistributionDisallowed(IDistributor indexed distributor, bytes32 indexed distributionId);


    function allowDistribution(IDistributor distributor, bytes32 distributionId) external;

    function disallowDistribution(IDistributor distributor, bytes32 distributionId) external;

    function whitelistedDistributions(IDistributor distributor) external view returns (bytes32[] memory);

    function whitelistDistributor(IDistributor distributor) external;

    function revokeWhitelistedDistributor(IDistributor distributor) external;

    function isDistributor(IDistributor distributor) external view returns (bool);

    function getWhitelistedDistributors() external view returns (address[] memory);

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
