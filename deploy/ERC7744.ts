import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  //   generated with cast create2 --starts-with c0de1d
  const bigIntValue = BigInt(
    "78378381581284404895893517889493377250775871826728312469548102844709657272918"
  );
  // Convert to a hexadecimal string
  const salt = "0x" + bigIntValue.toString(16);
  // const salt = "0x3f137ce155bc03d2f15fcd92ce561321f5b240867a6413fb82f386119638fa95";

  console.log("salt", salt);
  const result = await deploy("ERC7744", {
    deterministicDeployment: salt,
    from: deployer,
    skipIfAlreadyDeployed: true
  });

  console.log("ERC7744 deployed at", result.address);
  if (result.bytecode) {
    const codeHash = ethers.utils.keccak256(result.bytecode);
    console.log(`CodeHash: ${codeHash}`);
  }
};

export default func;
func.tags = ["ERC7744"];
