import { subtask, task } from "hardhat/config";
import { TASK_COMPILE_SOLIDITY_EMIT_ARTIFACTS } from "hardhat/builtin-tasks/task-names";
import path, { join } from "path";
import { writeFile, mkdir } from "fs/promises";
import { inspect } from "util";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "hardhat-deploy";
import "solidity-docgen";
import "solidity-coverage";
import "hardhat-tracer";
import { ethers } from "ethers";
import { FormatTypes, JsonFragment } from "@ethersproject/abi";
import fs from "fs";
// import "@nomicfoundation/hardhat-verify";

type ContractMap = Record<string, { abi: object }>;

subtask(TASK_COMPILE_SOLIDITY_EMIT_ARTIFACTS).setAction(async (args, env, next) => {
  const output = await next();
  const promises = Object.entries(args.output.contracts).map(async ([sourceName, contract]) => {
    // Extract the contract name from the full path
    const contractName = sourceName.split("/").pop()?.replace(".sol", "") || "";
    const dirPath = join("./abi", sourceName);
    await mkdir(dirPath, { recursive: true });
    const file = join(dirPath, `${contractName}.ts`);
    const { abi } = Object.values(contract as ContractMap)[0];
    if (JSON.stringify(abi).length > 2) {
      const data = `export const abi = ${inspect(abi, false, null)} as const; export default abi;`;
      await writeFile(file, data);
    }
  });
  await Promise.all(promises);
  return output;
});

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const getSuperInterface = (outputPath?: string) => {
  let mergedArray: JsonFragment[] = [];
  function readDirectory(directory: string) {
    const files = fs.readdirSync(directory);

    files.forEach((file) => {
      const fullPath = path.join(directory, file);
      if (fs.statSync(fullPath).isDirectory()) {
        readDirectory(fullPath); // Recurse into subdirectories
      } else if (path.extname(file) === ".json") {
        const fileContents = require("./" + fullPath); // Load the JSON file
        if (Array.isArray(fileContents)) {
          mergedArray = mergedArray.concat(fileContents); // Merge the array from the JSON file
        }
      }
    });
  }
  const originalConsoleLog = console.log;
  readDirectory("./abi");
  console.log = () => {}; // avoid noisy output
  const result = new ethers.utils.Interface(mergedArray);
  if (outputPath) {
    fs.writeFileSync(outputPath, JSON.stringify(result.format(FormatTypes.full), null, 2));
  }
  console.log = originalConsoleLog;
  return result;
};

task("getSuperInterface", "Prints the super interface of a contract")
  .setAction(async (taskArgs: { outputPath: string }, hre) => {
    const originalConsoleLog = console.log;
    console.log = () => {};
    const su = getSuperInterface(taskArgs.outputPath + "/super-interface.json");
    let return_value: Record<string, string> = {};
    Object.values(su.functions).forEach((x) => {
      return_value[su.getSighash(x.format())] = x.format(FormatTypes.full);
    });
    Object.values(su.events).forEach((x) => {
      return_value[su.getEventTopic(x)] = x.format(FormatTypes.full);
    });
    Object.values(su.errors).forEach((x) => {
      return_value[su.getSighash(x)] = x.format(FormatTypes.full);
    });
    fs.writeFileSync(
      taskArgs.outputPath + "/signatures.json",
      JSON.stringify(return_value, null, 2)
    );
    console.log = originalConsoleLog;
  })
  .addParam("outputPath", "The path to the abi file");

export default {
  docgen: {
    outputDir: "./docs/contracts",
    pages: "files",
    templates: "docs/templates",
    sourcesDir: "./src",
    pageExtension: ".md",
    exclude: ["mocks", "initializers", "vendor", "modifiers", "fixtures"]
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 21,
    token: "MATIC",
    gasPriceApi: "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
    enabled: false,
    coinmarketcap: process.env.COINMARKETCAP_KEY
  },
  namedAccounts: {
    deployer: {
      hardhat: "0xF52E5dF676f51E410c456CC34360cA6F27959420",
      arbitrum: "0x5F997aAb4F6757FAa48e008faa599841947959F1",
      anvil: "0x6Cf8d74C7875de8C2FfB09228F4bf2A21b25e583",
      default: "0xF52E5dF676f51E410c456CC34360cA6F27959420" //TODO this must be set for networks
    },
    owner: {
      default: "0x520E00225C4a43B6c55474Db44a4a44199b4c3eE",
      anvil: "0x507c2d32185667156de5B4C440FEEf3800078bDb"
    }
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: {
        mnemonic: "casual vacant letter raw trend tool vacant opera buzz jaguar bridge myself"
      } // ONLY LOCAL
    },
    arbitrum: {
      url: process.env.RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY]
    },
    mumbai: {
      url: "https://matic-mumbai.chainstacklabs.com",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY]
    },
    matic: {
      url: process.env.RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY]
    },
    ganache: {
      url: process.env.GANACHE_RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY]
    },
    goerli: {
      url: process.env.RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY && [process.env.PRIVATE_KEY]
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: {
        mnemonic: "casual vacant letter raw trend tool vacant opera buzz jaguar bridge myself"
      } // ONLY LOCAL
    },
    anvil: {
      url: process.env.ANVIL_RPC_URL ?? "",
      accounts: {
        mnemonic: process.env.ANVIL_MNEMONIC ?? "x"
      }
    }
  },
  paths: {
    sources: "./src"
  },
  solidity: {
    compilers: [
      {
        version: "0.8.28",
        settings: {
          evmVersion: "cancun",
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 2000
          },
          metadata: {
            bytecodeHash: "none"
          }
        }
      }
    ]
    // overrides: {
    //   "src/erc7744/ERC7744.sol": {
    //     version: "0.8.28",
    //     settings: {
    //       evmVersion: "cancun",
    //       viaIR: true,
    //       optimizer: {
    //         enabled: true,
    //         runs: 2000
    //       },
    //       metadata: {
    //         bytecodeHash: "none"
    //       }
    //     }
    //   }
    // }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
    alwaysGenerateOverloads: true // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
    // externalArtifacts: ["externalArtifacts/*.json"], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
  },
  abiExporter: {
    path: "./abi",
    runOnCompile: true,
    clear: true,
    format: "json",
    // flat: true,
    // only: [":ERC20$"],
    spacing: 2,
    pretty: false
  }
};
