// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IDistribution.sol";
import {IInitializer} from "../interfaces/IInitializer.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IDistributor} from "../interfaces/IDistributor.sol";
contract WrappedProxyInitializer is IInitializer {
    function initialize(
        address distribution,
        bytes32,
        uint256,
        bytes calldata data
    ) public returns (address[] memory instances) {
        // (address installer, bytes memory args) = abi.decode(data, (address, bytes));
        bytes memory encodedData = abi.encode(msg.sender, data);
        try IDistribution(distribution).instantiate(encodedData) returns (
            address[] memory _newAppComponents,
            bytes32,
            uint256
        ) {
            return _newAppComponents;
        } catch Error(string memory reason) {
            revert(reason);
        } catch Panic(uint errorCode) {
            revert IDistributor.DistributionInstantiationPanic(errorCode);
        } catch (bytes memory lowLevelData) {
            revert IDistributor.DistributionInstantiationFailed(lowLevelData);
        }
    }
}
