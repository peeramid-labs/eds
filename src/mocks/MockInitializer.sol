// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// We need to make sure the function selector matches what Distributor expects
import {IInitializer} from "../interfaces/IInitializer.sol";
import {IDistribution} from "../interfaces/IDistribution.sol";
import "hardhat/console.sol";
contract MockInitializer is IInitializer {
    // This function handles the low-level call when given just the 2 parameters
    // This matches what Distributor actually passes in the delegatecall
    function initialize(
        address distribution,
        bytes32,
        uint256,
        bytes calldata userArgs
    ) external returns (address[] memory instances) {
        // Revert with a specific reason if args contain "FAIL"
        if (keccak256(userArgs) == keccak256(bytes("FAIL"))) {
            // Use bytes for the error message to ensure it's properly passed back
            bytes memory errorMsg = bytes("Initializer failed as requested");
            assembly {
                revert(add(32, errorMsg), mload(errorMsg))
            }
        }
        if (keccak256(userArgs) == keccak256(bytes("REVERT"))) {
            revert();
        }
        // Otherwise, succeed
        (instances, , ) = IDistribution(distribution).instantiate(userArgs);
        return instances;
    }

    // Solidity gets the selector from the first function that matches the name and parameter count
    // So we need to account for both possible calls
    function initialize(bytes32, address[] memory, bytes32, uint256, bytes calldata args) external pure {
        // In case this gets called directly, delegate to the 2-parameter version
        if (keccak256(args) == keccak256(bytes("FAIL"))) {
            bytes memory errorMsg = bytes("Initializer failed as requested");
            assembly {
                revert(add(32, errorMsg), mload(errorMsg))
            }
        }
    }
}
