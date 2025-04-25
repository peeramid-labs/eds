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
  OwnableRepository__factory
} from "../../types";
import { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("Version Workflows", function () {
  let codeIndex: ERC7744;
  let distributor: OwnableDistributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let erc20CodeHash: string;
  let repository: any;
  let mockMigration: any;
  let installer: any;
  let distributionId: string;
  let appId: number | null = null;
  let appInstances: string[] = [];

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

  // Helper function to create version
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

    // Deploy mock installer (user infrastructure)
    const MockInstallerFactory = (await ethers.getContractFactory(
      "MockInstaller"
    )) as MockInstaller__factory;
    installer = await MockInstallerFactory.deploy(user.address, user.address);
    await installer.deployed();

    // Deploy mock ERC20 for code hash
    const MockERC20 = (await ethers.getContractFactory("MockERC20")) as MockERC20__factory;
    const mockERC20Instance = await MockERC20.deploy("TokenA", "TKA", 1000);
    await mockERC20Instance.deployed();

    // Register ERC20 code
    const codeErc20 = await mockERC20Instance.provider.getCode(mockERC20Instance.address);
    erc20CodeHash = ethers.utils.keccak256(codeErc20);
    await codeIndex.register(mockERC20Instance.address);

    // Deploy mock migration contracts for different versions
    const MockMigrationFactory = (await ethers.getContractFactory(
      "MockMigration"
    )) as MockMigration__factory;
    mockMigration = await MockMigrationFactory.deploy();
    await mockMigration.deployed();

    // Deploy repository for versioning
    const RepositoryFactory = (await ethers.getContractFactory(
      "OwnableRepository"
    )) as OwnableRepository__factory;
    repository = await RepositoryFactory.deploy(
      owner.address,
      ethers.utils.formatBytes32String("TestRepository"),
      "test-uri"
    );
    await repository.deployed();

    // Whitelist the distributor in the installer
    await installer.connect(user).whitelistDistributor(distributor.address);
  });

  describe("Repository Version Management", function () {
    it("should add multiple releases to the repository", async function () {
      // Add first version to the repository (v1.0.0)
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(1, 0, 0),
        mockMigration.address
      );

      // Add second version to the repository (v1.0.1)
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(1, 0, 1),
        ethers.constants.AddressZero // No migration for patch releases
      );

      // Add third version to the repository (v1.1.0)
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(1, 1, 0),
        ethers.constants.AddressZero // No migration for minor releases
      );

      // Add fourth version to the repository (v2.0.0)
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(2, 0, 0),
        mockMigration.address
      );

      // Check that all versions are registered
      const latestRelease = await repository.getLatest();
      expect(latestRelease.version.major).to.equal(2);
      expect(latestRelease.version.minor).to.equal(0);
      expect(latestRelease.version.patch).to.equal(0);

      // Check specific version retrieval
      const v101 = await repository.get(createVersionRequirement(1, 0, 1, 0)); // 0 = GTE
      expect(v101.sourceId).to.equal(erc20CodeHash);

      const v200 = await repository.get(createVersionRequirement(2, 0, 0, 0)); // 0 = GTE
      expect(v200.sourceId).to.equal(erc20CodeHash);
    });

    it("should use version requirement when registering distribution", async function () {
      // Add first version to the repository
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(1, 0, 0),
        mockMigration.address
      );

      // Add second version to the repository
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(2, 0, 0),
        mockMigration.address
      );

      // Register versioned distribution with distributor (requiring v1.0.0 or higher)
      await distributor
        .connect(owner)
        ["addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"](
          repository.address,
          ethers.constants.AddressZero,
          createVersionRequirement(1, 0, 0, 0), // 0 = GTE (greater than or equal)
          "VersionedDist"
        );

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("VersionedDist");
      expect(distributionId).to.not.equal(ethers.constants.HashZero);

      // Check that the distribution is linked to the repository
      const distribution = await distributor.getDistribution(distributionId);
      expect(distribution.distributionLocation).to.equal(repository.address);

      // Verify version requirements
      const versionReq = await distributor.versionRequirements(distributionId);
      expect(versionReq.version.major).to.equal(1);
      expect(versionReq.version.minor).to.equal(0);
      expect(versionReq.version.patch).to.equal(0);
      expect(versionReq.requirement).to.equal(0); // GTE
    });
  });

  describe("Basic Versioned Instantiation", function () {
    beforeEach(async function () {
      // Add first version to the repository
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(1, 0, 0),
        mockMigration.address
      );

      // Register versioned distribution with distributor
      await distributor
        .connect(owner)
        ["addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"](
          repository.address,
          ethers.constants.AddressZero,
          createVersionRequirement(1, 0, 0, 0), // 0 = GTE
          "VersionedDist"
        );

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("VersionedDist");
    });

    it("should instantiate a versioned distribution", async function () {
      // Prepare instantiation data
      const instantiateData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address,bytes)"],
        [[installer.address, "0x"]]
      );

      // Instantiate the distribution
      const tx = await distributor.connect(user).instantiate(distributionId, instantiateData);
      const receipt = await tx.wait();

      // Check that there are logs from the transaction
      expect(receipt.logs.length).to.be.gt(0);

      const instantiatedFilter = distributor.filters.Instantiated();
      const instantiatedLogs = await distributor.queryFilter(instantiatedFilter);
      expect(instantiatedLogs.length).to.be.eq(1);

      appId = instantiatedLogs[0].args.newAppId.toNumber();
      appInstances = instantiatedLogs[0].args.appComponents;
      expect(appId).to.not.be.null;
      expect(appInstances.length).to.be.gt(0);
      const currentVersion = await distributor.appVersions(appId);
      expect(currentVersion.major).to.equal(1);
      expect(currentVersion.minor).to.equal(0);
      expect(currentVersion.patch).to.equal(0);
    });
  });

  describe("Version Migration", function () {
    beforeEach(async function () {
      // Add first version to the repository
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(1, 0, 0),
        mockMigration.address
      );

      // Add second version to the repository
      await repository.connect(owner).newRelease(
        erc20CodeHash,
        "0x", // metadata
        createVersion(2, 0, 0),
        mockMigration.address
      );

      //   try {
      // Instantiate with v1.0.0
      const instantiateData = ethers.utils.defaultAbiCoder.encode(
        ["tuple(address,bytes)"],
        [[installer.address, "0x"]]
      );

      // Register versioned distribution with distributor
      await distributor
        .connect(owner)
        ["addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"](
          repository.address,
          ethers.constants.AddressZero,
          createVersionRequirement(1, 0, 0, 1), // 1 = EXACT
          "VersionedDist"
        );
      const tx = await distributor.connect(user).instantiate(distributionId, instantiateData);
      const receipt = await tx.wait();

      // Get the distribution ID
      distributionId = await distributor.getIdFromAlias("VersionedDist");

      // Add migration path from v1 to v2
      await distributor.connect(owner).addVersionMigration(
        distributionId,
        createVersionRequirement(1, 0, 0, 1), // From v1.0.0
        createVersionRequirement(2, 0, 0, 1), // To v2.0.0
        mockMigration.address,
        0, // MigrationStrategy.CALL
        "0x" // No special calldata
      );

      // Parse logs to get app information
      const parsed = utils.getSuperInterface().parseLog(receipt.logs[0]);
      appId = parsed.args.newAppId.toNumber();
      appInstances = parsed.args.appComponents;
      if (!appId) throw new Error("Failed to instantiate - no valid app ID");
    });

    it("should migrate from v1 to v2", async function () {
      if (!appId || !appInstances || appInstances.length === 0) {
        throw new Error("Instantiation failed, failing test");
      }

      // Calculate migration ID
      const migrationId = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "uint8"],
          [distributionId, mockMigration.address, 0]
        )
      );

      // Get initial version
      const initialVersion = await distributor.appVersions(appId);
      expect(initialVersion.major).to.equal(1);

      // Perform the upgrade
      await expect(
        distributor.connect(user)["upgradeUserInstance(uint256,bytes32,bytes)"](
          appId,
          migrationId,
          "0x" // No user calldata
        )
      ).to.emit(mockMigration, "Migrated");

      // Verify the new version
      const newVersion = await distributor.appVersions(appId);
      expect(newVersion.major).to.equal(2);
      expect(newVersion.minor).to.equal(0);
      expect(newVersion.patch).to.equal(0);
    });

    it("should not allow upgrade with invalid migration path", async function () {
      if (!appId || !appInstances || appInstances.length === 0) {
        throw new Error("Instantiation failed, failing test");
      }

      // Create a fake migration ID
      const fakeMigrationId = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["bytes32", "address", "uint8"],
          [distributionId, ethers.constants.AddressZero, 0]
        )
      );

      // Attempt to upgrade with invalid migration ID should fail
      await expect(
        distributor
          .connect(user)
          ["upgradeUserInstance(uint256,bytes32,bytes)"](appId, fakeMigrationId, "0x")
      ).to.be.reverted; // Should revert with migration not found
    });
  });
});
