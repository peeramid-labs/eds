// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ShortStrings, ShortString} from "@openzeppelin/contracts/utils/ShortStrings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IDistribution.sol";

contract MockDistribution is IDistribution, ERC165 {
    ShortString private immutable distributionName;
    uint256 private constant distributionVersion = 1;

    constructor() {
        distributionName = ShortStrings.toShortString("MockDistribution");
    }

    function contractURI() external pure override returns (string memory) {
        return "MockDistribution";
    }

    function instantiate(bytes memory) external override returns (address[] memory, bytes32, uint256) {
        address[] memory instances = new address[](1);
        instances[0] = address(this);

        // Emit the required event
        emit Distributed(msg.sender, instances);

        return (instances, ShortString.unwrap(distributionName), distributionVersion);
    }

    function get() external view override returns (address[] memory, bytes32, uint256) {
        address[] memory sources = new address[](1);
        sources[0] = address(this);
        return (sources, ShortString.unwrap(distributionName), distributionVersion);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IDistribution).interfaceId || super.supportsInterface(interfaceId);
    }
}
