// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IDistribution.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract CloneDistribution is IDistribution {
    error CodeNotFoundInIndex(bytes32 codeId);

    function sources() internal view virtual returns (address[] memory, bytes32 name, uint256 version);

    // @inheritdoc IDistribution
    function _instantiate()
        internal
        virtual
        returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion)
    {
        (address[] memory _sources, bytes32 _distributionName, uint256 _distributionVersion) = sources();
        uint256 srcsLength = _sources.length;
        instances = new address[](srcsLength);
        for (uint256 i; i < srcsLength; ++i) {
            address clone = Clones.clone(_sources[i]);
            instances[i] = clone;
        }
        emit Distributed(msg.sender, instances);
        return (instances, _distributionName, _distributionVersion);
    }
    // @inheritdoc IDistribution
    function get() external view virtual returns (address[] memory src, bytes32 name, uint256 version) {
        return sources();
    }
    // @inheritdoc IDistribution
    function contractURI() external view virtual returns (string memory);

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IDistribution).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
