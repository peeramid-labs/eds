import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  const bigIntValue = BigInt(
    "41141709390666784200050170042964565822604878497452311470603333265732153031889"
  );
  // Convert to a hexadecimal string
  const hexValue = "0x" + bigIntValue.toString(16);

  console.log("hexValue", hexValue);
  const result = await deploy("CodeIndex", {
    deterministicDeployment: hexValue,
    from: deployer,
    skipIfAlreadyDeployed: true,
  });

  console.log("CodeIndex deployed at", result.address);
  if (result.bytecode) {
    const codeHash = ethers.utils.keccak256(result.bytecode);
    console.log(`CodeHash: ${codeHash}`);
  }
};

export default func;
func.tags = ["code_index"];
