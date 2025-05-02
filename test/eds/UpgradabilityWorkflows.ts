import { ethers } from "hardhat";
import { expect } from "chai";
import {
  ERC7744,
  OwnableDistributor,
  OwnableDistributor__factory,
  MockInstaller__factory,
  UpgradableDistribution__factory,
  MockMigration__factory,
  MockERC20__factory,
  OwnableRepository__factory,
  OwnableRepository,
  MockInstaller,
  MockInitializer,
  WrappedProxyInitializer,
  WrappedProxyInitializer__factory
} from "../../types";
import { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("Upgradability Workflows", function () {
  let codeIndex: ERC7744;
  let distributor: OwnableDistributor;
  let repository: OwnableRepository;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let erc20CodeHash: string;
  let mockMigration: any;
  let UpgradableDistribution: any;
  let UpgradableDistributionId: string;
  let distributionId: string;
  let installer: MockInstaller;
  let mockERC20Instance: any;
  let initializer: WrappedProxyInitializer;
  let migrationHash: string;

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

  // Helper function to create versions
  function createVersion(major: number, minor: number, patch: number) {
    return {
      major,
      minor,
      patch
    };
  }

  beforeEach(async function () {
    await deployments.fixture("ERC7744");
    const ERC7744 = await ethers.getContractFactory("ERC7744");
    [deployer, owner, user] = await ethers.getSigners();

    // Setup code index
    const codeIndexDeployment = await deployments.get("ERC7744");
    codeIndex = new ethers.Contract(codeIndexDeployment.address, ERC7744.interface).connect(
      deployer
    ) as ERC7744;

    // Deploy distributor (security oracle)
    const Distributor = (await ethers.getContractFactory(
      "OwnableDistributor"
    )) as OwnableDistributor__factory;
    distributor = await Distributor.deploy(owner.address);
    await distributor.deployed();

    // Deploy repository for versioned distributions
    const OwnableRepositoryFactory = (await ethers.getContractFactory(
      "OwnableRepository"
    )) as OwnableRepository__factory;
    repository = await OwnableRepositoryFactory.deploy(
      owner.address,
      ethers.utils.formatBytes32String("MockRepository"),
      "0x"
    );
    await repository.deployed();

    // Deploy wrapped proxy initializer
    const WrappedProxyInitializerFactory = (await ethers.getContractFactory(
      "WrappedProxyInitializer"
    )) as WrappedProxyInitializer__factory;
    initializer = await WrappedProxyInitializerFactory.deploy();
    await initializer.deployed();

    // Deploy mock installer (user infrastructure)
    const MockInstallerFactory = (await ethers.getContractFactory(
      "MockInstaller"
    )) as MockInstaller__factory;
    installer = await MockInstallerFactory.deploy(user.address, user.address);
    await installer.deployed();

    // Deploy mock ERC20 for code hash
    const MockERC20 = (await ethers.getContractFactory("MockERC20")) as MockERC20__factory;
    mockERC20Instance = await MockERC20.deploy("TokenA", "TKA", ethers.utils.parseEther("1000"));
    await mockERC20Instance.deployed();

    // Register ERC20 code
    const codeErc20 = await mockERC20Instance.provider.getCode(mockERC20Instance.address);
    erc20CodeHash = ethers.utils.keccak256(codeErc20);
    await codeIndex.register(mockERC20Instance.address);

    // Deploy mock migration contract
    const MockMigrationFactory = (await ethers.getContractFactory(
      "MockMigration"
    )) as MockMigration__factory;
    mockMigration = await MockMigrationFactory.deploy();
    await mockMigration.deployed();

    // Get migration hash
    const migrationCode = await mockMigration.provider.getCode(mockMigration.address);
    migrationHash = ethers.utils.keccak256(migrationCode);
    await codeIndex.register(mockMigration.address);

    // Register version 1.0.0 in the repository
    await repository.connect(owner).newRelease(
      erc20CodeHash,
      "0x", // metadata
      createVersion(1, 0, 0),
      migrationHash
    );

    // Deploy UpgradableDistribution
    const UpgradableDistributionFactory = (await ethers.getContractFactory(
      "UpgradableDistribution"
    )) as UpgradableDistribution__factory;
    UpgradableDistribution = await UpgradableDistributionFactory.deploy(
      erc20CodeHash,
      ethers.utils.formatBytes32String("metadata"),
      "TestDistribution",
      1 // version
    );
    await UpgradableDistribution.deployed();

    // Get version distribution code hash and register
    const code = await UpgradableDistribution.provider.getCode(UpgradableDistribution.address);
    UpgradableDistributionId = ethers.utils.keccak256(code);
    await codeIndex.register(UpgradableDistribution.address);

    // Whitelist the distributor in the installer
    await installer.connect(user).whitelistDistributor(distributor.address);
  });

  describe("Installer Workflow", function () {
    it("should install an app through the installer", async function () {
      // Register the distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](UpgradableDistributionId, initializer.address, "InstallerTest");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("InstallerTest");

      // Allow this distribution in the installer

      // Install the app
      const installTx = await installer
        .connect(user)
        .install(distributor.address, distributionId, "0x");

      // Check if we can get the installed app
      const appComponents = await installer.getApp(1);
      expect(appComponents.length).to.be.gt(0);
    });

    it("should uninstall an app through the installer", async function () {
      // Register the distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](UpgradableDistributionId, initializer.address, "UninstallTest");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("UninstallTest");

      // Allow this distribution in the installer

      // Install the app
      await installer.connect(user).install(distributor.address, distributionId, "0x");

      // Uninstall the app
      await installer.connect(user).uninstall(1);
      const app = await installer.getApp(1);
      // Should revert when trying to access the uninstalled app
      expect(app.contracts.length).to.be.eq(0);
    });

    it("should change distributor for an app", async function () {
      // Register the distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](UpgradableDistributionId, initializer.address, "ChangeTest");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("ChangeTest");

      // Allow this distribution in the installer

      // Install the app
      await installer.connect(user).install(distributor.address, distributionId, "0x");
      const appComponents = await installer.getApp(1);

      // Change the distributor
      await expect(
        installer.connect(user).changeDistributor(1, ethers.constants.AddressZero, [])
      ).to.emit(distributor, "DistributorChanged");
    });

    it("should upgrade an app through the installer", async function () {
      // Register version 1.0.0 in the repository if not already registered
      try {
        await repository.connect(owner).newRelease(
          erc20CodeHash,
          "0x", // metadata
          createVersion(1, 0, 0),
          migrationHash
        );
      } catch (e) {
        // Version might already exist, ignore error
      }

      // Register the distribution with version 1.0.0 using the repository
      await distributor
        .connect(owner)
        ["addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"](
          repository.address,
          initializer.address,
          createVersionRequirement(1, 0, 0, 0), // 0 = GTE (greater than or equal)
          "TestDistribution"
        );

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("TestDistribution");

      // Install the app
      const installData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address,bytes)"],
        [[installer.address, "0x"]]
      );

      await installer.connect(user).install(distributor.address, distributionId, installData);
      const appComponents = await installer.getApp(1);
      const appId = 1;

      // Register a new version 2.0.0 in the repository
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(2, 0, 0),
        migrationHash
      );

      // Create version requirements for migration
      const fromVersion = createVersionRequirement(1, 0, 0, 0); // from v1.0.0
      const toVersion = createVersionRequirement(2, 0, 0, 0); // to v2.0.0

      // Add the version migration to the distributor
      await distributor.connect(owner).addVersionMigration(
        distributionId,
        fromVersion,
        toVersion,
        migrationHash,
        0, // MigrationStrategy.Direct (CALL)
        "0x" // No distributor calldata needed for this test
      );

      // Calculate migration ID
      const migrationId = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "bytes32", "uint8"],
          [distributionId, migrationHash, 0]
        )
      );

      // Upgrade the app
      const userCalldata = "0x123456"; // Example user calldata for migration

      // Get transaction and receipt
      const tx = await installer.connect(user).upgradeApp(appId, migrationId, userCalldata);
      const receipt = await tx.wait();

      // Check for AppUpgraded event from installer
      const upgradeEvent = receipt.events?.find(
        (e: any) =>
          e.address === installer.address &&
          e.topics[0] === ethers.utils.id("AppUpgraded(uint256,bytes32,uint256,bytes)")
      );
      expect(upgradeEvent).to.not.be.undefined;

      // Find the MigrationExecuted event from the mock migration
      const migrationEvent = receipt.events?.find(
        (e: any) =>
          e.address === mockMigration.address &&
          e.topics[0] ===
            ethers.utils.id("MigrationExecuted(address[],uint256,uint256,bytes,bytes)")
      );
      expect(migrationEvent).to.not.be.undefined;
    });

    it("should revert when trying to upgrade a non-existent app", async function () {
      // Try to upgrade a non-existent app (ID 999)
      const nonExistentAppId = 999;
      const userCalldata = "0x123456";

      // Should revert with "App not installed"
      await expect(
        installer.connect(user).upgradeApp(nonExistentAppId, migrationHash, userCalldata)
      ).to.be.revertedWith("App not installed");
    });
  });

  describe("Distributor Control", function () {
    it("should allow and disallow distributions", async function () {
      // Register the distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](UpgradableDistributionId, initializer.address, "AllowTest");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("AllowTest");

      // Allow this distribution in the installer

      // Should be able to install
      await installer.connect(deployer).install(distributor.address, distributionId, "0x");

      // remove whitelisted distributor
      await installer.connect(user).revokeWhitelistedDistributor(distributor.address);
      // Disallow the distribution
      await installer.connect(user).disallowDistribution(distributor.address, distributionId);

      // Installation should now revert
      await expect(
        installer.connect(deployer).install(distributor.address, distributionId, "0x")
      ).to.be.revertedWithCustomError(installer, "InvalidDistributor");
    });

    it("should disable a distribution", async function () {
      // Register the distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](UpgradableDistributionId, initializer.address, "DisableTest");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("DisableTest");

      // Allow this distribution in the installer

      // Should be able to install
      await installer.connect(user).install(distributor.address, distributionId, "0x");

      // Disable the distribution
      await distributor.connect(owner).disableDistribution(distributionId);

      // Installation should now revert
      await expect(
        installer.connect(user).install(distributor.address, distributionId, "0x")
      ).to.be.revertedWithCustomError(distributor, "DistributionNotFound");
    });
  });
});
