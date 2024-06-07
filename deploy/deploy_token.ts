import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  const result = await deploy("MockERC20", {
    from: deployer,
    args: ["TokenName", "TokenSymbol", owner],
    skipIfAlreadyDeployed: true,
  });
  console.log("deployed at", result.address);
};

export default func;
func.tags = ["mockERC20_token"];
