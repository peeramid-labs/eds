import { ethers } from "hardhat";
import { expect } from "chai";
import {
  ERC7744,
  MockCloneDistribution__factory,
  OwnableDistributor,
  OwnableDistributor__factory,
  TestFacet__factory
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
        ["addDistribution(bytes32,address)"](cloneDistributionId, ethers.constants.AddressZero)
    ).to.emit(distributor, "DistributionAdded");
    await expect(
      distributor
        .connect(deployer)
        ["addDistribution(bytes32,address)"](cloneDistributionId, ethers.constants.AddressZero)
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
      const name = ethers.utils.formatBytes32String("test-distribution");
      const initializer = ethers.constants.AddressZero;

      await expect(
        distributor.connect(owner).addNamedDistribution(name, cloneDistributionId, initializer)
      )
        .to.emit(distributor, "DistributionAdded")
        .withArgs(name, await codeIndex.get(cloneDistributionId), initializer);
    });

    it("should revert when non-owner tries to add a named distribution", async function () {
      const name = ethers.utils.formatBytes32String("test-distribution");
      const initializer = ethers.constants.AddressZero;

      await expect(
        distributor.connect(deployer).addNamedDistribution(name, cloneDistributionId, initializer)
      ).to.be.revertedWithCustomError(distributor, "OwnableUnauthorizedAccount");
    });

    it("should revert when distribution ID does not exist", async function () {
      const name = ethers.utils.formatBytes32String("test-distribution");
      const initializer = ethers.constants.AddressZero;
      const nonExistentId = ethers.utils.formatBytes32String("non-existent");

      await expect(
        distributor.connect(owner).addNamedDistribution(name, nonExistentId, initializer)
      ).to.be.revertedWithCustomError(distributor, "DistributionNotFound");
    });
  });

  describe("when distribution is added", function () {
    beforeEach(async function () {
      await distributor
        .connect(owner)
        ["addDistribution(bytes32,address)"](cloneDistributionId, ethers.constants.AddressZero);
    });

    it("Is possible to instantiate a contract", async function () {
      expect(
        await distributor.connect(owner).instantiate(distributorsId, ethers.constants.AddressZero)
      ).to.emit(distributor, "Instantiated");
    });

    it("Is possible to remove a distribution", async function () {
      expect(await distributor.connect(owner).removeDistribution(distributorsId)).to.emit(
        distributor,
        "DistributionRemoved"
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
        await distributor.connect(owner).removeDistribution(distributorsId);
      });
      it("Instance is invalid upon check", async () => {
        await expect(
          distributor.connect(owner).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
        ).to.be.revertedWithCustomError(distributor, "InvalidInstance");
      });
    });
  });
});
