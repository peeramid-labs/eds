import { expect } from "chai";
import { ethers, deployments } from "hardhat";
import {
  MockERC20,
  MockERC20__factory,
  MockTokenizedDistributor,
  MockTokenizedDistributor__factory,
  ERC7744,
  MockCloneDistribution__factory
} from "../../types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("TokenizedDistributor", function () {
  let mockToken: MockERC20;
  let distributor: MockTokenizedDistributor;
  let codeIndex: ERC7744;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let distributionId: any;
  let distributorsId: any;
  const defaultCost = ethers.utils.parseEther("1");

  before(async function () {
    await deployments.fixture("ERC7744"); // This is the key addition
    const ERC7744 = await ethers.getContractFactory("ERC7744");
    [deployer, owner] = await ethers.getSigners();
    const codeIndexDeployment = await deployments.get("ERC7744");
    codeIndex = new ethers.Contract(codeIndexDeployment.address, ERC7744.interface).connect(
      deployer
    ) as ERC7744;
    [owner, addr1] = await ethers.getSigners();
    const CloneDistribution = (await ethers.getContractFactory(
      "MockCloneDistribution"
    )) as MockCloneDistribution__factory;
    const cloneDistribution = await CloneDistribution.deploy();
    await cloneDistribution.deployed();
    const code = await cloneDistribution.provider.getCode(cloneDistribution.address);
    distributionId = ethers.utils.keccak256(code);
    await codeIndex.register(cloneDistribution.address);
  });

  beforeEach(async function () {
    const MockERC20 = (await ethers.getContractFactory("MockERC20", owner)) as MockERC20__factory;
    mockToken = await MockERC20.deploy("Mock Token", "MTK", ethers.utils.parseEther("1000"));
    const MockTokenizedDistributor = (await ethers.getContractFactory(
      "MockTokenizedDistributor"
    )) as MockTokenizedDistributor__factory;
    distributor = await MockTokenizedDistributor.deploy(
      owner.address,
      mockToken.address,
      defaultCost
    ).then((d) => d.connect(owner));
    distributorsId = await distributor["calculateDistributorId(bytes32,address)"](
      distributionId,
      addr1.address
    );
  });

  it("should set the correct default instantiation cost", async function () {
    expect(await distributor.defaultInstantiationCost()).to.equal(defaultCost);
  });

  it("should set the correct payment token", async function () {
    expect(await distributor.paymentToken()).to.equal(mockToken.address);
  });

  it("should allow admin to add a distribution", async function () {
    await expect(
      distributor["addDistribution(bytes32,address)"](distributionId, addr1.address)
    ).to.emit(distributor, "InstantiationCostChanged");
    expect(await distributor.instantiationCosts(distributorsId)).to.equal(defaultCost);
  });

  it("should allow admin to set instantiation cost", async function () {
    const newCost = ethers.utils.parseEther("2");
    await distributor.setInstantiationCost(distributorsId, newCost);
    expect(await distributor.instantiationCosts(distributorsId)).to.equal(newCost);
  });

  it("should fail to instantiate without sufficient payment", async function () {
    await distributor["addDistribution(bytes32,address)"](distributionId, addr1.address);
    await mockToken.connect(addr1).approve(distributor.address, defaultCost);
    await mockToken.connect(addr1).approve(owner.address, defaultCost);
    await expect(distributor.connect(addr1).instantiate(distributorsId, [])).to.be.reverted;
  });

  it("should instantiate with sufficient payment", async function () {
    await distributor["addDistribution(bytes32,address)"](distributionId, addr1.address);
    await mockToken.connect(owner).transfer(addr1.address, defaultCost);
    await mockToken.connect(addr1).approve(distributor.address, defaultCost);
    await expect(distributor.connect(addr1).instantiate(distributorsId, [])).to.emit(
      distributor,
      "Instantiated"
    );
  });

  it("should support the correct interfaces", async function () {
    expect(await distributor.supportsInterface("0x01ffc9a7")).to.be.true; // ERC165
    expect(await distributor.supportsInterface("0x7965db0b")).to.be.true; // AccessControl
  });
});
