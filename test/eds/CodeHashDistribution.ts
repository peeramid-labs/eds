import { ethers } from "hardhat";
import { expect } from "chai";
import { CodeHashDistribution, CodeHashDistribution__factory, CodeIndex } from "../../types";
import { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import utils from "../utils";

describe("CloneHashDistribution", function () {
  let codeIndex: CodeIndex;
  let deployer: SignerWithAddress;

  beforeEach(async function () {
    await deployments.fixture("code_index"); // This is the key addition
    const CodeIndex = await ethers.getContractFactory("CodeIndex");
    deployer = (await ethers.getSigners())[0];
    const codeIndexDeployment = await deployments.get("CodeIndex");
    codeIndex = new ethers.Contract(codeIndexDeployment.address, CodeIndex.interface).connect(
      deployer
    ) as CodeIndex;
  });

  it("Can instantiate a contract", async function () {
    const TestFacet = await ethers.getContractFactory("TestFacet");
    const testFacet = await TestFacet.deploy();
    codeIndex.register(testFacet.address);
    const CodeHashDistribution = (await ethers.getContractFactory(
      "CodeHashDistribution"
    )) as CodeHashDistribution__factory;
    const code = await testFacet.provider.getCode(testFacet.address);
    const codeHash = ethers.utils.keccak256(code);
    const codeHashDistribution = (await CodeHashDistribution.deploy(
      codeHash,
      ethers.utils.formatBytes32String("DiamondProxy"),
      ethers.utils.formatBytes32String("testDistribution"),
      0
    )) as CodeHashDistribution;
    expect(await codeHashDistribution.instantiate("0x")).to.emit(codeHashDistribution, "Distributed");
  });
  it("Instantiated contract code hash matches", async function () {
    const TestFacet = await ethers.getContractFactory("TestFacet");
    const testFacet = await TestFacet.deploy();
    codeIndex.register(testFacet.address);
    const CodeHashDistribution = await ethers.getContractFactory("CodeHashDistribution");
    const code = await testFacet.provider.getCode(testFacet.address);
    const codeHash = ethers.utils.keccak256(code);
    const codeHashDistribution = (await CodeHashDistribution.deploy(
      codeHash,
      ethers.utils.formatBytes32String("DiamondProxy"),
      ethers.utils.formatBytes32String("testDistribution"),
      0
    )) as CodeHashDistribution;
    const receipt = await (await codeHashDistribution.instantiate("0x")).wait();

    // await codeIndex.register(instance.contractAddress)
    const superInterface = utils.getSuperInterface();
    const parsed = receipt.logs.map((log) => ({
      rawLog: log,
      ...superInterface.parseLog(log),
    }));
    const instance = parsed[0].args.instances[0];
    const code2 = await testFacet.provider.getCode(instance);
    expect(code2.slice(22, 62).toLowerCase()).to.be.equal(testFacet.address.slice(2).toLowerCase());
  });
  it("returns contract name and version", async function () {
    const TestFacet = await ethers.getContractFactory("TestFacet");
    const testFacet = await TestFacet.deploy();
    codeIndex.register(testFacet.address);
    const CodeHashDistribution = (await ethers.getContractFactory(
      "CodeHashDistribution"
    )) as CodeHashDistribution__factory;
    const code = await testFacet.provider.getCode(testFacet.address);
    const codeHash = ethers.utils.keccak256(code);
    const codeHashDistribution = (await CodeHashDistribution.deploy(
      codeHash,
      ethers.utils.formatBytes32String("DiamondProxy"),
      ethers.utils.formatBytes32String("testDistribution"),
      0
    )) as CodeHashDistribution;

    const { src, name, version } = await codeHashDistribution.get();
    expect(ethers.utils.parseBytes32String(name)).to.be.equal("testDistribution");
    expect(version).to.be.equal(0);
  });
});
