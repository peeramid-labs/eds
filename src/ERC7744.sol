// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.28;
import {IERC7744} from "./IERC7744.sol";

/**
 * @title Byte Code Indexer Contract
 * @notice You can use this contract to index contracts by their bytecode.
 * @dev This allows to query contracts by their bytecode instead of addresses.
 * @author Tim Pechersky (@Peersky)
 */
contract ERC7744 is IERC7744 {
    mapping(bytes32 => address) private index;

    function isValidContainer(address container) private view returns (bool) {
        bytes memory code = container.code;
        bytes32 codeHash = address(container).codehash;
        uint256 containerCodeLength;
        assembly {
            containerCodeLength := extcodesize(container)
        }
        bool is7702 = containerCodeLength == 23;
        // Contract should have non-empty code and valid codehash
        return (code.length > 0 && codeHash != bytes32(0) && !is7702);
    }

    /**
     * @notice Registers a contract in the index by its bytecode hash
     * @param container The contract to register
     * @dev `msg.codeHash` will be used
     * @dev It will revert if the contract is already indexed or if returns EIP7702 hash
     */
    function register(address container) external {
        address etalon = index[container.codehash];
        require(isValidContainer(container), "Invalid container");
        if (etalon != address(0)) {
            if (isValidContainer(etalon)) revert alreadyExists(container.codehash, container);
        }
        index[container.codehash] = container;
        emit Indexed(container, container.codehash);
    }

    /**
     * @notice Returns the contract address by its bytecode hash
     * @dev returns zero if the contract is not indexed
     * @param id The bytecode hash
     * @return The contract address
     */
    function get(bytes32 id) external view returns (address) {
        return index[id];
    }
}
