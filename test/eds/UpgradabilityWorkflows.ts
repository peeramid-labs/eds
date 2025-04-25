import { ethers } from "hardhat";
import { expect } from "chai";
import {
  ERC7744,
  OwnableDistributor,
  OwnableDistributor__factory,
  MockInstaller__factory,
  VersionDistribution__factory,
  MockMigration__factory,
  MockERC20__factory,
  OwnableRepository__factory,
  MockInstaller
} from "../../types";
import { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("Upgradability Workflows", function () {
  let codeIndex: ERC7744;
  let distributor: OwnableDistributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let erc20CodeHash: string;
  let mockMigration: any;
  let versionDistribution: any;
  let versionDistributionId: string;
  let distributionId: string;
  let installer: MockInstaller;
  let mockERC20Instance: any;

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

    // Deploy mock installer (user infrastructure)
    const MockInstallerFactory = (await ethers.getContractFactory(
      "MockInstaller"
    )) as MockInstaller__factory;
    installer = await MockInstallerFactory.deploy(user.address, user.address);
    await installer.deployed();

    // Deploy mock ERC20 for code hash
    const MockERC20 = (await ethers.getContractFactory("MockERC20")) as MockERC20__factory;
    mockERC20Instance = await MockERC20.deploy("TokenA", "TKA", 1000);
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

    // Deploy VersionDistribution
    const VersionDistributionFactory = (await ethers.getContractFactory(
      "VersionDistribution"
    )) as VersionDistribution__factory;
    versionDistribution = await VersionDistributionFactory.deploy(
      erc20CodeHash,
      ethers.utils.formatBytes32String("metadata"),
      "TestDistribution",
      1, // version
      true // allowUserCalldata - allowing user data during instantiation
    );
    await versionDistribution.deployed();

    // Get version distribution code hash and register
    const code = await versionDistribution.provider.getCode(versionDistribution.address);
    versionDistributionId = ethers.utils.keccak256(code);
    await codeIndex.register(versionDistribution.address);

    // Whitelist the distributor in the installer
    await installer.connect(user).whitelistDistributor(distributor.address);
  });

  describe("Installer Workflow", function () {
    it("should install an app through the installer", async function () {
      // Register the distribution with the distributor
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](versionDistributionId, ethers.constants.AddressZero, "TestDistribution");

      // Get the distribution ID from alias
      distributionId = await distributor.getIdFromAlias("TestDistribution");

      // Prepare installation data
      const installData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address,bytes)"],
        [[installer.address, "0x"]]
      );

      // Get installed app information
      const appCount = await installer.getAppsNum();
      await installer.connect(user).install(distributor.address, distributionId, installData);
      const newAppCount = await installer.getAppsNum();
      expect(newAppCount).to.equal(appCount.toNumber() + 1, "Should have one app instance");

      // Get the instance details
      const appComponents = await installer.getApp(1);
      expect(appComponents.length).to.be.gt(0, "Should have at least one component");

      // Verify the instance is recognized by the installer
      const isApp = await installer.isApp(appComponents.contracts[0]);
      expect(isApp).to.be.true;

      // Verify the distributor association
      const linkedDistributor = await installer.distributorOf(appComponents.contracts[0]);
      expect(linkedDistributor).to.equal(distributor.address);
    });

    it("should uninstall an app through the installer", async function () {
      // Register the distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](versionDistributionId, ethers.constants.AddressZero, "TestDistribution");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("TestDistribution");

      // Install the app
      const installData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address,bytes)"],
        [[installer.address, "0x"]]
      );

      await installer.connect(user).install(distributor.address, distributionId, installData);

      // Get the installed app details
      const appComponents = await installer.getApp(1);
      const instanceId = 1;

      // Uninstall the app
      await installer.connect(user).uninstall(instanceId);

      // Verify the instance is no longer recognized
      if (appComponents && appComponents.length > 0) {
        const isApp = await installer.isApp(appComponents.contracts[0]);
        expect(isApp).to.be.false;
      }
    });

    it("should change distributor for an app", async function () {
      // Register the distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](versionDistributionId, ethers.constants.AddressZero, "TestDistribution");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("TestDistribution");

      // Install the app
      const installData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address,bytes)"],
        [[installer.address, "0x"]]
      );

      await installer.connect(user).install(distributor.address, distributionId, installData);

      // Deploy a new distributor
      const NewDistributor = (await ethers.getContractFactory(
        "OwnableDistributor"
      )) as OwnableDistributor__factory;
      const newDistributor = await NewDistributor.deploy(owner.address);
      await newDistributor.deployed();

      // Get the installed app components
      const appComponents = await installer.getApp(1);

      // Change the distributor
      await installer.connect(user).changeDistributor(1, newDistributor.address, []);

      // Verify the distributor changed
      if (appComponents && appComponents.length > 0) {
        const linkedDistributor = await installer.distributorOf(appComponents.contracts[0]);
        expect(linkedDistributor).to.equal(newDistributor.address);
        expect(await distributor.getAppId(appComponents.contracts[0])).to.equal(0);
      }
    });
  });

  describe("Distributor Control", function () {
    it("should allow and disallow distributions", async function () {
      // Register the distribution with the distributor
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](versionDistributionId, ethers.constants.AddressZero, "TestDistribution");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("TestDistribution");

      // First revoke whitelist to test specific allowances
      await installer.connect(user).revokeWhitelistedDistributor(distributor.address);

      // Allow specific distribution
      await installer.connect(user).allowDistribution(distributor.address, distributionId);

      // Install should work with allowed distribution
      const installData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address,bytes)"],
        [[installer.address, "0x"]]
      );

      await expect(
        installer.connect(user).install(distributor.address, distributionId, installData)
      ).to.not.be.reverted;

      // Now disallow the distribution
      await installer.connect(user).disallowDistribution(distributor.address, distributionId);

      // Install should now fail
      await expect(
        installer.connect(user).install(distributor.address, distributionId, installData)
      ).to.be.reverted;
    });

    it("should disable a distribution", async function () {
      // Register the distribution
      await distributor
        .connect(owner)
        [
          "addDistribution(bytes32,address,string)"
        ](versionDistributionId, ethers.constants.AddressZero, "TestDistribution");

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("TestDistribution");

      // Disable the distribution
      await distributor.connect(owner).disableDistribution(distributionId);

      // Install should fail with disabled distribution
      const installData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address,bytes)"],
        [[installer.address, "0x"]]
      );

      await expect(
        installer.connect(user).install(distributor.address, distributionId, installData)
      ).to.be.revertedWithCustomError(distributor, "DistributionNotFound");
    });
  });
});
