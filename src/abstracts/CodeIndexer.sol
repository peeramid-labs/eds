// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/ICodeIndex.sol";

abstract contract CodeIndexer {
    //Create2 contract
    ICodeIndex constant indexContract = ICodeIndex(0xc0d31D6A64D1BE49867158ed3c25152D240b5c0B);

    constructor() {}

    function getContractsIndex() internal pure returns (ICodeIndex) {
        return indexContract;
    }

    function index(address source) internal {
        indexContract.register(source);
    }
}
