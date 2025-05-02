// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IDistribution.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract MockPanicDistribution is IDistribution {
    function instantiate(bytes calldata) external override returns (address[] memory, bytes32, uint256) {
        // Intentionally trigger a panic (like division by zero)
        uint256 a = 1;
        uint256 b = 0;
        uint256 c = a / b; // This will cause a panic

        // This code is unreachable
        address[] memory instances = new address[](1);
        instances[0] = address(this);
        emit Distributed(msg.sender, instances);
        return (instances, bytes32("MockPanicDistribution"), 1);
    }

    function contractURI() external pure override returns (string memory) {
        return "ipfs://mockPanicDistribution";
    }

    function get() external view override returns (address[] memory, bytes32, uint256) {
        address[] memory sources = new address[](1);
        sources[0] = address(this);
        return (sources, bytes32("MockPanicDistribution"), 1);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IDistribution).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
