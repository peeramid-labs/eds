// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract MockDiamondInitialize {
    event MockInit(string testData);

    function init(bytes calldata data) public {
        emit MockInit(string(data));
    }
}
