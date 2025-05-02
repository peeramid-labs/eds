import { ethers, deployments } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ERC7744 } from "../../types";

// Fix for LibSemver import
interface VersionStruct {
  major: number;
  minor: number;
  patch: number;
}

interface VersionRequirementStruct {
  version: VersionStruct;
  requirement: number;
}

describe("TokenizedDistributor & OwnableTokenizedDistributor", function () {
  // Constants
  const DEFAULT_COST = ethers.utils.parseEther("10");
  const SPECIFIC_COST = ethers.utils.parseEther("5");
  const DISTRIBUTION_NAME = "TestDistribution";
  const VERSION_1_0_0: VersionStruct = { major: 1, minor: 0, patch: 0 };
  const VERSION_REQ_1_0_0: VersionRequirementStruct = {
    version: VERSION_1_0_0,
    requirement: 0
  }; // EXACT

  // Fixture definition
  async function deployTokenizedDistributorFixture() {
    // First deploy ERC7744 fixture - this is the key addition
    await deployments.fixture("ERC7744");

    const [owner, beneficiary, user1, user2] = await ethers.getSigners();

    // Get the deployed codeIndex contract
    const ERC7744Factory = await ethers.getContractFactory("ERC7744");
    const codeIndexDeployment = await deployments.get("ERC7744");
    const codeIndex = new ethers.Contract(
      codeIndexDeployment.address,
      ERC7744Factory.interface
    ).connect(owner) as ERC7744;

    // Deploy Mock ERC20 Token
    const mockERC20Factory = await ethers.getContractFactory("MockERC20");
    const paymentToken = await mockERC20Factory.deploy(
      "MockToken",
      "MTK",
      ethers.utils.parseEther("1000000")
    );
    await paymentToken.deployed();

    // Distribute tokens to users
    await paymentToken.transfer(user1.address, ethers.utils.parseEther("1000"));
    await paymentToken.transfer(user2.address, ethers.utils.parseEther("100"));

    // Deploy OwnableTokenizedDistributor
    const OwnableTokenizedDistributorFactory = await ethers.getContractFactory(
      "OwnableTokenizedDistributor"
    );
    const distributor = await OwnableTokenizedDistributorFactory.deploy(
      owner.address,
      paymentToken.address,
      DEFAULT_COST,
      beneficiary.address
    );
    await distributor.deployed();

    // Deploy Mock Clone Distribution
    const mockCloneDistributionFactory = await ethers.getContractFactory("MockCloneDistribution");
    const mockCloneDistribution = await mockCloneDistributionFactory.deploy("TestClone");
    await mockCloneDistribution.deployed();

    // Get the code hash for the distribution
    const distributionCode = await ethers.provider.getCode(mockCloneDistribution.address);
    const distributionHash = ethers.utils.keccak256(distributionCode);

    // Register with codeIndex - this is crucial
    await codeIndex.register(mockCloneDistribution.address);

    // Deploy Mock Repository
    const mockRepositoryFactory = await ethers.getContractFactory("MockRepository");
    const mockRepository = await mockRepositoryFactory.deploy();
    await mockRepository.deployed();

    // Register repository with codeIndex as well
    await codeIndex.register(mockRepository.address);

    // Add versioned distribution code to the repository
    // This is needed for versioned distributions to work properly
    const versionedDistributionCode = await ethers.provider.getCode(mockCloneDistribution.address);
    const versionedDistributionHash = ethers.utils.keccak256(versionedDistributionCode);

    // Register version 1.0.0 in the repository
    await mockRepository.newRelease(
      versionedDistributionHash,
      ethers.utils.toUtf8Bytes("v1 metadata"),
      { major: 1, minor: 0, patch: 0 },
      ethers.constants.HashZero // No migration script needed
    );

    // Add distributions to the Distributor - using the specific function signature for bytes32
    await distributor
      .connect(owner)
      [
        "addDistribution(bytes32,address,string)"
      ](distributionHash, ethers.constants.AddressZero, DISTRIBUTION_NAME + "_unversioned");

    // Get unversioned distribution ID
    const unversionedDistId = await distributor.getIdFromAlias(DISTRIBUTION_NAME + "_unversioned");

    // Add versioned distribution - using specific function signature for IRepository
    await distributor
      .connect(owner)
      [
        "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
      ](mockRepository.address, ethers.constants.AddressZero, VERSION_REQ_1_0_0, DISTRIBUTION_NAME + "_versioned");

    // Get versioned distribution ID
    const versionedDistId = await distributor.getIdFromAlias(DISTRIBUTION_NAME + "_versioned");

    return {
      owner,
      beneficiary,
      user1,
      user2,
      paymentToken,
      distributor,
      mockCloneDistribution,
      mockRepository,
      unversionedDistId,
      versionedDistId,
      codeIndex
    };
  }

  describe("Deployment & Initialization", function () {
    it("Should set the correct owner", async function () {
      const { distributor, owner } = await loadFixture(deployTokenizedDistributorFixture);
      expect(await distributor.owner()).to.equal(owner.address);
    });

    it("Should set the correct payment token", async function () {
      const { distributor, paymentToken } = await loadFixture(deployTokenizedDistributorFixture);
      expect(await distributor.paymentToken()).to.equal(paymentToken.address);
    });

    it("Should set the correct default instantiation cost", async function () {
      const { distributor } = await loadFixture(deployTokenizedDistributorFixture);
      expect(await distributor.defaultInstantiationCost()).to.equal(DEFAULT_COST);
    });

    it("Should set the correct beneficiary", async function () {
      const { distributor, beneficiary } = await loadFixture(deployTokenizedDistributorFixture);
      expect(await distributor.beneficiary()).to.equal(beneficiary.address);
    });
  });

  describe("Instantiation Cost Management (Ownable)", function () {
    it("Should allow owner to set specific instantiation cost", async function () {
      const { distributor, owner, unversionedDistId } = await loadFixture(
        deployTokenizedDistributorFixture
      );
      await expect(
        distributor.connect(owner).setInstantiationCost(unversionedDistId, SPECIFIC_COST)
      )
        .to.emit(distributor, "InstantiationCostChanged")
        .withArgs(unversionedDistId, SPECIFIC_COST);
      expect(await distributor.instantiationCosts(unversionedDistId)).to.equal(SPECIFIC_COST);
    });

    it("Should revert if non-owner tries to set instantiation cost", async function () {
      const { distributor, user1, unversionedDistId } = await loadFixture(
        deployTokenizedDistributorFixture
      );
      await expect(
        distributor.connect(user1).setInstantiationCost(unversionedDistId, SPECIFIC_COST)
      ).to.be.revertedWithCustomError(distributor, "OwnableUnauthorizedAccount");
    });

    it("Should use default cost if specific cost not set", async function () {
      const { distributor, unversionedDistId } = await loadFixture(
        deployTokenizedDistributorFixture
      );
      // Cost is set to default upon adding the distribution
      expect(await distributor.instantiationCosts(unversionedDistId)).to.equal(DEFAULT_COST);
    });
  });

  describe("Beneficiary Management (Ownable)", function () {
    it("Should allow owner to set a new beneficiary", async function () {
      const { distributor, owner, user2 } = await loadFixture(deployTokenizedDistributorFixture);
      await expect(distributor.connect(owner).setBeneficiary(user2.address)).to.not.be.reverted;
      expect(await distributor.beneficiary()).to.equal(user2.address);
    });

    it("Should revert if non-owner tries to set beneficiary", async function () {
      const { distributor, user1, user2 } = await loadFixture(deployTokenizedDistributorFixture);
      await expect(
        distributor.connect(user1).setBeneficiary(user2.address)
      ).to.be.revertedWithCustomError(distributor, "OwnableUnauthorizedAccount");
    });
  });

  describe("Instantiation Payment", function () {
    it("Should instantiate and transfer tokens (default cost)", async function () {
      const { distributor, user1, beneficiary, paymentToken, unversionedDistId } =
        await loadFixture(deployTokenizedDistributorFixture);
      const initialUserBalance = await paymentToken.balanceOf(user1.address);
      const initialBeneficiaryBalance = await paymentToken.balanceOf(beneficiary.address);

      // User approves distributor to spend tokens
      await paymentToken.connect(user1).approve(distributor.address, DEFAULT_COST);

      await expect(distributor.connect(user1).instantiate(unversionedDistId, "0x")).to.emit(
        distributor,
        "Instantiated"
      );

      // Check balances
      expect(await paymentToken.balanceOf(user1.address)).to.equal(
        initialUserBalance.sub(DEFAULT_COST)
      );
      expect(await paymentToken.balanceOf(beneficiary.address)).to.equal(
        initialBeneficiaryBalance.add(DEFAULT_COST)
      );
    });

    it("Should instantiate and transfer tokens (specific cost)", async function () {
      const { distributor, owner, user1, beneficiary, paymentToken, unversionedDistId } =
        await loadFixture(deployTokenizedDistributorFixture);
      // Set specific cost
      await distributor.connect(owner).setInstantiationCost(unversionedDistId, SPECIFIC_COST);

      const initialUserBalance = await paymentToken.balanceOf(user1.address);
      const initialBeneficiaryBalance = await paymentToken.balanceOf(beneficiary.address);

      // User approves distributor
      await paymentToken.connect(user1).approve(distributor.address, SPECIFIC_COST);

      await expect(distributor.connect(user1).instantiate(unversionedDistId, "0x")).to.emit(
        distributor,
        "Instantiated"
      );

      // Check balances
      expect(await paymentToken.balanceOf(user1.address)).to.equal(
        initialUserBalance.sub(SPECIFIC_COST)
      );
      expect(await paymentToken.balanceOf(beneficiary.address)).to.equal(
        initialBeneficiaryBalance.add(SPECIFIC_COST)
      );
    });

    it("Should instantiate versioned distribution and transfer tokens", async function () {
      const { distributor, user1, beneficiary, paymentToken, versionedDistId } = await loadFixture(
        deployTokenizedDistributorFixture
      );
      const initialUserBalance = await paymentToken.balanceOf(user1.address);
      const initialBeneficiaryBalance = await paymentToken.balanceOf(beneficiary.address);

      // User approves distributor to spend tokens (default cost applies here too)
      await paymentToken.connect(user1).approve(distributor.address, DEFAULT_COST);

      await expect(distributor.connect(user1).instantiate(versionedDistId, "0x")).to.emit(
        distributor,
        "Instantiated"
      );

      // Check balances
      expect(await paymentToken.balanceOf(user1.address)).to.equal(
        initialUserBalance.sub(DEFAULT_COST)
      );
      expect(await paymentToken.balanceOf(beneficiary.address)).to.equal(
        initialBeneficiaryBalance.add(DEFAULT_COST)
      );
    });

    it("Should revert if user has insufficient balance", async function () {
      const { distributor, user2, paymentToken, unversionedDistId } = await loadFixture(
        deployTokenizedDistributorFixture
      );
      // Transfer most of user2's tokens away to leave insufficient balance
      const balance = await paymentToken.balanceOf(user2.address);

      // Use a non-zero address instead of address(0) to avoid the ERC20InvalidReceiver error
      const dummyRecipient = "0x0000000000000000000000000000000000000001";

      await paymentToken
        .connect(user2)
        .transfer(dummyRecipient, balance.sub(ethers.utils.parseEther("1")));

      // Approve more than the balance
      await paymentToken.connect(user2).approve(distributor.address, DEFAULT_COST);

      // Should revert due to insufficient balance
      await expect(
        distributor.connect(user2).instantiate(unversionedDistId, "0x")
      ).to.be.revertedWithCustomError(paymentToken, "ERC20InsufficientBalance");
    });

    it("Should revert if user has not approved enough tokens", async function () {
      const { distributor, user1, paymentToken, unversionedDistId } = await loadFixture(
        deployTokenizedDistributorFixture
      );
      // User approves less than required
      await paymentToken.connect(user1).approve(distributor.address, DEFAULT_COST.sub(1));

      await expect(
        distributor.connect(user1).instantiate(unversionedDistId, "0x")
      ).to.be.revertedWithCustomError(paymentToken, "ERC20InsufficientAllowance");
    });

    it("Should revert if trying to instantiate non-existent distribution", async function () {
      const { distributor, user1, paymentToken } = await loadFixture(
        deployTokenizedDistributorFixture
      );
      const fakeDistId = ethers.utils.formatBytes32String("fake");
      await paymentToken.connect(user1).approve(distributor.address, DEFAULT_COST);
      await expect(
        distributor.connect(user1).instantiate(fakeDistId, "0x")
      ).to.be.revertedWithCustomError(distributor, "DistributionNotFound");
    });
  });

  describe("Adding Distributions", function () {
    it("Should set default instantiation cost when adding unversioned distribution", async function () {
      const { distributor, unversionedDistId } = await loadFixture(
        deployTokenizedDistributorFixture
      );
      // Cost was already set during fixture setup's addDistribution call
      expect(await distributor.instantiationCosts(unversionedDistId)).to.equal(DEFAULT_COST);
    });

    it("Should set default instantiation cost when adding versioned distribution", async function () {
      const { distributor, versionedDistId } = await loadFixture(deployTokenizedDistributorFixture);
      // Cost was already set during fixture setup's addDistribution call
      expect(await distributor.instantiationCosts(versionedDistId)).to.equal(DEFAULT_COST);
    });
  });
});
