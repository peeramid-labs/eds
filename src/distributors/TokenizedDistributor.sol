// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Distributor.sol";

abstract contract TokenizedDistributor is Distributor {
    event InstantiationCostChanged(bytes32 indexed id, uint256 cost);
    IERC20 public paymentToken;
    address public _beneficiary;
    mapping(bytes32 codeHash => uint256) public instantiationCosts;
    uint256 public defaultInstantiationCost;
    constructor(IERC20 token, uint256 defaultCost, address beneficiary) Distributor() {
        paymentToken = token;
        defaultInstantiationCost = defaultCost;
        _beneficiary = beneficiary;
    }

    /**
     * @notice Sets instantiation cost on a specific instantiation id
     * @param distributorsId distributors id
     * @param cost cost of instantiation
     */
    function _setInstantiationCost(bytes32 distributorsId, uint256 cost) internal {
        instantiationCosts[distributorsId] = cost;
        emit InstantiationCostChanged(distributorsId, cost);
    }

    /**
     * @inheritdoc Distributor
     */
    function _addDistribution(
        bytes32 codeHash,
        address initializerAddress,
        string memory readableName
    ) internal override returns (bytes32 distributorsId) {
        distributorsId = super._addDistribution(codeHash, initializerAddress, readableName);
        _setInstantiationCost(distributorsId, defaultInstantiationCost);
    }

    function _addDistribution(
        address repository,
        address initializer,
        LibSemver.VersionRequirement memory requirement,
        string memory readableName
    ) internal override returns (bytes32 distributorsId) {
        distributorsId = super._addDistribution(repository, initializer, requirement, readableName);
        _setInstantiationCost(distributorsId, defaultInstantiationCost);
    }

    /**
     * @inheritdoc Distributor
     */
    function _instantiate(
        bytes32 distributorsId,
        bytes memory args
    )
        internal
        virtual
        override
        returns (address[] memory instances, bytes32 distributionName, uint256 distributionVersion)
    {
        paymentToken.transferFrom(msg.sender, _beneficiary, instantiationCosts[distributorsId]);
        return super._instantiate(distributorsId, args);
    }
}
