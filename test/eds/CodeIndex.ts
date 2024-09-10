import { ethers } from "hardhat";
import { expect } from "chai";
import { CodeIndex, TestFacet } from "../../types";
import hre, { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
describe("CloneDistribution", function () {
  let codeIndex: CodeIndex;
  let testContract: TestFacet;
  let deployer: SignerWithAddress;

  beforeEach(async function () {
    await deployments.fixture("code_index"); // This is the key addition
    const CodeIndex = await ethers.getContractFactory("CodeIndex");

    const initCodeHash = ethers.utils.keccak256(CodeIndex.bytecode);
    console.log(`Init Code Hash: ${initCodeHash}`);
    deployer = (await ethers.getSigners())[0];
    // Convert to a BigInt since the value is too large for standard Number types
    const bigIntValue = BigInt(
      "42759584821269276073726276772598488633863215600876260121819881722816808625192"
    );
    // Convert to a hexadecimal string
    const hexValue = "0x" + bigIntValue.toString(16);
    const result = await hre.deployments.deploy("CodeIndex", {
      deterministicDeployment: hexValue,
      from: deployer.address,
      skipIfAlreadyDeployed: true,
    });
    codeIndex = new ethers.Contract(
      result.address,
      CodeIndex.interface
    ).connect(deployer) as CodeIndex;
    console.log("CodeIndex deployed at", result.address);
    const TestContract = await ethers.getContractFactory("TestFacet");
    testContract = (await TestContract.deploy()) as TestFacet;
  });

  it("should emit Distributed event", async function () {
    // const code = await testContract.provider.getCode(testContract.address);
    expect(await codeIndex.register(testContract.address)).to.emit(
      codeIndex,
      "Indexed"
    );
  });

  it("should return address for registered code hash", async function () {
    await codeIndex.register(testContract.address);
    const code = await testContract.provider.getCode(testContract.address);
    const codeHash = ethers.utils.keccak256(code);
    expect(await codeIndex.get(codeHash)).to.equal(testContract.address);
  });

  it("Should revert on registering same code hash", async function () {
    await codeIndex.register(testContract.address);
    await expect(
      codeIndex.register(testContract.address)
    ).to.be.revertedWithCustomError(codeIndex, "alreadyExists");
  });
});
