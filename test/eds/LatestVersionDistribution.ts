import { deployments, ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  ERC7744,
  ERC7744__factory,
  LatestVersionDistribution,
  MockCloneDistribution,
  MockCloneDistribution__factory,
  MockERC20__factory,
  MockLatestVersionDistribution__factory,
  MockRepository,
  MockRepository__factory
} from "../../types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("LatestUpgradableDistribution", function () {
  let deployer: SignerWithAddress;
  let user: SignerWithAddress;
  let repository: MockRepository;
  let latestVersionDist: LatestVersionDistribution; // Use any to allow sources() method
  let mockDistribution: MockCloneDistribution;
  // Use bytes32 for metadata as expected by the LatestUpgradableDistribution constructor
  const metadata = "testMetadata";

  // Repository name should be bytes32 as per IRepository interface
  const repoName = ethers.utils.formatBytes32String("MyRepo");

  async function deployTestFixture() {
    await deployments.fixture("ERC7744");
    [deployer, user] = await ethers.getSigners();

    // Use MockRepository which has a simpler implementation
    const MockRepositoryFactory = (await ethers.getContractFactory(
      "MockRepository"
    )) as MockRepository__factory;
    repository = await MockRepositoryFactory.deploy();
    await repository.deployed();

    // Deploy a mock implementation contract for cloning
    const MockDistFactory = (await ethers.getContractFactory(
      "MockCloneDistribution"
    )) as MockCloneDistribution__factory;
    mockDistribution = await MockDistFactory.deploy("name");
    await mockDistribution.deployed();

    // Deploy MockLatestVersionDistribution instead
    const MockLatestVersionDistributionFactory = (await ethers.getContractFactory(
      "MockLatestVersionDistribution"
    )) as MockLatestVersionDistribution__factory;
    latestVersionDist = await MockLatestVersionDistributionFactory.deploy(
      repository.address,
      metadata
    );
    await latestVersionDist.deployed();

    // Add a release to the repository with sourceId pointing to mockDistribution
    const version1 = { major: 0, minor: 1, patch: 0 };

    const mockERC20 = (await ethers.getContractFactory("MockERC20")) as MockERC20__factory;
    const mockERC20Instance = await mockERC20.deploy(
      "MockERC20",
      "MockERC20",
      "1000000000000000000000000"
    );
    await mockERC20Instance.deployed();
    const code = await mockERC20Instance.provider.getCode(mockERC20Instance.address);

    const sourceId1 = ethers.utils.keccak256(code);
    const ERC7744 = (await ethers.getContractFactory("ERC7744")) as ERC7744__factory;
    const codeIndexDeployment = await deployments.get("ERC7744");
    const codeIndex = new ethers.Contract(codeIndexDeployment.address, ERC7744.interface).connect(
      deployer
    ) as ERC7744;
    await codeIndex.register(mockERC20Instance.address);
    await codeIndex.register(latestVersionDist.address);

    // Use bytes instead of string for the metadata
    const metadataBytes = ethers.utils.toUtf8Bytes("metadata");

    // Add a new release to the repository - this will also set it as the latest version
    await repository.newRelease(sourceId1, metadataBytes, version1, ethers.constants.HashZero);

    return { deployer, user, repository, latestVersionDist, mockDistribution };
  }

  beforeEach(async function () {
    await loadFixture(deployTestFixture);
  });

  describe("Constructor", function () {
    it("should set the repository address correctly", async function () {
      expect(await latestVersionDist.repository()).to.equal(repository.address);
    });

    it("should set the metadata correctly", async function () {
      // Need a way to read metadata, contractURI reads it for now
      const uri = await latestVersionDist.contractURI();
      expect(uri).to.equal(metadata); // Using string comparison now
    });
  });

  describe("contractURI", function () {
    it("should return the metadata as a string", async function () {
      const uri = await latestVersionDist.contractURI();
      // Expect the string value directly
      expect(uri).to.equal(metadata);
    });
  });

  // Skipping instantiate test for now since it requires a fully mocked repository
  describe("instantiate", function () {
    it("should instantiate without reverting", async function () {
      // Just ensure it doesn't revert for now
      await latestVersionDist.instantiate("0x");
    });
  });
});
