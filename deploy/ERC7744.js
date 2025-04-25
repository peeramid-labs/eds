import { ethers } from "ethers";

const func = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  // generated with cast create2 --starts-with c0de1d
  const salt = "0x9425035d50edcd7504fe5eeb5df841cc74fe6cccd82dca6ee75bcdf774bd88d9";

  const result = await deploy("ERC7744", {
    deterministicDeployment: salt,
    from: deployer,
    skipIfAlreadyDeployed: true
  });

  hre.network.name !== "hardhat" && console.log("ERC7744 deployed at", result.address);
  if (result.bytecode) {
    const codeHash = ethers.utils.keccak256(result.bytecode);
    hre.network.name !== "hardhat" && console.log(`CodeHash: ${codeHash}`);
  }
};

export default func;
func.tags = ["ERC7744"];
