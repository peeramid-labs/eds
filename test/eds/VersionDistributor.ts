import { ethers, network } from "hardhat";
import { expect } from "chai";
import {
  MockCloneDistribution,
  ERC7744,
  MockCloneDistribution__factory,
  OwnableDistributor__factory,
  OwnableRepository__factory,
  Repository,
  TestFacet__factory,
  OwnableDistributor,
  MockMigration__factory,
  MockMigration,
  OwnableInstaller__factory,
  OwnableInstaller
} from "../../types";
import { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("Version Distributor", function () {
  let codeIndex: ERC7744;
  let distributor: OwnableDistributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let mockDistr: MockCloneDistribution;
  let repository: Repository;
  let mockInstaller: OwnableInstaller;
  let dummyMigration: MockMigration;
  let dummyMigrationCodeHash: string;

  beforeEach(async function () {
    await deployments.fixture("ERC7744"); // This is the key addition
    const ERC7744 = await ethers.getContractFactory("ERC7744");
    [deployer, owner] = await ethers.getSigners();
    const codeIndexDeployment = await deployments.get("ERC7744");
    const MockInstaller = (await ethers.getContractFactory(
      "OwnableInstaller"
    )) as OwnableInstaller__factory;
    mockInstaller = await MockInstaller.deploy(deployer.address, owner.address);

    codeIndex = new ethers.Contract(codeIndexDeployment.address, ERC7744.interface).connect(
      deployer
    ) as ERC7744;

    const DummyMigration = (await ethers.getContractFactory(
      "MockMigration"
    )) as MockMigration__factory;
    dummyMigration = await DummyMigration.deploy();
    await dummyMigration.deployed();
    await codeIndex.register(dummyMigration.address);
    dummyMigrationCodeHash = ethers.utils.keccak256(
      await dummyMigration.provider.getCode(dummyMigration.address)
    );

    const Repository = (await ethers.getContractFactory(
      "OwnableRepository"
    )) as OwnableRepository__factory;
    repository = await Repository.deploy(
      owner.address,
      ethers.utils.formatBytes32String("testRepository"),
      "test"
    );

    const CloneDistribution = (await ethers.getContractFactory(
      "MockCloneDistribution"
    )) as MockCloneDistribution__factory;
    mockDistr = await CloneDistribution.deploy("MockCloneDistribution");
    await mockDistr.deployed();
    const code = await mockDistr.provider.getCode(mockDistr.address);
    const mockDistributionId = ethers.utils.keccak256(code);
    await codeIndex.register(mockDistr.address);

    const tx = await repository.connect(owner).newRelease(
      mockDistributionId,
      ethers.utils.formatBytes32String("test"),
      {
        major: 1,
        minor: 0,
        patch: 0
      },
      dummyMigrationCodeHash
    );
    await tx.wait();

    const Distributor = (await ethers.getContractFactory(
      "OwnableDistributor"
    )) as OwnableDistributor__factory;
    distributor = await Distributor.deploy(owner.address);
  });

  it("Only Owner can add distribution instantiate a contract", async function () {
    expect(
      await distributor
        .connect(owner)
        [
          "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
        ](repository.address, ethers.constants.AddressZero, { version: { major: 0, minor: 0, patch: 1 }, requirement: 1 }, "test")
    ).to.emit(distributor, "VersionedDistributionAdded");
    await expect(
      distributor
        .connect(deployer)
        [
          "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
        ](repository.address, ethers.constants.AddressZero, { version: { major: 1, minor: 0, patch: 1 }, requirement: 1 }, "test")
    ).to.be.revertedWithCustomError(distributor, "OwnableUnauthorizedAccount");
  });

  it("Does not allow instantiate a repository that was not added", async function () {
    const TestFacetDistribution = (await ethers.getContractFactory(
      "TestFacet"
    )) as TestFacet__factory;
    const testFacetDistribution = await TestFacetDistribution.deploy();
    await testFacetDistribution.deployed();
    await codeIndex.register(testFacetDistribution.address);
    const id = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [testFacetDistribution.address, ethers.constants.AddressZero]
      )
    );
    await expect(
      distributor.connect(owner).instantiate(id, ethers.utils.formatBytes32String(""))
    ).to.be.revertedWithCustomError(distributor, "DistributionNotFound");
  });

  describe("when distribution is added", function () {
    beforeEach(async function () {
      await distributor
        .connect(owner)
        [
          "addDistribution(address,address,((uint64,uint64,uint128),uint8),string)"
        ](repository.address, ethers.constants.AddressZero, { version: { major: 1, minor: 0, patch: 0 }, requirement: 1 }, "test");
    });

    it("Is possible to instantiate a contract", async function () {
      //InstantiateData memory instantiateData = abi.decode(data, (InstantiateData));
      const instantiateData = ethers.utils.defaultAbiCoder.encode(
        ["address", "bytes"],
        [mockInstaller.address, ethers.utils.formatBytes32String("")]
      );
      const id = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["address", "address"],
          [repository.address, ethers.constants.AddressZero]
        )
      );
      expect(await distributor.connect(owner).instantiate(id, instantiateData)).to.emit(
        distributor,
        "Instantiated"
      );
    });

    it("Is possible to remove a distribution", async function () {
      const id = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["address", "address"],
          [repository.address, ethers.constants.AddressZero]
        )
      );

      expect(await distributor.connect(owner).disableDistribution(id)).to.emit(
        distributor,
        "DistributionDisabled"
      );
    });

    it("reverts if version has changed above the threshold", async function () {
      let instanceAddress: string;
      const id = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(
          ["address", "address"],
          [repository.address, ethers.constants.AddressZero]
        )
      );
      let receipt = await (
        await distributor.connect(owner).instantiate(id, ethers.utils.formatBytes32String(""))
      ).wait();
      let parsed = utils.getSuperInterface().parseLog(receipt.logs[0]);
      instanceAddress = parsed.args.instances[0];
      const impersonatedSigner = await ethers.getImpersonatedSigner(instanceAddress);
      await network.provider.send("hardhat_setBalance", [
        impersonatedSigner.address,
        "0x9000000000000000000"
      ]);
      await distributor
        .connect(owner)
        .changeVersion(id, { version: { major: 2, minor: 0, patch: 0 }, requirement: 2 });
      await expect(
        distributor
          .connect(owner)
          .beforeCall(
            ethers.utils.defaultAbiCoder.encode(
              ["tuple(address,address,bytes)"],
              [[instanceAddress!, owner.address!, "0x"]]
            ),
            "0x00000000",
            instanceAddress,
            "0",
            "0x"
          )
      ).to.be.revertedWithCustomError(distributor, "VersionOutdated");
      await distributor
        .connect(owner)
        .changeVersion(id, { version: { major: 1, minor: 0, patch: 0 }, requirement: 1 });
      await expect(
        distributor
          .connect(owner)
          .beforeCall(
            ethers.utils.defaultAbiCoder.encode(["address"], [instanceAddress]),
            "0x00000000",
            instanceAddress,
            "0",
            "0x"
          )
      ).to.not.be.revertedWithCustomError(distributor, "VersionOutdated");
    });

    describe("When distribution is instantiated and then removed", () => {
      let instanceAddress: string;
      beforeEach(async () => {
        const repoId = ethers.utils.keccak256(
          ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [repository.address, ethers.constants.AddressZero]
          )
        );
        let receipt = await (
          await distributor.connect(owner).instantiate(repoId, ethers.utils.formatBytes32String(""))
        ).wait();
        let parsed = utils.getSuperInterface().parseLog(receipt.logs[0]);
        instanceAddress = parsed.args.instances[0];
        const id = ethers.utils.keccak256(
          ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [repository.address, ethers.constants.AddressZero]
          )
        );
        await distributor.connect(owner).disableDistribution(id);
      });
      it("Instance is invalid upon check", async () => {
        await expect(
          distributor
            .connect(owner)
            .beforeCall(
              ethers.utils.defaultAbiCoder.encode(
                ["tuple(address,address,bytes)"],
                [[instanceAddress!, owner.address!, "0x"]]
              ),
              "0x00000000",
              instanceAddress,
              "0",
              "0x"
            )
        ).to.be.revertedWithCustomError(distributor, "InvalidApp");
      });
    });
  });
});
