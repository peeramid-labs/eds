// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../distributors/OwnableDistributor.sol";

import {ShortString, ShortStrings} from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract MockOwnableDistributor is OwnableDistributor {

    constructor(
      address owner_
    ) OwnableDistributor(owner_) {}

   function renounceApp(uint256 appId) public {
    appsRenounced[appId] = true;
   }

   function setMigration(uint256 appId, address migration) public {
    appsUndergoingMigration[appId] = migration;
   }
}
