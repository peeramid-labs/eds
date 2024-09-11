import { ethers } from "hardhat";
import { expect } from "chai";
import {
  CodeIndex,
  Distributor,
  MockCloneDistribution,
  MockCloneDistribution__factory,
  MockInstaller,
  MockInstaller__factory,
  OwnableDistributor,
  OwnableDistributor__factory,
} from "../../types";
import { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Installer", function () {
  let codeIndex: CodeIndex;
  let distributor: OwnableDistributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let target: SignerWithAddress;
  let cloneDistributionId: any;
  let installer: MockInstaller;

  beforeEach(async function () {
    await deployments.fixture("code_index"); // This is the key addition
    const CodeIndex = await ethers.getContractFactory("CodeIndex");
    [deployer, owner, target] = await ethers.getSigners();
    const codeIndexDeployment = await deployments.get("CodeIndex");
    codeIndex = new ethers.Contract(codeIndexDeployment.address, CodeIndex.interface).connect(
      deployer
    ) as CodeIndex;

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
    await codeIndex.register(cloneDistribution.address);
    distributor
      .connect(owner)
      .addDistribution(cloneDistributionId, ethers.utils.formatBytes32String(""));
    const Installer = (await ethers.getContractFactory("MockInstaller")) as MockInstaller__factory;
    installer = await Installer.deploy(target.address, owner.address);
  });

  it("Only owner can install distributors", async function () {
    expect(await installer.connect(owner).addDistributor(distributor.address)).to.emit(
      installer,
      "DistributorAdded"
    );

    await expect(
      installer.connect(deployer).addDistributor(distributor.address)
    ).to.be.revertedWithCustomError(installer, "OwnableUnauthorizedAccount");
  });

  it("Only owner can remove distributors", async function () {
    await installer.connect(owner).addDistributor(distributor.address);

    expect(await installer.connect(owner).removeDistributor(distributor.address)).to.emit(
      installer,
      "DistributorRemoved"
    );

    await expect(
      installer.connect(deployer).removeDistributor(distributor.address)
    ).to.be.revertedWithCustomError(installer, "OwnableUnauthorizedAccount");
  });

  it("Anyone can instantiate from whitelisted distributors", async function () {
    await installer.connect(owner).addDistributor(distributor.address);

    expect(
      await installer.connect(deployer).install(distributor.address, cloneDistributionId, "0x")
    ).to.emit(installer, "Installed");
  });
  it("can List distributors", async function () {
    await installer.connect(owner).addDistributor(distributor.address);
    expect(await installer.connect(owner).getDistributors()).to.be.deep.eq([distributor.address]);
  });
  it("Can get instances by id", async function () {
    await installer.connect(owner).addDistributor(distributor.address);
    await installer.connect(owner).install(distributor.address, cloneDistributionId, "0x");
    const instanceNum = await installer.connect(owner).getInstancesNum();
    expect((await installer.connect(owner).getInstance(instanceNum)).length).to.be.eq(1);
    let instanceAddress = (await installer.connect(owner).getInstance(instanceNum))[0];
    const instance = (await ethers.getContractAt(
      "MockCloneDistribution",
      instanceAddress
    )) as MockCloneDistribution;
    const { src } = await instance.get();
    expect(src[0]).to.be.equal(instance.address);
  });

  it("Allows only valid instances to call target", async () => {
    await installer.connect(owner).addDistributor(distributor.address);
    await installer.connect(owner).install(distributor.address, cloneDistributionId, "0x");
    const instanceNum = await installer.connect(owner).getInstancesNum();
    let instanceAddress = (await installer.connect(target).getInstance(instanceNum))[0];
    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", deployer.address, "0", "0x")
    ).to.be.revertedWithCustomError(installer, "NotAnInstance");

    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
    ).to.be.not.revertedWithCustomError(installer, "NotAnInstance");

    await distributor.connect(owner).removeDistribution(cloneDistributionId);
    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
    ).to.be.revertedWithCustomError(distributor, "InvalidInstance");
  });
  it("Does reverts on invalid target", async () => {
    await installer.connect(owner).addDistributor(distributor.address);
    await installer.connect(owner).install(distributor.address, cloneDistributionId, "0x");
    const instanceNum = await installer.connect(owner).getInstancesNum();
    let instanceAddress = (await installer.connect(target).getInstance(instanceNum))[0];
    await expect(
      installer.connect(deployer).beforeCall("0x", "0x00000000", deployer.address, "0", "0x")
    ).to.be.revertedWithCustomError(installer, "InvalidTarget");

    await expect(
      installer.connect(deployer).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
    ).to.be.revertedWithCustomError(installer, "InvalidTarget");
  });
});
