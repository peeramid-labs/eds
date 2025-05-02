// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// We need to make sure the function selector matches what Distributor expects
import {IInitializer} from "../interfaces/IInitializer.sol";

contract MockNoReasonInitializer {
    // This function handles the low-level call when given just the 2 parameters
    // This matches what Distributor actually passes in the delegatecall
    function initialize(address[] memory, bytes memory) external pure {
        // Revert without a reason string
        assembly {
            revert(0, 0)
        }
    }

    // Solidity gets the selector from the first function that matches the name and parameter count
    // So we need to account for both possible calls
    function initialize(bytes32, address[] memory, bytes32, uint256, bytes calldata) external pure {
        // In case this gets called directly, still revert without a reason
        assembly {
            revert(0, 0)
        }
    }
}
