// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDistributor.sol";
import "../interfaces/IERC7746.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../versioning/LibSemver.sol";

contract MockDistributorForTest is IDistributor, ERC165 {
    // Simple storage for testing
    mapping(address => uint256) public appIds;
    mapping(uint256 => bytes32) public distributionOf;
    mapping(bytes32 => bool) public distributionExists;
    mapping(uint256 => address[]) public appComponents;
    uint256 public numAppInstances;

    // Return values for beforeCall and afterCall tests
    bytes public beforeCallReturnValue;

    // Upgrade user instance call storage
    struct UpgradeCall {
        uint256 appId;
        bytes32 migrationId;
        bytes userCalldata;
    }
    UpgradeCall public lastUpgradeCall;
    bool public shouldRevertOnUpgrade;

    constructor() {
        // Set test data
        distributionExists[bytes32("testDistributionId")] = true;
        shouldRevertOnUpgrade = false;
    }

    // Control revert behavior
    function setUpgradeUserInstanceRevertState(bool _shouldRevert) external {
        shouldRevertOnUpgrade = _shouldRevert;
    }

    // Get the last upgrade call parameters
    function getLastUpgradeUserInstanceCall() external view returns (UpgradeCall memory) {
        return lastUpgradeCall;
    }

    // Function to add a mock distribution for testing
    function addMockDistribution(bytes32 distributionId) external {
        distributionExists[distributionId] = true;
    }

    function setBeforeCallReturn(bytes memory value) external {
        beforeCallReturnValue = value;
    }

    // Implement required IDistributor functions
    function getDistributions() external view override returns (bytes32[] memory) {
        bytes32[] memory distributions = new bytes32[](1);
        distributions[0] = bytes32("testDistributionId");
        return distributions;
    }

    function getDistributionURI(bytes32) external pure override returns (string memory) {
        return "https://example.com/test-distribution";
    }

    function instantiate(
        bytes32 distributionId,
        bytes calldata
    ) external payable override returns (address[] memory, bytes32, uint256) {
        require(distributionExists[distributionId], "Distribution not found");

        numAppInstances++;
        uint256 appId = numAppInstances;

        address[] memory instances = new address[](1);
        instances[0] = address(uint160(appId)); // Use appId as address for testing

        // Register the app
        appIds[instances[0]] = appId;
        distributionOf[appId] = distributionId;
        appComponents[appId] = instances;

        return (instances, bytes32("testDistributionName"), 1);
    }

    function addDistribution(bytes32, address, string memory) external pure override {
        // No-op for testing
    }

    function disableDistribution(bytes32) external pure override {
        // No-op for testing
    }

    function getDistributionId(address) external pure override returns (bytes32) {
        return bytes32("testDistributionId");
    }

    function getAppId(address appComponent) external view override returns (uint256) {
        return appIds[appComponent];
    }

    function addDistribution(
        IRepository,
        address,
        LibSemver.VersionRequirement memory,
        string memory
    ) external pure override {
        // No-op for testing
    }

    function changeVersion(bytes32, LibSemver.VersionRequirement memory) external pure override {
        // No-op for testing
    }

    function addVersionMigration(
        bytes32,
        LibSemver.VersionRequirement memory,
        LibSemver.VersionRequirement memory,
        bytes32,
        MigrationStrategy,
        bytes memory
    ) external pure override {
        // No-op for testing
    }

    function removeVersionMigration(bytes32) external pure override {
        // No-op for testing
    }

    function getVersionMigration(bytes32) external pure override returns (MigrationPlan memory) {
        return
            MigrationPlan({
                from: LibSemver.VersionRequirement({
                    version: LibSemver.parse(1),
                    requirement: LibSemver.requirements.ANY
                }),
                to: LibSemver.VersionRequirement({
                    version: LibSemver.parse(2),
                    requirement: LibSemver.requirements.ANY
                }),
                migrationHash: bytes32(0),
                strategy: MigrationStrategy.CALL,
                distributorCalldata: bytes(""),
                distributionId: bytes32("testDistributionId")
            });
    }

    function upgradeUserInstance(
        uint256 appId,
        bytes32 migrationId,
        bytes calldata userCalldata
    ) external override returns (LibSemver.Version memory) {
        // Save the call data
        lastUpgradeCall = UpgradeCall({appId: appId, migrationId: migrationId, userCalldata: userCalldata});

        // Optionally revert for testing
        if (shouldRevertOnUpgrade) {
            revert("Upgrade reverted for testing");
        }

        return LibSemver.parse(2);
    }

    function onDistributorChanged(
        uint256,
        address,
        bytes[] memory
    ) external pure override returns (bool[] memory statuses, bytes[] memory results) {
        bool[] memory _statuses = new bool[](1);
        bytes[] memory _results = new bytes[](1);
        _statuses[0] = true;
        return (_statuses, _results);
    }

    function getIdFromAlias(string memory) external pure override returns (bytes32) {
        return bytes32("testDistributionId");
    }

    function calculateDistributorId(address, address) external pure override returns (bytes32) {
        return bytes32("testDistributionId");
    }

    // Implement IDistributor's IERC7746 functions
    function beforeCall(
        bytes memory,
        bytes4,
        address,
        uint256,
        bytes memory
    ) external view override returns (bytes memory) {
        return beforeCallReturnValue;
    }

    function afterCall(bytes memory, bytes4, address, uint256, bytes memory, bytes memory) external pure override {
        // No-op for testing
    }

    // Implement supportsInterface to return true for IDistributor and IERC7746
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IDistributor).interfaceId ||
            interfaceId == type(IERC7746).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
