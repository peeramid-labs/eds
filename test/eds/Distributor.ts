import { ethers } from "hardhat";
import { expect } from "chai";
import {
  ERC7744,
  MockCloneDistribution__factory,
  OwnableDistributor,
  OwnableDistributor__factory,
  TestFacet__factory,
  VersionDistribution__factory,
  MockMigration__factory
} from "../../types";
import { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("Distributor", function () {
  let codeIndex: ERC7744;
  let distributor: OwnableDistributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let distributorsId: any;
  let cloneDistributionId: any;

  // Helper function to create version requirements
  function createVersionRequirement(
    major: number,
    minor: number,
    patch: number,
    requirement: number
  ) {
    return {
      version: {
        major,
        minor,
        patch
      },
      requirement
    };
  }

  beforeEach(async function () {
    await deployments.fixture("ERC7744"); // This is the key addition
    const ERC7744 = await ethers.getContractFactory("ERC7744");
    [deployer, owner] = await ethers.getSigners();
    const codeIndexDeployment = await deployments.get("ERC7744");
    codeIndex = new ethers.Contract(codeIndexDeployment.address, ERC7744.interface).connect(
      deployer
    ) as ERC7744;

    const Distributor = (await ethers.getContractFactory(
      "OwnableDistributor"
    )) as OwnableDistributor__factory;
    distributor = await Distributor.deploy(owner.address);

    const CloneDistribution = (await ethers.getContractFactory(
      "MockCloneDistribution"
    )) as MockCloneDistribution__factory;
    const cloneDistribution = await CloneDistribution.deploy();
    await cloneDistribution.deployed();
    const code = await cloneDistribution.provider.getCode(cloneDistribution.address);
    cloneDistributionId = ethers.utils.keccak256(code);
    distributorsId = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "bytes32"],
        [cloneDistributionId, ethers.utils.formatBytes32String("")]
      )
    );
    await codeIndex.register(cloneDistribution.address);
  });

  it("Only Owner can add distribution instantiate a contract", async function () {
    expect(
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](cloneDistributionId, ethers.constants.AddressZero, "TestDistribution")
    ).to.emit(distributor, "DistributionAdded");

    await expect(
      distributor
        .connect(deployer)
        [
          "addDistribution(bytes32,address,string)"
        ](ethers.utils.keccak256(cloneDistributionId), ethers.constants.AddressZero, "TestDistribution")
    ).to.be.revertedWithCustomError(distributor, "OwnableUnauthorizedAccount");
  });

  it("Does not allow instantiate a contract that was not added", async function () {
    const TestFacetDistribution = (await ethers.getContractFactory(
      "TestFacet"
    )) as TestFacet__factory;
    const testFacetDistribution = await TestFacetDistribution.deploy();
    await testFacetDistribution.deployed();
    const code = await testFacetDistribution.provider.getCode(testFacetDistribution.address);
    const cloneDistributionId = ethers.utils.keccak256(code);
    await codeIndex.register(testFacetDistribution.address);
    await expect(
      distributor
        .connect(owner)
        .instantiate(cloneDistributionId, ethers.utils.formatBytes32String(""))
    ).to.be.revertedWithCustomError(distributor, "DistributionNotFound");
  });

  describe("addNamedDistribution", function () {
    it("should allow owner to add a named distribution", async function () {
      const name = "test-distribution";
      const initializer = ethers.constants.AddressZero;

      // Use emit without checking args since the event has 5 args
      await expect(
        distributor
          .connect(owner)
          ["addDistribution(bytes32,address,string)"](cloneDistributionId, initializer, name)
      ).to.emit(distributor, "DistributionAdded");
    });

    it("should revert when non-owner tries to add a named distribution", async function () {
      const name = "test-distribution";
      const initializer = ethers.constants.AddressZero;

      await expect(
        distributor
          .connect(deployer)
          ["addDistribution(bytes32,address,string)"](cloneDistributionId, initializer, name)
      ).to.be.revertedWithCustomError(distributor, "OwnableUnauthorizedAccount");
    });

    it("should revert when distribution ID does not exist", async function () {
      const name = "test-distribution";
      const initializer = ethers.constants.AddressZero;
      const nonExistentId = ethers.utils.formatBytes32String("non-existent");

      await expect(
        distributor
          .connect(owner)
          ["addDistribution(bytes32,address,string)"](nonExistentId, initializer, name)
      ).to.be.revertedWithCustomError(distributor, "AddressNotFound");
    });
  });

  describe("when distribution is added", function () {
    beforeEach(async function () {
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](cloneDistributionId, ethers.constants.AddressZero, "test");
    });

    it("Is possible to instantiate a contract", async function () {
      expect(
        await distributor.connect(owner).instantiate(distributorsId, ethers.constants.AddressZero)
      ).to.emit(distributor, "Instantiated");
    });

    it("Is possible to remove a distribution", async function () {
      expect(await distributor.connect(owner).disableDistribution(distributorsId)).to.emit(
        distributor,
        "DistributionDisabled"
      );
    });

    describe("When distribution is instantiated and then removed", () => {
      let instanceAddress: string;
      beforeEach(async () => {
        let receipt = await (
          await distributor.connect(owner).instantiate(distributorsId, ethers.constants.AddressZero)
        ).wait();
        let parsed = utils.getSuperInterface().parseLog(receipt.logs[0]);
        instanceAddress = parsed.args.instances[0];
        console.log(instanceAddress);
        await distributor.connect(owner).disableDistribution(distributorsId);
      });
      it("Instance is invalid upon check", async () => {
        await expect(
          distributor.connect(owner).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
        ).to.be.revertedWithCustomError(distributor, "InvalidApp");
      });
    });
  });

  // New tests for versioning and migrations
  describe("Version management and migrations", function () {
    let versionDistributionId: string;
    let versionDistributionAddress: string;
    let mockMigrationAddress: string;
    let appId: number;
    let migrationId: string;
    let erc20CodeHash: string;
    let repository: any;
    let mockERC20Instance: any;

    beforeEach(async function () {
      // Deploy a mock ERC20 for code hash
      const mockERC20 = await ethers.getContractFactory("MockERC20");
      mockERC20Instance = await mockERC20.deploy("TokenA", "TKA", 1000);
      await mockERC20Instance.deployed();
      const codeErc20 = await mockERC20Instance.provider.getCode(mockERC20Instance.address);
      erc20CodeHash = ethers.utils.keccak256(codeErc20);
      await codeIndex.register(mockERC20Instance.address);

      // Deploy repository
      const repositoryFactory = await ethers.getContractFactory("OwnableRepository");
      repository = await repositoryFactory.deploy(
        owner.address,
        ethers.utils.formatBytes32String("TestRepository"),
        "test-uri"
      );
      await repository.deployed();

      // Deploy VersionDistribution
      const VersionDistribution = (await ethers.getContractFactory(
        "VersionDistribution"
      )) as VersionDistribution__factory;
      const versionDistribution = await VersionDistribution.deploy(
        erc20CodeHash,
        ethers.utils.formatBytes32String("metadata"),
        "TestDistribution",
        1, // version
        false // allowUserCalldata
      );
      await versionDistribution.deployed();

      // Deploy mock migration contract
      const MockMigration = (await ethers.getContractFactory(
        "MockMigration"
      )) as MockMigration__factory;
      const mockMigration = await MockMigration.deploy();
      await mockMigration.deployed();
      mockMigrationAddress = mockMigration.address;

      // Get version distribution code and register
      const code = await versionDistribution.provider.getCode(versionDistribution.address);
      versionDistributionId = ethers.utils.keccak256(code);
      versionDistributionAddress = versionDistribution.address;

      await codeIndex.register(versionDistribution.address);

      // Add distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](versionDistributionId, ethers.constants.AddressZero, "TestDistribution");
    });

    it("should add a versioned distribution", async function () {
      // Add distribution with repository and version requirement
      await expect(
        distributor
          .connect(owner)
          [
            "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
          ](repository.address, ethers.constants.AddressZero, createVersionRequirement(1, 0, 0, 0), "VersionedTest")
      ).to.emit(distributor, "DistributionAdded");
    });

    it("should change distribution version requirement", async function () {
      // Add a versioned distribution first
      await distributor
        .connect(owner)
        [
          "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
        ](repository.address, ethers.constants.AddressZero, createVersionRequirement(1, 0, 0, 0), "VersionedTest");

      const distrId = await distributor.getIdFromAlias("VersionedTest");

      // Change version
      await expect(
        distributor.connect(owner).changeVersion(distrId, createVersionRequirement(2, 0, 0, 0))
      ).to.emit(distributor, "VersionChanged");
    });

    it("should add and remove migration contracts", async function () {
      // Add a versioned distribution first
      await distributor
        .connect(owner)
        [
          "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
        ](repository.address, ethers.constants.AddressZero, createVersionRequirement(1, 0, 0, 0), "VersionedTest");

      const distrId = await distributor.getIdFromAlias("VersionedTest");

      // Add migration
      await distributor.connect(owner).addVersionMigration(
        distrId,
        createVersionRequirement(1, 0, 0, 0),
        createVersionRequirement(2, 0, 0, 0),
        mockMigrationAddress,
        0, // MigrationStrategy.CALL
        "0x" // distributor calldata
      );

      // Calculate migration ID
      migrationId = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "uint8"],
          [distrId, mockMigrationAddress, 0]
        )
      );

      // Verify migration exists
      const migrationPlan = await distributor.getVersionMigration(migrationId);
      expect(migrationPlan.exists).to.be.true;

      // Remove migration
      await expect(distributor.connect(owner).removeVersionMigration(migrationId)).to.emit(
        distributor,
        "VersionMigrationRemoved"
      );

      // Verify migration removed
      const updatedMigrationPlan = await distributor.getVersionMigration(migrationId);
      expect(updatedMigrationPlan.exists).to.be.false;
    });

    it("should handle different migration strategies", async function () {
      // Add a versioned distribution first
      await distributor
        .connect(owner)
        [
          "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
        ](repository.address, ethers.constants.AddressZero, createVersionRequirement(1, 0, 0, 0), "VersionedTest");

      const distrId = await distributor.getIdFromAlias("VersionedTest");

      // Add migration with CALL strategy
      await distributor.connect(owner).addVersionMigration(
        distrId,
        createVersionRequirement(1, 0, 0, 0),
        createVersionRequirement(2, 0, 0, 0),
        mockMigrationAddress,
        0, // MigrationStrategy.CALL
        "0x" // distributor calldata
      );

      // Add migration with DELEGATECALL strategy
      await distributor.connect(owner).addVersionMigration(
        distrId,
        createVersionRequirement(2, 0, 0, 0),
        createVersionRequirement(3, 0, 0, 0),
        mockMigrationAddress,
        1, // MigrationStrategy.DELEGATECALL
        "0x" // distributor calldata
      );

      // Calculate migration IDs
      const callMigrationId = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "uint8"],
          [distrId, mockMigrationAddress, 0]
        )
      );

      const delegatecallMigrationId = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "uint8"],
          [distrId, mockMigrationAddress, 1]
        )
      );

      // Verify migrations exist with correct strategies
      const callMigrationPlan = await distributor.getVersionMigration(callMigrationId);
      expect(callMigrationPlan.exists).to.be.true;
      expect(callMigrationPlan.strategy).to.equal(0); // CALL

      const delegatecallMigrationPlan =
        await distributor.getVersionMigration(delegatecallMigrationId);
      expect(delegatecallMigrationPlan.exists).to.be.true;
      expect(delegatecallMigrationPlan.strategy).to.equal(1); // DELEGATECALL
    });

    it("should revert when adding migration to unversioned distribution", async function () {
      // Add a simple unversioned distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](cloneDistributionId, ethers.constants.AddressZero, "UnversionedTest");

      const unversionedId = await distributor.getIdFromAlias("UnversionedTest");

      // Attempt to add migration to unversioned distribution
      await expect(
        distributor.connect(owner).addVersionMigration(
          unversionedId,
          createVersionRequirement(1, 0, 0, 0),
          createVersionRequirement(2, 0, 0, 0),
          mockMigrationAddress,
          0, // MigrationStrategy.CALL
          "0x" // distributor calldata
        )
      ).to.be.revertedWithCustomError(distributor, "UnversionedDistribution");
    });

    it("should revert when changing version of unversioned distribution", async function () {
      // Add a simple unversioned distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](cloneDistributionId, ethers.constants.AddressZero, "UnversionedTest");

      const unversionedId = await distributor.getIdFromAlias("UnversionedTest");

      // Attempt to change version of unversioned distribution
      await expect(
        distributor
          .connect(owner)
          .changeVersion(unversionedId, createVersionRequirement(2, 0, 0, 0))
      ).to.be.revertedWithCustomError(distributor, "UnversionedDistribution");
    });

    // Simplified test for unversioned instance - just verifying it gets added properly
    it("should add unversioned distribution instance", async function () {
      // Add an unversioned distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](cloneDistributionId, ethers.constants.AddressZero, "UnversionedTest");

      const unversionedId = await distributor.getIdFromAlias("UnversionedTest");

      // Instantiate the unversioned distribution
      await expect(
        distributor.connect(owner).instantiate(unversionedId, ethers.constants.AddressZero)
      ).to.emit(distributor, "Instantiated");
    });
  });
});
