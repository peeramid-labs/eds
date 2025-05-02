import { expect } from "chai";
import { deployments, ethers } from "hardhat";
import {
  ERC7744,
  MockERC20,
  MockERC20__factory,
  MockMigration,
  MockMigration__factory,
  MockOwnableDistributor,
  MockOwnableDistributor__factory,
  OwnableInstaller,
  OwnableInstaller__factory,
  OwnableRepository,
  OwnableRepository__factory,
  UpgradableDistribution__factory,
  WrappedProxyInitializer__factory
} from "../../types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { constants } from "ethers";

describe("InstallerClonable", function () {
  let installer: OwnableInstaller;
  let distributor: MockOwnableDistributor;
  let migration: MockMigration;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let distributionId: string;
  let migrationId: string;
  let repository: OwnableRepository;
  let mockErc20: MockERC20;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();
    await deployments.fixture(["ERC7744"]);

    // Deploy the mock distributor
    const MockDistributorForTest = (await ethers.getContractFactory(
      "MockOwnableDistributor"
    )) as MockOwnableDistributor__factory;
    distributor = await MockDistributorForTest.deploy(owner.address);
    await distributor.deployed();

    // Deploy the mock installer
    const MockInstaller = (await ethers.getContractFactory(
      "OwnableInstaller"
    )) as OwnableInstaller__factory;
    installer = await MockInstaller.deploy(owner.address, owner.address);
    await installer.deployed();
    // await installer.initialize(distributor.address);

    // Deploy mock migration
    const MockMigration = (await ethers.getContractFactory(
      "MockMigration"
    )) as MockMigration__factory;
    migration = await MockMigration.deploy();
    await migration.deployed();

    const Repository = (await ethers.getContractFactory(
      "OwnableRepository"
    )) as OwnableRepository__factory;
    repository = await Repository.deploy(
      owner.address,
      ethers.utils.formatBytes32String("test"),
      "0x"
    );
    await repository.deployed();

    const WrappedProxyInitializer = (await ethers.getContractFactory(
      "WrappedProxyInitializer"
    )) as WrappedProxyInitializer__factory;
    const initializer = await WrappedProxyInitializer.deploy();
    await initializer.deployed();

    const MockDistributor = (await ethers.getContractFactory(
      "UpgradableDistribution"
    )) as UpgradableDistribution__factory;
    const MockERC20 = (await ethers.getContractFactory("MockERC20")) as MockERC20__factory;
    mockErc20 = await MockERC20.deploy("Test", "TEST", ethers.utils.parseEther("1000"));
    await mockErc20.deployed();

    const codeIndexArtifact = await deployments.get("ERC7744");
    const codeIndex = new ethers.Contract(
      codeIndexArtifact.address,
      codeIndexArtifact.abi,
      owner
    ) as ERC7744;
    await codeIndex.register(mockErc20.address);
    const codeHash = ethers.utils.keccak256(await ethers.provider.getCode(mockErc20.address));

    const distr1 = await MockDistributor.deploy(
      codeHash,
      ethers.utils.formatBytes32String("TestDistribution"),
      "name",
      1
    );
    await distr1.deployed();
    const distr1CodeHash = ethers.utils.keccak256(await ethers.provider.getCode(distr1.address));
    await codeIndex.register(distr1.address);

    const distr2 = await MockDistributor.deploy(
      codeHash,
      ethers.utils.formatBytes32String("TestDistribution2"),
      "name2",
      1
    );
    await distr2.deployed();
    const distr2CodeHash = ethers.utils.keccak256(await ethers.provider.getCode(distr2.address));
    await codeIndex.register(distr2.address);

    // release the distribution
    await repository.connect(owner).newRelease(
      distr1CodeHash,
      ethers.utils.formatBytes32String("TestDistribution"),
      {
        major: 0,
        minor: 1,
        patch: 0
      },
      constants.HashZero
    );

    await distributor["addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"](
      repository.address,
      initializer.address,
      {
        version: {
          major: 0,
          minor: 1,
          patch: 0
        },
        requirement: 4
      },
      "TestDistribution"
    );
    distributionId = await distributor.getIdFromAlias("TestDistribution");

    // Install an app for testing
    await installer.connect(owner).install(distributor.address, distributionId, "0x");

    // release the distribution
    await repository.connect(owner).newRelease(
      distr2CodeHash,
      ethers.utils.formatBytes32String("TestDistribution2"),
      {
        major: 0,
        minor: 2,
        patch: 0
      },
      constants.HashZero
    );
    const migrationCodeHash = ethers.utils.keccak256(
      await ethers.provider.getCode(migration.address)
    );
    await codeIndex.register(migration.address);
    await distributor.addVersionMigration(
      distributionId,
      {
        version: {
          major: 0,
          minor: 1,
          patch: 0
        },
        requirement: 4
      },
      {
        version: {
          major: 0,
          minor: 2,
          patch: 0
        },
        requirement: 4
      },
      migrationCodeHash,
      1,
      ethers.utils.formatBytes32String("TestDistribution2")
    );
    migrationId = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "bytes32", "uint8"],
        [distributionId, migrationCodeHash, 1]
      )
    );
  });

  describe("upgradeApp", function () {
    it("should upgrade an app successfully", async function () {
      // Set up the distributor to not revert on upgrade
      //   await distributor.setUpgradeUserInstanceRevertState(false);

      // Call upgradeApp
      const appId = 1; // First installed app
      const userCalldata = "0x1234";

      // Should emit AppUpgraded event
      await expect(installer.connect(owner).upgradeApp(appId, migrationId, userCalldata)).to.emit(
        installer,
        "AppUpgraded"
      );

      const appVersion = await distributor.appVersions(appId);
      expect(appVersion.major).to.equal(ethers.BigNumber.from("0"));
      expect(appVersion.minor).to.equal(ethers.BigNumber.from("2"));
      expect(appVersion.patch).to.equal(ethers.BigNumber.from("0"));
    });

    it("should revert when app is not installed", async function () {
      const nonExistentAppId = 999;
      const userCalldata = "0x1234";

      // Should revert with proper message
      await expect(
        installer.connect(owner).upgradeApp(nonExistentAppId, migrationId, userCalldata)
      ).to.be.revertedWith("App not installed");
    });

    it("should revert when caller is not the owner", async function () {
      const appId = 1;
      const userCalldata = "0x1234";

      // Should revert when not called by owner
      await expect(
        installer.connect(user).upgradeApp(appId, migrationId, userCalldata)
      ).to.be.revertedWithCustomError(installer, "OwnableUnauthorizedAccount");
    });

    it("should properly forward migration data to the distributor", async function () {
      // Set up the distributor to not revert on upgrade
      await distributor.setUpgradeUserInstanceRevertState(false);

      const appId = 1;
      const userCalldata = "0xabcdef";

      // Upgrade the app
      await installer.connect(owner).upgradeApp(appId, migrationId, userCalldata);

      // Check that distributor was called with correct parameters
      const lastCallData = await distributor.getLastUpgradeUserInstanceCall();
      expect(lastCallData.appId).to.equal(appId);
      expect(lastCallData.migrationId).to.equal(migrationId);
      expect(lastCallData.userCalldata).to.equal(userCalldata);
    });
  });
});
