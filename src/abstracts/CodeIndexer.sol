// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/ICodeIndex.sol";

abstract contract CodeIndexer {
    //Create2 contract
    ICodeIndex constant indexContract = ICodeIndex(0xC0d31dB079b9eb23f6942A44c29F1ece9e118C30);

    constructor() {}

    function getContractsIndex() internal pure returns (ICodeIndex) {
        return indexContract;
    }

    function index(address source) internal {
        indexContract.register(source);
    }
}
