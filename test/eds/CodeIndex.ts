import { ethers } from "hardhat";
import { expect } from "chai";
import { ERC7744, TestFacet } from "../../types";
import hre, { deployments } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
describe("Code Index", function () {
  let codeIndex: ERC7744;
  let testContract: TestFacet;
  let deployer: SignerWithAddress;

  beforeEach(async function () {
    await deployments.fixture("ERC7744"); // This is the key addition
    const ERC7744 = await ethers.getContractFactory("ERC7744");
    const codeIndexDeployment = await deployments.get("ERC7744");
    const { deployer: _deployer } = await hre.getNamedAccounts();
    deployer = await ethers.getSigner(_deployer);
    codeIndex = new ethers.Contract(codeIndexDeployment.address, ERC7744.interface).connect(
      deployer
    ) as ERC7744;

    const TestContract = await ethers.getContractFactory("TestFacet");
    testContract = (await TestContract.deploy()) as TestFacet;
  });

  it("should emit Indexed event", async function () {
    // const code = await testContract.provider.getCode(testContract.address);
    expect(await codeIndex.register(testContract.address)).to.emit(codeIndex, "Indexed");
  });

  it("should return address for registered code hash", async function () {
    await codeIndex.register(testContract.address);
    const code = await testContract.provider.getCode(testContract.address);
    const codeHash = ethers.utils.keccak256(code);
    expect(await codeIndex.get(codeHash)).to.equal(testContract.address);
  });

  it("Should revert on registering same code hash", async function () {
    await codeIndex.register(testContract.address);
    await expect(codeIndex.register(testContract.address)).to.be.revertedWithCustomError(
      codeIndex,
      "alreadyExists"
    );
  });
});
