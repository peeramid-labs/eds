// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../abstracts/Distributor.sol";

contract OwnableDistributor is Distributor, Ownable {
    constructor(address _owner) Ownable(_owner) {}

    function instantiate(bytes32 id, bytes calldata args) external returns (address[] memory, bytes32, uint256 ) {
        return super._instantiate(id, args);
    }

    function addDistribution(bytes32 id, address initializer) public onlyOwner {
        super._addDistribution(id, initializer);
    }

    function removeDistribution(bytes32 id) public onlyOwner {
        super._removeDistribution(id);
    }
}
