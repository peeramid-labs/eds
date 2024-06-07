/* global  ethers */

import { deployments, ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import { expect } from "chai";
import { MockERC20 } from "../types";

const setupTest = deployments.createFixture(
  async ({ deployments, getNamedAccounts, ethers: _eth }, options) => {
    const { deployer, owner } = await getNamedAccounts();
    await deployments.fixture(["mockERC20_token"]);
    console.warn(deployer, owner);
    const c = await deployments.get("MockERC20");
    return {
      owner,
      deployer,
      mock: (await ethers.getContractAt(c.abi, c.address)) as MockERC20,
    };
  },
);

describe("TestOwnership", async function () {
  let env: { owner: string; deployer: string; mock: MockERC20 };
  beforeEach(async function () {
    console.log("before");
    env = await setupTest();
  });
  it("returns owner", async () => {
    expect(await env.mock.owner()).to.be.equal(env.owner);
  });
});
