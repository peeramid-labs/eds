import { ethers } from "hardhat";
import { expect } from "chai";
import {
  ERC7744,
  MockCloneDistribution,
  MockCloneDistribution__factory,
  MockInstaller,
  MockInstaller__factory,
  OwnableDistributor,
  OwnableDistributor__factory
} from "../../types";
import { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Installer", function () {
  let codeIndex: ERC7744;
  let distributor: OwnableDistributor;
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let target: SignerWithAddress;
  let cloneDistributionId: any;
  let distributorsId: any;
  let installer: MockInstaller;

  beforeEach(async function () {
    await deployments.fixture("ERC7744"); // This is the key addition
    const ERC7744 = await ethers.getContractFactory("ERC7744");
    [deployer, owner, target] = await ethers.getSigners();
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
    await codeIndex.register(cloneDistribution.address);
    distributor
      .connect(owner)
      ["addDistribution(bytes32,address)"](cloneDistributionId, ethers.constants.AddressZero);
    distributorsId = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "address"],
        [cloneDistributionId, ethers.constants.AddressZero]
      )
    );
    const Installer = (await ethers.getContractFactory("MockInstaller")) as MockInstaller__factory;
    installer = await Installer.deploy(target.address, owner.address);
  });

  it("Only owner can install distributors", async function () {
    expect(await installer.connect(owner).whitelistDistributor(distributor.address)).to.emit(
      installer,
      "DistributorAdded"
    );

    await expect(
      installer.connect(deployer).whitelistDistributor(distributor.address)
    ).to.be.revertedWithCustomError(installer, "OwnableUnauthorizedAccount");
  });

  it("Only owner can remove distributors", async function () {
    await installer.connect(owner).whitelistDistributor(distributor.address);

    expect(
      await installer.connect(owner).revokeWhitelistedDistributor(distributor.address)
    ).to.emit(installer, "DistributorRemoved");

    await expect(
      installer.connect(deployer).revokeWhitelistedDistributor(distributor.address)
    ).to.be.revertedWithCustomError(installer, "OwnableUnauthorizedAccount");
  });

  it("Anyone can instantiate from whitelisted distributors", async function () {
    await installer.connect(owner).whitelistDistributor(distributor.address);

    expect(
      await installer.connect(deployer).install(distributor.address, distributorsId, "0x")
    ).to.emit(installer, "Installed");
  });
  it("can List distributors", async function () {
    await installer.connect(owner).whitelistDistributor(distributor.address);
    expect(await installer.connect(owner).getWhitelistedDistributors()).to.be.deep.eq([
      distributor.address
    ]);
  });
  it("Can get instances by id", async function () {
    await installer.connect(owner).whitelistDistributor(distributor.address);
    await installer.connect(owner).install(distributor.address, distributorsId, "0x");
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

  it("Allows whitelisted distributor only valid instances to call target", async () => {
    await installer.connect(owner).whitelistDistributor(distributor.address);
    await installer.connect(owner).install(distributor.address, distributorsId, "0x");
    const instanceNum = await installer.connect(owner).getInstancesNum();
    let instanceAddress = (await installer.connect(target).getInstance(instanceNum))[0];
    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", deployer.address, "0", "0x")
    ).to.be.revertedWithCustomError(installer, "NotAnInstance");

    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
    ).to.be.not.revertedWithCustomError(installer, "NotAnInstance");

    await distributor.connect(owner).removeDistribution(distributorsId);
    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
    ).to.be.revertedWithCustomError(distributor, "InvalidInstance");
  });

  it("Allows valid distributions added by distributor and distribution id to call target", async () => {
    await installer.connect(owner).allowDistribution(distributor.address, distributorsId);
    await installer.connect(owner).install(distributor.address, distributorsId, "0x");
    const instanceNum = await installer.connect(owner).getInstancesNum();
    let instanceAddress = (await installer.connect(target).getInstance(instanceNum))[0];
    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", deployer.address, "0", "0x")
    ).to.be.revertedWithCustomError(installer, "NotAnInstance");

    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
    ).to.be.not.revertedWithCustomError(installer, "NotAnInstance");

    await distributor.connect(owner).removeDistribution(distributorsId);
    await expect(
      installer.connect(target).beforeCall("0x", "0x00000000", instanceAddress, "0", "0x")
    ).to.be.revertedWithCustomError(distributor, "InvalidInstance");
  });

  it("Reverts when valid distributions added by distributor and distribution id were removed", async () => {
    await installer.connect(owner).allowDistribution(distributor.address, distributorsId);
    await installer.connect(owner).install(distributor.address, distributorsId, "0x");
    const instanceNum = await installer.connect(owner).getInstancesNum();
    let instanceAddress = (await installer.connect(target).getInstance(instanceNum))[0];

    await installer.connect(owner).disallowDistribution(distributor.address, distributorsId);

    await expect(
      installer
        .connect(target)
        .beforeCall(
          ethers.utils.defaultAbiCoder.encode(["address"], [instanceAddress]),
          "0x00000000",
          instanceAddress,
          "0",
          "0x"
        )
    ).to.be.revertedWithCustomError(installer, "DistributionIsNotPermitted");
  });

  it("Does reverts on invalid target", async () => {
    await installer.connect(owner).whitelistDistributor(distributor.address);
    await installer.connect(owner).install(distributor.address, distributorsId, "0x");
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
