import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  //   generated with cast create2 --starts-with c0de1d
  //   const bigIntValue = BigInt(
  //     "50974397650477774973013714513428960054656154370774770732424793889552745009750"
  //   );
  //   // Convert to a hexadecimal string
  //   const salt = "0x" + bigIntValue.toString(16);
  const salt = "0x70b27c94ed692bfb60748cee464ef910d4bf768ac1f3a63eeb4c05258f629256";

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
