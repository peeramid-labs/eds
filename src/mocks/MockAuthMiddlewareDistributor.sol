// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDistributor.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../versioning/LibSemver.sol";

/**
 * Simplified mock for testing AuthorizationMiddleware
 */
contract MockAuthMiddlewareDistributor is IDistributor, ERC165 {
    bytes public beforeCallReturnValue;
    bool public beforeCallCalled;
    bool public afterCallCalled;

    function setBeforeCallReturn(bytes memory value) external {
        beforeCallReturnValue = value;
    }

    // Implement IERC7746 functions
    function beforeCall(bytes memory, bytes4, address, uint256, bytes memory) external override returns (bytes memory) {
        beforeCallCalled = true;
        return beforeCallReturnValue;
    }

    function afterCall(bytes memory, bytes4, address, uint256, bytes memory, bytes memory) external override {
        afterCallCalled = true;
        // No return value needed
    }

    // Minimal implementations of required IDistributor functions
    function getDistributions() external pure override returns (bytes32[] memory) {
        bytes32[] memory distributions = new bytes32[](0);
        return distributions;
    }

    function getDistributionURI(bytes32) external pure override returns (string memory) {
        return "";
    }

    function instantiate(
        bytes32,
        bytes calldata
    ) external payable override returns (address[] memory, bytes32, uint256) {
        address[] memory instances = new address[](0);
        return (instances, bytes32(0), 0);
    }

    function addDistribution(bytes32, address, string memory) external pure override {}
    function disableDistribution(bytes32) external pure override {}
    function getDistributionId(address) external pure override returns (bytes32) {
        return bytes32(0);
    }
    function getAppId(address) external pure override returns (uint256) {
        return 0;
    }
    function addDistribution(
        IRepository,
        address,
        LibSemver.VersionRequirement memory,
        string memory
    ) external pure override {}
    function changeVersion(bytes32, LibSemver.VersionRequirement memory) external pure override {}
    function addVersionMigration(
        bytes32,
        LibSemver.VersionRequirement memory,
        LibSemver.VersionRequirement memory,
        bytes32,
        MigrationStrategy,
        bytes memory
    ) external pure override {}
    function removeVersionMigration(bytes32) external pure override {}
    function getVersionMigration(bytes32) external pure override returns (MigrationPlan memory) {
        return
            MigrationPlan({
                from: LibSemver.VersionRequirement({
                    version: LibSemver.parse(0),
                    requirement: LibSemver.requirements.ANY
                }),
                to: LibSemver.VersionRequirement({
                    version: LibSemver.parse(0),
                    requirement: LibSemver.requirements.ANY
                }),
                migrationHash: bytes32(0),
                strategy: MigrationStrategy.CALL,
                distributorCalldata: bytes(""),
                distributionId: bytes32(0)
            });
    }
    function upgradeUserInstance(
        uint256,
        bytes32,
        bytes calldata
    ) external pure override returns (LibSemver.Version memory) {
        return LibSemver.parse(0);
    }
    function onDistributorChanged(
        uint256,
        address,
        bytes[] memory
    ) external pure override returns (bool[] memory, bytes[] memory) {
        bool[] memory statuses = new bool[](0);
        bytes[] memory results = new bytes[](0);
        return (statuses, results);
    }
    function getIdFromAlias(string memory) external pure override returns (bytes32) {
        return bytes32(0);
    }
    function calculateDistributorId(address, address) external pure override returns (bytes32) {
        return bytes32(0);
    }

    // Override supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IDistributor).interfaceId ||
            interfaceId == type(IERC7746).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function calculateDistributorId(bytes32, address) external returns (bytes32) {
        return bytes32("testDistributionId");
    }
}
