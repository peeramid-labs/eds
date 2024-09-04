// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import "../ICodeIndex.sol";

abstract contract CodeIndexer {
    //Create2 contract
    ICodeIndex constant indexContract = ICodeIndex(0xc0D31d398c5ee86C5f8a23FA253ee8a586dA03Ce);
    constructor() {}

    function getContractsIndex() internal pure returns (ICodeIndex) {
        return indexContract;
    }

    function index(address source) internal {
        indexContract.register(source);
    }
}
