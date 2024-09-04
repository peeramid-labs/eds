import { ethers } from "hardhat";
import { Signer } from "ethers";
import { expect } from "chai";
import {
  CodeHashDistribution,
  CodeHashDistribution__factory,
  CodeIndex,
  Distributor,
  Distributor__factory,
  MockCloneDistribution__factory,
  OwnableDistributor__factory,
  TestFacet,
  TestFacet__factory,
} from "../../types";
import hre, { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("Distributor", function () {
  let codeIndex: CodeIndex;
  let distributor: Distributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let cloneDistributionId: any;

  beforeEach(async function () {
    await deployments.fixture("code_index"); // This is the key addition
    const CodeIndex = await ethers.getContractFactory("CodeIndex");
    [deployer, owner] = await ethers.getSigners();
    const codeIndexDeployment = await deployments.get("CodeIndex");
    codeIndex = new ethers.Contract(
      codeIndexDeployment.address,
      CodeIndex.interface
    ).connect(deployer) as CodeIndex;

    const Distributor = (await ethers.getContractFactory(
      "OwnableDistributor"
    )) as OwnableDistributor__factory;
    distributor = await Distributor.deploy(owner.address);

    const CloneDistribution = (await ethers.getContractFactory(
      "MockCloneDistribution"
    )) as MockCloneDistribution__factory;
    const cloneDistribution = await CloneDistribution.deploy();
    await cloneDistribution.deployed();
    const code = await cloneDistribution.provider.getCode(
      cloneDistribution.address
    );
    cloneDistributionId = ethers.utils.keccak256(code);
    await codeIndex.register(cloneDistribution.address);
  });

  it("Only Owner can add distribution instantiate a contract", async function () {
    expect(
      await distributor
        .connect(owner)
        .addDistribution(
          cloneDistributionId,
          ethers.utils.formatBytes32String("")
        )
    ).to.emit(distributor, "DistributionAdded");
    await expect(
      distributor
        .connect(deployer)
        .addDistribution(
          cloneDistributionId,
          ethers.utils.formatBytes32String("")
        )
    ).to.be.revertedWithCustomError(distributor, "OwnableUnauthorizedAccount");
  });

  it("Does not allow instantiate a contract that was not added", async function () {
    const TestFacetDistribution = (await ethers.getContractFactory(
      "TestFacet"
    )) as TestFacet__factory;
    const testFacetDistribution = await TestFacetDistribution.deploy();
    await testFacetDistribution.deployed();
    const code = await testFacetDistribution.provider.getCode(
      testFacetDistribution.address
    );
    const cloneDistributionId = ethers.utils.keccak256(code);
    await codeIndex.register(testFacetDistribution.address);
    await expect(
      distributor
        .connect(owner)
        .instantiate(cloneDistributionId, ethers.utils.formatBytes32String(""))
    ).to.be.revertedWithCustomError(distributor, "DistributionNotFound");
  });

  describe("when distribution is added", function () {
    beforeEach(async function () {
      await distributor
        .connect(owner)
        .addDistribution(
          cloneDistributionId,
          ethers.utils.formatBytes32String("")
        );
    });

    it("Is possible to instantiate a contract", async function () {
      expect(
        await distributor
          .connect(owner)
          .instantiate(
            cloneDistributionId,
            ethers.utils.formatBytes32String("")
          )
      ).to.emit(distributor, "Instantiated");
    });

    it("Is possible to remove a distribution", async function () {
      expect(
        await distributor.connect(owner).removeDistribution(cloneDistributionId)
      ).to.emit(distributor, "DistributionRemoved");
    });

    describe("When distribution is instantiated and then removed", () => {
      let instanceAddress: string;
      beforeEach(async () => {
        let receipt = await (
          await distributor
            .connect(owner)
            .instantiate(
              cloneDistributionId,
              ethers.utils.formatBytes32String("")
            )
        ).wait();
        let parsed = utils.getSuperInterface().parseLog(receipt.logs[0]);
        instanceAddress = parsed.args.instances[0];
        console.log(instanceAddress);
        await distributor
          .connect(owner)
          .removeDistribution(cloneDistributionId);
      });
      it("Instance is invalid upon check", async () => {
        await expect(
          distributor
            .connect(owner)
            .beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
        ).to.be.revertedWithCustomError(distributor, "InvalidInstance");
      });
    });
  });
});
