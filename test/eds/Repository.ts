import { ethers } from "hardhat";
import { Signer } from "ethers";
import { expect } from "chai";
import {
  CodeHashDistribution,
  CodeHashDistribution__factory,
  CodeIndex,
  Distributor,
  Distributor__factory,
  MockCloneDistribution,
  MockCloneDistribution__factory,
  MockInstaller,
  MockInstaller__factory,
  OwnableDistributor,
  OwnableDistributor__factory,
  OwnableRepository__factory,
  Repository,
  Repository__factory,
  TestFacet,
  TestFacet__factory,
} from "../../types";
import hre, { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("Installer", function () {
  let codeIndex: CodeIndex;
  let distributor: OwnableDistributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let target: SignerWithAddress;
  let firstId: any;
  let secondId: any;
  let thirdId: any;
  let fourthId: any;
  let installer: MockInstaller;
  let repository: Repository;

  beforeEach(async function () {
    await deployments.fixture("code_index"); // This is the key addition
    const CodeIndex = await ethers.getContractFactory("CodeIndex");
    [deployer, owner, target] = await ethers.getSigners();
    const codeIndexDeployment = await deployments.get("CodeIndex");
    codeIndex = new ethers.Contract(
      codeIndexDeployment.address,
      CodeIndex.interface
    ).connect(deployer) as CodeIndex;

    const Repository = (await ethers.getContractFactory(
      "OwnableRepository"
    )) as OwnableRepository__factory;
    repository = await Repository.deploy(
      owner.address,
      ethers.utils.formatBytes32String("testRepository")
    );
    const repositoryCode = await repository.provider.getCode(
      repository.address
    );
    fourthId = ethers.utils.keccak256(repositoryCode);

    const Distributor = (await ethers.getContractFactory(
      "OwnableDistributor"
    )) as OwnableDistributor__factory;
    distributor = await Distributor.deploy(owner.address);
    const distributorCode = await distributor.provider.getCode(
      distributor.address
    );
    thirdId = ethers.utils.keccak256(distributorCode);

    const CloneDistribution = (await ethers.getContractFactory(
      "MockCloneDistribution"
    )) as MockCloneDistribution__factory;
    const cloneDistribution = await CloneDistribution.deploy();
    await cloneDistribution.deployed();
    const code = await cloneDistribution.provider.getCode(
      cloneDistribution.address
    );
    firstId = ethers.utils.keccak256(code);
    await codeIndex.register(cloneDistribution.address);
    distributor
      .connect(owner)
      .addDistribution(firstId, ethers.utils.formatBytes32String(""));
    const Installer = (await ethers.getContractFactory(
      "MockInstaller"
    )) as MockInstaller__factory;
    installer = await Installer.deploy(target.address, owner.address);

    const installerCode = await installer.provider.getCode(installer.address);
    secondId = ethers.utils.keccak256(installerCode);
  });
  it("Can add new versions to the repository", async function () {
    await expect(
      repository
        .connect(owner)
        .newRelease(firstId, ethers.utils.formatBytes32String("test"), {
          major: 1,
          minor: 0,
          patch: 0,
        })
    ).to.emit(repository, "VersionAdded");
  });
  it("Can cannot create version with gap number ", async function () {
    await expect(
      repository
        .connect(owner)
        .newRelease(firstId, ethers.utils.formatBytes32String("test"), {
          major: 2,
          minor: 0,
          patch: 0,
        })
    ).to.be.revertedWithCustomError(repository, "VersionIncrementInvalid");
  });
  it("Can cannot create version with zero major ", async function () {
    await expect(
      repository
        .connect(owner)
        .newRelease(firstId, ethers.utils.formatBytes32String("test"), {
          major: 0,
          minor: 0,
          patch: 0,
        })
    ).to.be.revertedWithCustomError(repository, "ReleaseZeroNotAllowed");
  });
  describe("When version was created", function () {
    beforeEach(async () => {
      await repository
        .connect(owner)
        .newRelease(firstId, ethers.utils.formatBytes32String("test"), {
          major: 1,
          minor: 0,
          patch: 0,
        });
    });
    it("Can get versions", async function () {
      const src = await repository.get({ major: 1, minor: 0, patch: 0 }, 1);
      expect(src.sourceId).to.be.eq(firstId);
    });
    it("Cannot create same version again", async function () {
      await expect(
        repository
          .connect(owner)
          .newRelease(firstId, ethers.utils.formatBytes32String("test"), {
            major: 1,
            minor: 0,
            patch: 0,
          })
      ).to.be.revertedWithCustomError(repository, "VersionExists");
    });
    it("Can create minor release", async function () {
      await expect(
        repository
          .connect(owner)
          .newRelease(firstId, ethers.utils.formatBytes32String("test"), {
            major: 1,
            minor: 1,
            patch: 0,
          })
      ).to.emit(repository, "VersionAdded");
    });
    describe("When minor and second major versions were created", function () {
      beforeEach(async () => {
        await repository
          .connect(owner)
          .newRelease(secondId, ethers.utils.formatBytes32String("test"), {
            major: 2,
            minor: 0,
            patch: 0,
          });
        await repository
          .connect(owner)
          .newRelease(thirdId, ethers.utils.formatBytes32String("test"), {
            major: 1,
            minor: 1,
            patch: 0,
          });
        await repository
          .connect(owner)
          .newRelease(fourthId, ethers.utils.formatBytes32String("test"), {
            major: 2,
            minor: 1,
            patch: 0,
          });
      });
      it("Can get version by MAJOR", async () => {
        let src = await repository.get({ major: 1, minor: 0, patch: 0 }, 2);
        expect(src.sourceId).to.be.eq(thirdId);
        src = await repository.get({ major: 2, minor: 0, patch: 0 }, 2);
        expect(src.sourceId).to.be.eq(fourthId);
      });
      it("Can get version by MAJOR_MINOR", async () => {
        let src = await repository.get({ major: 1, minor: 0, patch: 1 }, 3);
        expect(src.sourceId).to.be.eq(firstId);
        src = await repository.get({ major: 1, minor: 1, patch: 4 }, 3);
        expect(src.sourceId).to.be.eq(thirdId);
        await expect(
          repository.get({ major: 2, minor: 2, patch: 1 }, 3)
        ).to.be.revertedWithCustomError(repository, "VersionDoesNotExist");
      });
      it("Can get version by GREATER_EQUAL", async () => {
        let src = await repository.get({ major: 1, minor: 0, patch: 0 }, 4);
        expect(src.sourceId).to.be.eq(fourthId);
        src = await repository.get({ major: 2, minor: 0, patch: 0 }, 4);
        expect(src.sourceId).to.be.eq(fourthId);
        src = await repository.get({ major: 2, minor: 1, patch: 0 }, 4);
        expect(src.sourceId).to.be.eq(fourthId);
        await expect(
          repository.get({ major: 2, minor: 2, patch: 1 }, 4)
        ).to.be.revertedWithCustomError(repository, "VersionDoesNotExist");
      });
      it("Can get version by GREATER", async () => {
        let src = await repository.get({ major: 1, minor: 0, patch: 0 }, 5);
        expect(src.sourceId).to.be.eq(fourthId);
        src = await repository.get({ major: 2, minor: 0, patch: 0 }, 5);
        expect(src.sourceId).to.be.eq(fourthId);
        await expect(
          repository.get({ major: 2, minor: 1, patch: 0 }, 5)
        ).to.be.revertedWithCustomError(repository, "VersionDoesNotExist");
      });
    });
  });
});
