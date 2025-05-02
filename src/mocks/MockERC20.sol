// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    // Add instantiate function to handle distribution instantiation
    function instantiate(bytes calldata) external returns (address[] memory instances) {
        // Parse installer and args if needed
        // For testing, we just return this contract as the instance
        instances = new address[](1);
        instances[0] = address(this);
        return instances;
    }
}
