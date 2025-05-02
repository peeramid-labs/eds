// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../distributors/OwnableDistributor.sol";

import {ShortString, ShortStrings} from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract MockOwnableDistributor is OwnableDistributor {

    uint256 public lastCallAppId;
    bytes32 public lastCallMigrationId;
    bytes public lastCallUserCalldata;
    bool public upgradeUserInstanceRevertState;
    constructor(
      address owner_
    ) OwnableDistributor(owner_) {}

   function renounceApp(uint256 appId) public {
    appsRenounced[appId] = true;
   }

   function setMigration(uint256 appId, address migration) public {
    appsUndergoingMigration[appId] = migration;
   }

   function getLastUpgradeUserInstanceCall() public view returns (uint256 appId, bytes32 migrationId, bytes memory userCalldata) {
    return (lastCallAppId, lastCallMigrationId, lastCallUserCalldata);
   }


   function upgradeUserInstance(uint256 appId, bytes32 migrationId, bytes calldata userCalldata) public override returns (LibSemver.Version memory newVersion) {
    newVersion = super.upgradeUserInstance(appId, migrationId, userCalldata);
    lastCallAppId = appId;
    lastCallMigrationId = migrationId;
    lastCallUserCalldata = userCalldata;
   }

   function setUpgradeUserInstanceRevertState(bool revertState) public {
    upgradeUserInstanceRevertState = revertState;
   }
}
