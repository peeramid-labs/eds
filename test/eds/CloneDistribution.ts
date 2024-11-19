import { ethers } from "hardhat";
import { expect } from "chai";

describe("CloneDistribution", function () {
  let cloneDistribution: any;

  beforeEach(async function () {
    const CloneDistribution = await ethers.getContractFactory("MockCloneDistribution");
    cloneDistribution = await CloneDistribution.deploy();
    await cloneDistribution.deployed();
  });

  it("should emit Distributed event", async function () {
    expect(await cloneDistribution.instantiate("0x")).to.emit(cloneDistribution, "Distributed");
  });

  it("Should read metadata", async function () {
    const metadata = await cloneDistribution.contractURI();
    expect(metadata).to.equal("MockCloneDistribution");
  });

  it("returns contract name and version", async function () {
    const { name, version } = await cloneDistribution.get();
    expect(ethers.utils.parseBytes32String(name)).to.be.equal("MockCloneDistribution");
    expect(version).to.be.equal(1);
  });
});
