import { expect } from "chai";
import { deployments, ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ERC7744,
  MockERC20__factory,
  MockMigration__factory,
  MockOwnableDistributor,
  MockOwnableDistributor__factory,
  OwnableInstaller,
  OwnableInstaller__factory,
  OwnableRepository__factory,
  UpgradableDistribution__factory,
  WrappedProxyInitializer__factory
} from "../../types";

describe("InstallerClonable Upgradeability", function () {
  let mockInstaller: OwnableInstaller;
  let mockDistributor: MockOwnableDistributor;
  let mockMigration: Contract;
  let owner: SignerWithAddress;
  let distributorId: string;
  let migrationId: string;
  let migrationHash: string;

  beforeEach(async function () {
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

    [owner] = await ethers.getSigners();
    await deployments.fixture("ERC7744");

    // Deploy mock distributor
    const MockOwnableDistributor = (await ethers.getContractFactory(
      "MockOwnableDistributor"
    )) as MockOwnableDistributor__factory;
    mockDistributor = await MockOwnableDistributor.deploy(owner.address);
    await mockDistributor.deployed();

    // Deploy installer
    const MockInstaller = (await ethers.getContractFactory(
      "OwnableInstaller"
    )) as OwnableInstaller__factory;
    mockInstaller = await MockInstaller.deploy(owner.address, owner.address);
    await mockInstaller.deployed();

    // Initialize installer with distributor
    //  await mockInstaller.initialize(mockDistributor.address);

    // Deploy mock migration
    const MockMigration = (await ethers.getContractFactory(
      "MockMigration"
    )) as MockMigration__factory;
    mockMigration = await MockMigration.deploy();
    await mockMigration.deployed();

    // Register the mock migration
    const code = await mockMigration.provider.getCode(mockMigration.address);
    migrationHash = ethers.utils.keccak256(code);
    const codeIndexDeployment = await deployments.get("ERC7744");
    const codeIndex = new ethers.Contract(
      codeIndexDeployment.address,
      codeIndexDeployment.abi
    ).connect(owner) as ERC7744;
    await codeIndex.register(mockMigration.address);

    const MockERC20 = (await ethers.getContractFactory("MockERC20")) as MockERC20__factory;
    const mockERC20 = await MockERC20.deploy("a", "a", 100);
    await mockERC20.deployed();
    const erc20Code = await mockERC20.provider.getCode(mockERC20.address);
    const erc20Hash = ethers.utils.keccak256(erc20Code);
    await codeIndex.register(mockERC20.address);

    const Repository = (await ethers.getContractFactory(
      "OwnableRepository"
    )) as OwnableRepository__factory;
    const repository = await Repository.deploy(
      owner.address,
      ethers.utils.formatBytes32String("MockRepository"),
      "0x"
    );
    await repository.deployed();

    // Mock Upgradable app
    const MockUpgradableApp = (await ethers.getContractFactory(
      "UpgradableDistribution"
    )) as UpgradableDistribution__factory;
    const mockUpgradableApp = await MockUpgradableApp.deploy(
      erc20Hash,
      ethers.utils.formatBytes32String(""),
      "MockUpgradableApp",
      1
    );
    await mockUpgradableApp.deployed();
    const upgradableCode = await mockUpgradableApp.provider.getCode(mockUpgradableApp.address);
    const upgradableHash = ethers.utils.keccak256(upgradableCode);
    await codeIndex.register(mockUpgradableApp.address);

    await repository.newRelease(
      upgradableHash,
      ethers.utils.formatBytes32String("MockUpgradableApp"),
      { major: 1, minor: 0, patch: 0 },
      migrationHash
    );
    await repository.newRelease(
      erc20Hash,
      ethers.utils.formatBytes32String("MockERC20"),
      { major: 2, minor: 0, patch: 0 },
      migrationHash
    );

    const WrappedProxyInitializer = (await ethers.getContractFactory(
      "WrappedProxyInitializer"
    )) as WrappedProxyInitializer__factory;
    const wrappedProxyInitializer = await WrappedProxyInitializer.deploy();
    await wrappedProxyInitializer.deployed();

    // Add distribution to mock distributor
    await mockDistributor[
      "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
    ](
      repository.address,
      wrappedProxyInitializer.address,
      createVersionRequirement(1, 0, 0, 1),
      "MockUpgradableApp"
    );
    distributorId = await mockDistributor.getIdFromAlias("MockUpgradableApp");
    // migrationId = keccak256(abi.encode(distributionId, migrationHash, strategy));
    migrationId = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "bytes32", "uint8"],
        [distributorId, migrationHash, 0]
      )
    );
    // Install upgradable app
    await mockInstaller.connect(owner).install(mockDistributor.address, distributorId, "0x");
    await mockDistributor.changeVersion(distributorId, createVersionRequirement(2, 0, 0, 1));
    await mockDistributor.addVersionMigration(
      distributorId,
      createVersionRequirement(1, 0, 0, 1),
      createVersionRequirement(2, 0, 0, 1),
      migrationHash,
      0,
      "0x"
    );
  });

  it("should upgrade an app successfully", async function () {
    // Prepare migration data
    const appId = 1;
    const userCalldata = "0x1234";
    // Call upgradeApp
    await mockInstaller.connect(owner).upgradeApp(appId, migrationId, userCalldata);

    // Success if no revert - this covers the upgradeApp code path
  });

  it("should revert when app is not installed", async function () {
    // Try to upgrade a non-existent app
    const nonExistentAppId = 999;
    const migrationHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test-migration"));
    const userCalldata = "0x1234";

    // Should revert with proper message
    await expect(
      mockInstaller.connect(owner).upgradeApp(nonExistentAppId, migrationHash, userCalldata)
    ).to.be.revertedWith("App not installed");
  });
});
