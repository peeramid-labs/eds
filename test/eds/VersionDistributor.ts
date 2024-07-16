import { ethers } from "hardhat";
import { Signer } from "ethers";
import { expect } from "chai";
import {
  CloneDistribution,
  CodeHashDistribution,
  CodeHashDistribution__factory,
  CodeIndex,
  Distributor,
  Distributor__factory,
  MockCloneDistribution__factory,
  OwnableDistributor__factory,
  OwnableRepository__factory,
  OwnableVersionDistributor__factory,
  Repository,
  TestFacet,
  TestFacet__factory,
  VersionDistributor,
} from "../../types";
import hre, { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("Version Distributor", function () {
  let codeIndex: CodeIndex;
  let distributor: VersionDistributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let mockDistr: CloneDistribution;
  let repository: Repository;

  beforeEach(async function () {
    await deployments.fixture("code_index"); // This is the key addition
    const CodeIndex = await ethers.getContractFactory("CodeIndex");
    [deployer, owner] = await ethers.getSigners();
    const codeIndexDeployment = await deployments.get("CodeIndex");
    codeIndex = new ethers.Contract(
      codeIndexDeployment.address,
      CodeIndex.interface
    ).connect(deployer) as CodeIndex;

    const Repository = (await ethers.getContractFactory(
      "OwnableRepository"
    )) as OwnableRepository__factory;
    repository = await Repository.deploy(owner.address);
    const repositoryCode = await repository.provider.getCode(
      repository.address
    );

    const CloneDistribution = (await ethers.getContractFactory(
      "MockCloneDistribution"
    )) as MockCloneDistribution__factory;
    mockDistr = await CloneDistribution.deploy();
    await mockDistr.deployed();
    const code = await mockDistr.provider.getCode(mockDistr.address);
    const mockDistributionId = ethers.utils.keccak256(code);
    await codeIndex.register(mockDistr.address);

    repository
      .connect(owner)
      .newRelease(
        mockDistributionId,
        ethers.utils.formatBytes32String("test"),
        {
          major: 1,
          minor: 0,
          patch: 0,
        }
      );

    const Distributor = (await ethers.getContractFactory(
      "OwnableVersionDistributor"
    )) as OwnableVersionDistributor__factory;
    distributor = await Distributor.deploy(owner.address);
  });

  it("Only Owner can add distribution instantiate a contract", async function () {
    expect(
      await distributor
        .connect(owner)
        .addVersionedDistribution(
          repository.address,
          { major: 1, minor: 0, patch: 0 },
          1,
          ethers.utils.formatBytes32String("")
        )
    ).to.emit(distributor, "VersionedDistributionAdded");
    await expect(
      distributor
        .connect(deployer)
        .addVersionedDistribution(
          repository.address,
          { major: 1, minor: 0, patch: 0 },
          1,
          ethers.utils.formatBytes32String("")
        )
    ).to.be.revertedWithCustomError(distributor, "OwnableUnauthorizedAccount");
  });

  it("Does not allow instantiate a repository that was not added", async function () {
    const TestFacetDistribution = (await ethers.getContractFactory(
      "TestFacet"
    )) as TestFacet__factory;
    const testFacetDistribution = await TestFacetDistribution.deploy();
    await testFacetDistribution.deployed();
    await codeIndex.register(testFacetDistribution.address);
    await expect(
      distributor
        .connect(owner)
        .instantiate(
          testFacetDistribution.address,
          ethers.utils.formatBytes32String("")
        )
    ).to.be.revertedWithCustomError(distributor, "InvalidRepository");
  });

  describe("when distribution is added", function () {
    beforeEach(async function () {
      await distributor
        .connect(owner)
        .addVersionedDistribution(
          repository.address,
          { major: 1, minor: 0, patch: 0 },
          1,
          ethers.utils.formatBytes32String("")
        );
    });

    it("Is possible to instantiate a contract", async function () {
      expect(
        await distributor
          .connect(owner)
          .instantiate(repository.address, ethers.utils.formatBytes32String(""))
      ).to.emit(distributor, "Instantiated");
    });

    it("Is possible to remove a distribution", async function () {
      expect(
        await distributor
          .connect(owner)
          .removeVersionedDistribution(repository.address)
      ).to.emit(distributor, "DistributionRemoved");
    });

    it("reverts if version has changed above the threshold", async function () {
      let instanceAddress: string;
      let receipt = await (
        await distributor
          .connect(owner)
          .instantiate(repository.address, ethers.utils.formatBytes32String(""))
      ).wait();
      let parsed = utils.getSuperInterface().parseLog(receipt.logs[0]);
      instanceAddress = parsed.args.instances[0];

      await distributor
        .connect(owner)
        .changeRequirement(
          repository.address,
          { major: 2, minor: 0, patch: 0 },
          2
        );
      await expect(
        distributor
          .connect(owner)
          .beforeCallValidation("0x", "0x00000000", instanceAddress, "0", "0x")
      ).to.be.revertedWithCustomError(distributor, "VersionOutdated");
      await distributor
        .connect(owner)
        .changeRequirement(
          repository.address,
          { major: 1, minor: 0, patch: 0 },
          1
        );
      await expect(
        distributor
          .connect(owner)
          .beforeCallValidation("0x", "0x00000000", instanceAddress, "0", "0x")
      ).to.not.be.revertedWithCustomError(distributor, "VersionOutdated");
    });

    describe("When distribution is instantiated and then removed", () => {
      let instanceAddress: string;
      beforeEach(async () => {
        let receipt = await (
          await distributor
            .connect(owner)
            .instantiate(
              repository.address,
              ethers.utils.formatBytes32String("")
            )
        ).wait();
        let parsed = utils.getSuperInterface().parseLog(receipt.logs[0]);
        instanceAddress = parsed.args.instances[0];
        console.log(instanceAddress);
        await distributor
          .connect(owner)
          .removeVersionedDistribution(repository.address);
      });
      it("Instance is invalid upon check", async () => {
        await expect(
          distributor
            .connect(owner)
            .beforeCallValidation(
              "0x",
              "0x00000000",
              instanceAddress,
              "0",
              "0x"
            )
        ).to.be.revertedWithCustomError(distributor, "InvalidInstance");
      });
    });
  });
});
