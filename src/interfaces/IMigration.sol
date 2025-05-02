// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IRepository} from "./IRepository.sol";
import {LibSemver} from "../versioning/LibSemver.sol";
interface IMigration {
    function migrate(
        address[] memory instances,
        LibSemver.Version memory oldVersion,
        LibSemver.Version memory newVersion,
        IRepository repository,
        bytes calldata distributorCalldata,
        bytes calldata userCalldata
    ) external;
}
